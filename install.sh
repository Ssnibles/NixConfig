#!/usr/bin/env bash
# =============================================================================
# NixOS Bootstrap Installer
# =============================================================================
set -euo pipefail

# Ensure running as root early before prompting or creating files
[[ $EUID -ne 0 ]] && { echo -e "\033[0;31m  ERROR: Run as root: sudo bash install.sh\033[0m" >&2; exit 1; }

REPO_URL="https://github.com/Ssnibles/NixConfig.git"
SSH_REPO_URL="git@github.com:Ssnibles/NixConfig.git"
CONFIG_BRANCH="main"
MOUNT="/mnt"
DEFAULT_USERNAME="josh"

# Enable nix command and flakes for the installer session (needed on minimal ISOs
# where these experimental features are not configured by default).
export NIX_CONFIG="extra-experimental-features = nix-command flakes"

# ── Colours & logging ─────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

info()    { echo -e "${BLUE}  ->${NC} $*"; }
success() { echo -e "${GREEN}  OK${NC} $*"; }
warn()    { echo -e "${YELLOW}  !${NC} $*"; }
die()     { echo -e "${RED}  ERROR:${NC} $*" >&2; exit 1; }

STEP=0; TOTAL_STEPS=8
step() { STEP=$((STEP + 1)); echo -e "\n${BOLD}---  [ $STEP / $TOTAL_STEPS ]  $*  ---${NC}"; }

# ── Helpers ───────────────────────────────────────────────────────────────

# Run git, falling back to `nix run` if the binary is missing (common on the
# NixOS minimal ISO).
run_git() {
  if command -v git >/dev/null 2>&1; then git "$@"; else nix run nixpkgs#git -- "$@"; fi
}

require_cmd() { command -v "$1" >/dev/null 2>&1 || die "Required command '$1' not found."; }

# Read from /dev/tty (if available) so piped invocations (curl | bash) can still prompt.
ask() {
  local var="$1" prompt="$2" default="${3:-}" input
  if [[ -c /dev/tty ]]; then
    if [[ -n "$default" ]]; then
      read -rp "$prompt [$default]: " input < /dev/tty
      printf -v "$var" '%s' "${input:-$default}"
    else
      read -rp "$prompt: " input < /dev/tty
      printf -v "$var" '%s' "$input"
    fi
  else
    if [[ -n "$default" ]]; then
      read -rp "$prompt [$default]: " input
      printf -v "$var" '%s' "${input:-$default}"
    else
      read -rp "$prompt: " input
      printf -v "$var" '%s' "$input"
    fi
  fi
}

# Wait for the kernel to recognise partition table changes.
settle_disk() {
  blockdev --rereadpt "$1" 2>/dev/null || true
  partprobe "$1" 2>/dev/null || true
  udevadm settle --timeout=10 2>/dev/null || sleep 1
}

# Set up ~/.ssh/authorized_keys from a local file or a GitHub username.
install_ssh_keys() {
  local source="$1" method="$2"   # method: "file" | "github"
  local ssh_dir="$MOUNT/home/$USERNAME/.ssh"
  mkdir -p "$ssh_dir"
  if [[ "$method" == "file" ]]; then
    cp "$source" "$ssh_dir/authorized_keys"
    success "Copied SSH key from $source"
  elif curl -fsSL "https://github.com/${source}.keys" -o "$ssh_dir/authorized_keys" && [[ -s "$ssh_dir/authorized_keys" ]]; then
    success "SSH keys imported from github.com/${source}"
  else
    warn "Could not fetch keys from github.com/${source} (or user has no SSH keys) -- skipping."
    rm -f "$ssh_dir/authorized_keys"
    return
  fi
  chmod 700 "$ssh_dir"; chmod 600 "$ssh_dir/authorized_keys"
  nixos-enter --root "$MOUNT" -- chown -R "$USERNAME:users" "/home/$USERNAME/.ssh"
}

# ── Argument parsing ──────────────────────────────────────────────────────
DISK=""
DRY_RUN=false
HOST=""
USERNAME="$DEFAULT_USERNAME"
HOSTNAME=""
NO_REBOOT=false
SKIP_FORMAT=false
UPDATE=false
OVERWRITE=false
AUTO_CONFIRM=false
SSH_KEY_GITHUB=""
COPY_SSH_KEY=""
LOG_FILE="/tmp/nixos-install.log"
PROMPT_USER=true
PROMPT_HOSTNAME=true

while [[ $# -gt 0 ]]; do
  case $1 in
    --host)                HOST="$2";                              shift 2 ;;
    --disk)                DISK="$2";                              shift 2 ;;
    --user)                USERNAME="$2"; PROMPT_USER=false;       shift 2 ;;
    --hostname)            HOSTNAME="$2"; PROMPT_HOSTNAME=false;   shift 2 ;;
    --no-reboot)           NO_REBOOT=true;                         shift   ;;
    --skip-format)         SKIP_FORMAT=true;                       shift   ;;
    --update)              UPDATE=true;                            shift   ;;
    --overwrite)           OVERWRITE=true;                         shift   ;;
    -y|--yes)              AUTO_CONFIRM=true;                      shift   ;;
    --ssh-key-from-github) SSH_KEY_GITHUB="$2";                    shift 2 ;;
    --copy-ssh-key)        COPY_SSH_KEY="$2";                      shift 2 ;;
    --log)                 LOG_FILE="$2";                          shift 2 ;;
    --dry-run)             DRY_RUN=true;                           shift   ;;
    -h|--help)
      cat <<EOF
Usage: sudo bash install.sh [options]

  Without flags the installer is interactive and reads from /dev/tty.
  With flags it runs automatically. This means the script can be piped from
  curl and still prompt for missing values.

Options:
  --host <desktop|laptop>      Host configuration to install (prompt if omitted)
  --disk /dev/sdX              Target disk (will be wiped unless --skip-format; prompt if omitted)
  --user <username>            Username to create (default: $DEFAULT_USERNAME)
  --hostname <hostname>        Hostname (default: the host name)
  --no-reboot                  Don't reboot after installation
  --skip-format                Skip disk wipe/format; use existing partitions
  --update                     Run nix flake update after cloning
  --overwrite                  Remove an existing ~/NixConfig directory without prompting
  -y, --yes                    Skip disk wipe confirmation prompt
  --ssh-key-from-github <user> Import SSH keys from GitHub
  --copy-ssh-key <path>        Copy local authorized_keys file to new install
  --log <file>                 Log file path (default: $LOG_FILE)
  --dry-run                    Preview what would be done; no disk changes

Examples:
  sudo bash install.sh
  curl -fsSL https://raw.githubusercontent.com/Ssnibles/NixConfig/HEAD/install.sh | sudo bash -s -- --host desktop --disk /dev/nvme0n1
  curl -fsSL https://raw.githubusercontent.com/Ssnibles/NixConfig/HEAD/install.sh | sudo bash -s -- --host laptop --disk /dev/sda --user alice --hostname t480
  curl -fsSL https://raw.githubusercontent.com/Ssnibles/NixConfig/HEAD/install.sh | sudo bash -s -- --host desktop --skip-format --no-reboot
EOF
      exit 0 ;;
    *) warn "Unknown argument: $1"; shift ;;
  esac
done

# ── Interactive prompts for missing values ────────────────────────────────
if [[ -z "$HOST" ]]; then
  echo "  Available host configurations:"
  echo "    desktop"
  echo "    laptop"
  ask HOST "  Select host (desktop/laptop)"
  echo
fi
case "$HOST" in
  desktop|laptop) ;;
  *) die "Unknown host '$HOST'. Available: desktop, laptop" ;;
esac

[[ "$PROMPT_USER" == true ]]     && ask USERNAME "  Enter username" "$USERNAME"
[[ -z "$HOSTNAME" ]]             && HOSTNAME="$HOST"
[[ "$PROMPT_HOSTNAME" == true ]] && ask HOSTNAME "  Enter hostname" "$HOSTNAME"

# ── Logging ───────────────────────────────────────────────────────────────
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
touch "$LOG_FILE" || die "Could not create log file: $LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

# ── Cleanup trap ──────────────────────────────────────────────────────────
cleanup() {
  local code=$?
  if [[ $code -ne 0 && "$DRY_RUN" == false ]]; then
    warn "Install failed (exit $code) -- cleaning up mounts..."
    umount -R "$MOUNT" 2>/dev/null || true
    swapoff -a 2>/dev/null || true
    echo -e "${RED}  Aborted. Disk unmounted.${NC}"
  fi
}
trap cleanup EXIT

# ── Preflight ─────────────────────────────────────────────────────────────
echo -e "\n${BOLD}---  NixOS Bootstrap Installer - $HOST  ---${NC}"
[[ -d /nix/store ]] || die "This doesn't look like a NixOS live environment."
[[ "$DRY_RUN" == true ]] && warn "DRY-RUN -- no disk changes will be made."

require_cmd nix
require_cmd nixos-generate-config
if [[ "$SKIP_FORMAT" == false && "$DRY_RUN" == false ]]; then
  for cmd in sgdisk wipefs mkfs.fat mkfs.ext4 partprobe; do require_cmd "$cmd"; done
fi

info "Username: $USERNAME"
info "Hostname: $HOSTNAME"
info "Log file: $LOG_FILE"

# ==========================================================================
# 1 · NETWORK
# ==========================================================================
step "Network"
ping -c1 -W3 1.1.1.1 &>/dev/null || {
  warn "No internet connection. Connect first, then re-run."
  echo "  nmtui   -- text UI (easiest)"
  exit 1
}
success "Network OK"

# ==========================================================================
# 2 · DISK SELECTION
# ==========================================================================
step "Disk"

if [[ "$SKIP_FORMAT" == true ]]; then
  info "--skip-format set: existing partitions will be mounted by label."
  [[ -n "$DISK" ]] && { warn "Disk argument ignored in skip-format mode (labels are used)."; DISK=""; }
else
  if [[ -z "$DISK" ]]; then
    echo "  Available block devices:"
    lsblk -d -o NAME,SIZE,MODEL --noheadings | grep -v loop \
      | awk '{printf "    /dev/%-12s %6s  %s\n", $1, $2, $3}'
    echo
    ask DISK "  Enter disk (e.g., /dev/sda or /dev/nvme0n1)"
  fi
  [[ -b "$DISK" ]] || die "Disk '$DISK' not found."
  [[ "$(lsblk -dno TYPE "$DISK")" == "disk" ]] || \
    die "Target '$DISK' is not a whole disk (type: $(lsblk -dno TYPE "$DISK"))."

  # NVMe-style names (ending in a digit) need a 'p' separator before the
  # partition number; SATA-style names do not.
  [[ "$DISK" =~ [0-9]$ ]] && PART_PREFIX="p" || PART_PREFIX=""
  PART_EFI="${DISK}${PART_PREFIX}1"
  PART_ROOT="${DISK}${PART_PREFIX}2"

  warn "This will ERASE all data on ${DISK}!"
  echo "    $PART_EFI   -- 512 MiB EFI System Partition (FAT32)"
  echo "    $PART_ROOT  -- remainder, ext4 (root)"
  if [[ "$DRY_RUN" == false && "$AUTO_CONFIRM" == false ]]; then
    ask CONFIRM "  Type 'yes' to continue"
    [[ "$CONFIRM" == "yes" ]] || { info "Aborted."; exit 0; }
  fi
fi

# ==========================================================================
# 3 · PARTITIONING (UEFI + ext4)
# ==========================================================================
step "Partitioning"
if [[ "$SKIP_FORMAT" == true ]]; then
  info "Skipping partitioning (using existing labels)."
elif [[ "$DRY_RUN" == true ]]; then
  info "Dry-run: would wipe $DISK and create:"
  echo "    $PART_EFI   -- 512 MiB EFI System Partition (FAT32)"
  echo "    $PART_ROOT  -- remainder, ext4 (root)"
else
  info "Stopping swap and unmounting active partitions on $DISK..."
  swapoff -a 2>/dev/null || true
  for part in $(lsblk -ln -o PATH "$DISK" | tail -n +2); do
    umount -f "$part" 2>/dev/null || true
  done
  umount -R "$MOUNT" 2>/dev/null || true

  info "Erasing existing layout..."
  sgdisk --zap-all "$DISK" || die "sgdisk --zap-all failed. Is the disk busy?"
  wipefs -a "$DISK" --force

  info "Creating GPT partitions..."
  sgdisk --new=1:0:+512M --typecode=1:ef00 --change-name=1:EFI "$DISK" \
    || die "Failed to create EFI partition."
  sgdisk --new=2:0:0 --typecode=2:8300 --change-name=2:nixos "$DISK" \
    || die "Failed to create Root partition."

  settle_disk "$DISK"
  sleep 2
  [[ -b "$PART_ROOT" ]] || die "Partition $PART_ROOT did not appear after partitioning."

  info "Cleaning residual signatures..."
  wipefs -a "$PART_EFI" --force >/dev/null 2>&1 || true
  wipefs -a "$PART_ROOT" --force >/dev/null 2>&1 || true

  info "Formatting partitions..."
  mkfs.fat -F 32 -n EFI    "$PART_EFI"
  mkfs.ext4 -F -L nixos    "$PART_ROOT"

  success "Disk partitioned and formatted successfully"
fi

# ==========================================================================
# 4 · MOUNT
# ==========================================================================
step "Mounting"
if [[ "$DRY_RUN" == false ]]; then
  umount -R "$MOUNT" 2>/dev/null || true
  # Only scrub the mountpoint when we formatted the disk; in --skip-format mode
  # the user expects existing data to be preserved.
  [[ "$SKIP_FORMAT" == false ]] && rm -rf "${MOUNT:?}"/* 2>/dev/null || true

  settle_disk "${DISK:-}"
  info "Mounting root partition (label: nixos)..."
  mount /dev/disk/by-label/nixos "$MOUNT"
  mkdir -p "$MOUNT/boot"
  info "Mounting EFI partition (label: EFI)..."
  mount /dev/disk/by-label/EFI "$MOUNT/boot"
  success "Mounted root and EFI"
fi

# ==========================================================================
# 5 · CLONE CONFIG
# ==========================================================================
step "Cloning NixOS config"
TARGET="$MOUNT/etc/nixos"
HOME_TARGET="$MOUNT/home/$USERNAME/NixConfig"
if [[ "$DRY_RUN" == false ]]; then
  mkdir -p "$MOUNT/home/$USERNAME"

  if [[ -e "$HOME_TARGET" || -L "$HOME_TARGET" ]]; then
    if [[ "$OVERWRITE" == true ]]; then
      info "--overwrite set: removing existing $HOME_TARGET..."
      rm -rf "$HOME_TARGET"
    else
      warn "Directory already exists: $HOME_TARGET"
      ask OVERWRITE_ANSWER "  Remove and re-clone" "N"
      [[ "$OVERWRITE_ANSWER" =~ ^[Yy]([Ee][Ss])?$ ]] \
        || die "Aborted: existing $HOME_TARGET kept."
      info "Removing existing $HOME_TARGET..."
      rm -rf "$HOME_TARGET"
    fi
  fi

  info "Cloning $REPO_URL (branch: $CONFIG_BRANCH) -> $HOME_TARGET"
  run_git clone -b "$CONFIG_BRANCH" "$REPO_URL" "$HOME_TARGET"

  info "Configuring Git remote 'origin' to SSH ($SSH_REPO_URL)..."
  run_git -C "$HOME_TARGET" remote set-url origin "$SSH_REPO_URL" || \
    warn "Could not set Git remote URL to SSH."

  # Symlink /etc/nixos -> /home/$USERNAME/NixConfig (relative, so it resolves
  # correctly both under /mnt during install and at / after reboot).
  info "Creating symlink /etc/nixos -> /home/$USERNAME/NixConfig"
  mkdir -p "$MOUNT/etc"
  if [[ -e "$TARGET" || -L "$TARGET" ]]; then
    warn "Backing up existing $TARGET..."
    mv "$TARGET" "$TARGET.bak.$(date +%s)"
  fi
  ln -sfn "../home/$USERNAME/NixConfig" "$TARGET"

  success "Config cloned and symlinked"
fi

# ==========================================================================
# 6 · GENERATE HARDWARE CONFIG & INSTALLER OVERRIDES
# ==========================================================================
step "Hardware config and installer options"
if [[ "$DRY_RUN" == true ]]; then
  info "Dry-run: would generate hardware config and installer options for host '$HOST'"
else
  HW_FILE="$TARGET/modules/hosts/$HOST/_hardware-generated.nix"
  INSTALLER_FILE="$TARGET/modules/hosts/$HOST/_installer-options.nix"
  mkdir -p "$(dirname "$HW_FILE")"

  info "Generating hardware config for host '$HOST'..."
  nixos-generate-config --root /mnt --show-hardware-config > "$HW_FILE" \
    || die "nixos-generate-config failed."
  success "Wrote $HW_FILE"

  info "Writing installer options (username, hostname)..."
  cat > "$INSTALLER_FILE" <<EOF
{ lib, ... }:
{
  username = lib.mkForce "$USERNAME";
  networking.hostName = lib.mkForce "$HOSTNAME";
}
EOF
  success "Wrote $INSTALLER_FILE"

  # Nix flakes only include files tracked by git. Stage the generated files so
  # the flake actually sees them during installation.
  info "Staging generated files for flake evaluation..."
  run_git -C "$HOME_TARGET" add "modules/hosts/$HOST/_hardware-generated.nix" || \
    warn "Could not stage hardware config; the flake may not see it."
  run_git -C "$HOME_TARGET" add -f "modules/hosts/$HOST/_installer-options.nix" || \
    warn "Could not stage installer options; the flake may not see them."
fi

# ==========================================================================
# 7 · FLAKE VALIDATION & INSTALL
# ==========================================================================
step "Installing NixOS"
if [[ "$DRY_RUN" == true ]]; then
  info "Dry-run: would validate flake and run nixos-install --flake ${TARGET}#${HOST}"
else
  info "Validating flake..."
  nix flake metadata "$TARGET" || die "Flake validation failed."
  success "Flake OK"

  if [[ "$UPDATE" == true ]]; then
    info "Updating flake inputs..."
    nix flake update "$TARGET" || die "nix flake update failed."
  fi

  info "Running nixos-install (this will take a while)..."
  nixos-install --flake "${TARGET}#${HOST}" --no-root-passwd
  success "NixOS installed"
fi

# ==========================================================================
# 8 · POST-INSTALL
# ==========================================================================
step "Post-install setup"
if [[ "$DRY_RUN" == false ]]; then
  echo
  info "Set a password for root:"
  until nixos-enter --root "$MOUNT" -- passwd root; do warn "Try again."; done
  success "Root password set"

  echo
  info "Set a password for ${USERNAME}:"
  until nixos-enter --root "$MOUNT" -- passwd "$USERNAME"; do warn "Try again."; done
  success "Password set for ${USERNAME}"

  info "Fixing ownership of /home/${USERNAME}..."
  nixos-enter --root "$MOUNT" -- chown -R "$USERNAME:users" "/home/$USERNAME" || \
    warn "Could not fix ownership. After reboot run: sudo chown -R $USERNAME:users /home/$USERNAME"

  # SSH keys -- local file takes precedence over GitHub import.
  if [[ -n "$COPY_SSH_KEY" ]]; then
    if [[ -f "$COPY_SSH_KEY" ]]; then
      install_ssh_keys "$COPY_SSH_KEY" "file"
    else
      warn "SSH key file not found: $COPY_SSH_KEY -- skipping."
    fi
  else
    GH_USER="$SSH_KEY_GITHUB"
    [[ -z "$GH_USER" ]] && ask GH_USER "  Import SSH keys from GitHub? Enter username (or Enter to skip)"
    [[ -n "$GH_USER" ]] && install_ssh_keys "$GH_USER" "github"
  fi

  info "Copying install log to target..."
  mkdir -p "$MOUNT/var/log"
  cp "$LOG_FILE" "$MOUNT/var/log/nixos-install.log" 2>/dev/null || \
    warn "Could not copy install log to /var/log"
fi

# ==========================================================================
# DONE
# ==========================================================================
echo -e "\n${BOLD}---  Summary  ---${NC}"
echo -e "  ${GREEN}${BOLD}Installation complete!${NC}"
if [[ "$DRY_RUN" == false && -n "$DISK" ]]; then
  lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT "$DISK" 2>/dev/null | sed 's/^/    /' || true
fi
echo
info "Username:    $USERNAME"
info "Hostname:    $HOSTNAME"
info "Log file:    $LOG_FILE"
[[ "$DRY_RUN" == false ]] && info "Target log:  /var/log/nixos-install.log"
echo
echo -e "  ${BOLD}After reboot:${NC}"
echo -e "  ${DIM}1. Log in as ${USERNAME}${NC}"
echo -e "  ${DIM}2. Config is at ~/NixConfig (and /etc/nixos)${NC}"
echo -e "  ${DIM}3. Rebuild:  sudo nixos-rebuild switch --flake ~/NixConfig#${HOST}${NC}"
echo
[[ "$DRY_RUN" == true ]] && { warn "Dry-run complete -- nothing was changed."; exit 0; }

if [[ "$NO_REBOOT" == true ]]; then
  info "--no-reboot set; not rebooting."
  info "You can inspect the mounted system at $MOUNT"
  exit 0
fi

echo -e "${GREEN}${BOLD}  Rebooting in 5 seconds...${NC}  (Ctrl-C to cancel)"
sleep 5
reboot
