#!/usr/bin/env bash
# =============================================================================
# NixOS Bootstrap Installer
# =============================================================================
set -euo pipefail

REPO_URL="https://github.com/Ssnibles/NixConfig.git"
CONFIG_BRANCH="main"
MOUNT="/mnt"
DEFAULT_USERNAME="josh"

# Enable nix command and flakes for the installer session (needed on minimal ISOs
# where these experimental features are not configured by default).
export NIX_CONFIG="extra-experimental-features = nix-command flakes"

# ── Colours ───────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

info()    { echo -e "${BLUE}  ->${NC} $*"; }
success() { echo -e "${GREEN}  OK${NC} $*"; }
warn()    { echo -e "${YELLOW}  !${NC} $*"; }
die()     { echo -e "${RED}  ERROR:${NC} $*" >&2; exit 1; }
heading() { echo -e "\n${BOLD}---  $*  ---${NC}"; }

# Read interactive input from the controlling terminal so the script can be
# piped (e.g. curl ... | bash) and still prompt for missing values.
ask() {
  local var="$1"
  local prompt="$2"
  local default="${3:-}"
  local input
  if [[ -n "$default" ]]; then
    read -rp "$prompt [$default]: " input < /dev/tty
    printf -v "$var" '%s' "${input:-$default}"
  else
    read -rp "$prompt: " input < /dev/tty
    printf -v "$var" '%s' "$input"
  fi
}

# ── Argument parsing ──────────────────────────────────────────────────────
DISK=""
DRY_RUN=false
HOST=""
USERNAME="$DEFAULT_USERNAME"
USERNAME_SET=false
HOSTNAME=""
HOSTNAME_SET=false
NO_REBOOT=false
SKIP_FORMAT=false
UPDATE=false
OVERWRITE=false
SSH_KEY_GITHUB=""
COPY_SSH_KEY=""
LOG_FILE="/tmp/nixos-install.log"

while [[ $# -gt 0 ]]; do
  case $1 in
    --host)               HOST="$2";                shift 2 ;;
    --disk)               DISK="$2";                shift 2 ;;
    --user)               USERNAME="$2"; USERNAME_SET=true; shift 2 ;;
    --hostname)           HOSTNAME="$2"; HOSTNAME_SET=true; shift 2 ;;
    --no-reboot)          NO_REBOOT=true;           shift   ;;
    --skip-format)        SKIP_FORMAT=true;         shift   ;;
    --update)             UPDATE=true;              shift   ;;
    --overwrite)          OVERWRITE=true;           shift   ;;
    --ssh-key-from-github) SSH_KEY_GITHUB="$2";     shift 2 ;;
    --copy-ssh-key)       COPY_SSH_KEY="$2";        shift 2 ;;
    --log)                LOG_FILE="$2";            shift 2 ;;
    --dry-run)            DRY_RUN=true;             shift   ;;
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

if [[ -z "$HOSTNAME" ]]; then
  HOSTNAME="$HOST"
fi

if [[ "$USERNAME_SET" == false ]]; then
  ask input_username "  Enter username" "$DEFAULT_USERNAME"
  [[ -n "$input_username" ]] && USERNAME="$input_username"
  echo
fi

if [[ "$HOSTNAME_SET" == false ]]; then
  ask input_hostname "  Enter hostname" "$HOSTNAME"
  [[ -n "$input_hostname" ]] && HOSTNAME="$input_hostname"
  echo
fi

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
heading "NixOS Bootstrap Installer - $HOST"
[[ $EUID -ne 0 ]]   && die "Run as root: sudo bash install.sh"
[[ -d /nix/store ]] || die "This doesn't look like a NixOS live environment."
[[ "$DRY_RUN" == true ]] && warn "DRY-RUN -- no disk changes will be made."

info "Username: $USERNAME"
info "Hostname: $HOSTNAME"
info "Log file: $LOG_FILE"

# =============================================================================
# 1 / 8 · NETWORK
# =============================================================================
heading "[ 1 / 8 ]  Network"
ping -c1 -W3 1.1.1.1 &>/dev/null || {
  warn "No internet connection. Connect first, then re-run."
  echo "  nmtui   -- text UI (easiest)"
  exit 1
}
success "Network OK"

# =============================================================================
# 2 / 8 · DISK SELECTION
# =============================================================================
heading "[ 2 / 8 ]  Disk"

if [[ "$SKIP_FORMAT" == true ]]; then
  info "--skip-format set: existing partitions will be mounted by label."
  if [[ -n "$DISK" ]]; then
    warn "Disk argument ignored in skip-format mode (labels are used)."
    DISK=""
  fi
else
  if [[ -z "$DISK" ]]; then
    echo "  Available block devices:"
    lsblk -d -o NAME,SIZE,MODEL --noheadings | grep -v loop \
      | awk '{printf "    /dev/%-12s %6s  %s\n", $1, $2, $3}'
    echo
    ask DISK "  Enter disk (e.g., /dev/sda or /dev/nvme0n1)"
  fi
  [[ -b "$DISK" ]] || die "Disk '$DISK' not found."

  if [[ "$(lsblk -dno TYPE "$DISK")" != "disk" ]]; then
    die "Target '$DISK' is not a whole disk (type: $(lsblk -dno TYPE "$DISK")). Please specify the base disk."
  fi

  if [[ "$DISK" =~ [0-9]$ ]]; then
    PART_PREFIX="p"
  else
    PART_PREFIX=""
  fi
  PART_EFI="${DISK}${PART_PREFIX}1"
  PART_ROOT="${DISK}${PART_PREFIX}2"

  echo
  warn "This will ERASE all data on ${DISK}!"
  echo "    $PART_EFI   -- 512 MiB EFI System Partition (FAT32)"
  echo "    $PART_ROOT  -- remainder, ext4 (root)"
  if [[ "$DRY_RUN" == false ]]; then
    ask CONFIRM "  Type 'yes' to continue"
    [[ "$CONFIRM" == "yes" ]] || { info "Aborted."; exit 0; }
  fi
fi

# =============================================================================
# 3 / 8 · PARTITIONING (UEFI + ext4)
# =============================================================================
heading "[ 3 / 8 ]  Partitioning"
if [[ "$SKIP_FORMAT" == true ]]; then
  info "Skipping partitioning (using existing labels)."
elif [[ "$DRY_RUN" == true ]]; then
  info "Dry-run: would wipe $DISK and create:"
  echo "    $PART_EFI   -- 512 MiB EFI System Partition (FAT32)"
  echo "    $PART_ROOT  -- remainder, ext4 (root)"
else
  info "Stopping swap and forcefully unmounting any active partitions on $DISK..."
  swapoff -a 2>/dev/null || true

  for part in $(lsblk -ln -o NAME "$DISK" | tail -n +2); do
    umount -f "/dev/$part" 2>/dev/null || true
  done
  umount -R "$MOUNT" 2>/dev/null || true

  info "Acquiring exclusive disk lock and erasing existing layout..."
  flock "$DISK" sgdisk --zap-all "$DISK" || die "sgdisk --zap-all failed. Is the disk busy?"
  flock "$DISK" wipefs -a "$DISK" --force

  info "Forcing kernel to drop old partition cache..."
  blockdev --rereadpt "$DISK" 2>/dev/null || true
  partprobe "$DISK" 2>/dev/null || true
  udevadm settle

  info "Creating GPT partition table and defining layouts..."
  info "  -> Creating EFI partition..."
  flock "$DISK" sgdisk --new=1:0:+512M --typecode=1:ef00 --change-name=1:EFI "$DISK" \
    || die "Failed to create EFI partition."

  info "  -> Creating Root partition..."
  flock "$DISK" sgdisk --new=2:0:0 --typecode=2:8300 --change-name=2:nixos "$DISK" \
    || die "Failed to create Root partition."

  info "Forcing kernel storage layer to sync..."
  blockdev --rereadpt "$DISK" 2>/dev/null || true
  partprobe "$DISK" 2>/dev/null || true
  udevadm settle
  sleep 2

  [ -b "$PART_ROOT" ] || die "Partition $PART_ROOT did not appear after partitioning."

  info "Cleaning residual filesystem signatures from target partitions..."
  wipefs -a "$PART_EFI" --force >/dev/null 2>&1 || true
  wipefs -a "$PART_ROOT" --force >/dev/null 2>&1 || true

  info "Formatting partitions..."
  mkfs.fat -F 32 -n EFI    "$PART_EFI"
  mkfs.ext4 -F -L nixos    "$PART_ROOT"

  success "Disk partitioned and formatted successfully"
fi

# =============================================================================
# 4 / 8 · MOUNT
# =============================================================================
heading "[ 4 / 8 ]  Mounting"
if [[ "$DRY_RUN" == false ]]; then
  umount -R "$MOUNT" 2>/dev/null || true
  rm -rf "$MOUNT"/* 2>/dev/null || true

  info "Mounting root partition (label: nixos)..."
  mount /dev/disk/by-label/nixos "$MOUNT"
  mkdir -p "$MOUNT/boot"
  info "Mounting EFI partition (label: EFI)..."
  mount /dev/disk/by-label/EFI "$MOUNT/boot"
  success "Mounted root and EFI"
fi

# =============================================================================
# 5 / 8 · CLONE CONFIG
# =============================================================================
heading "[ 5 / 8 ]  Cloning NixOS config"
TARGET="$MOUNT/etc/nixos"
HOME_TARGET="$MOUNT/home/$USERNAME/NixConfig"
if [[ "$DRY_RUN" == false ]]; then
  mkdir -p "$MOUNT/home/$USERNAME"

  if [[ -e "$HOME_TARGET" ]]; then
    if [[ "$OVERWRITE" == true ]]; then
      info "--overwrite set: removing existing $HOME_TARGET..."
      rm -rf "$HOME_TARGET"
    else
      warn "Directory already exists: $HOME_TARGET"
      ask OVERWRITE_ANSWER "  Remove and re-clone" "N"
      if [[ "$OVERWRITE_ANSWER" =~ ^[Yy]([Ee][Ss])?$ ]]; then
        info "Removing existing $HOME_TARGET..."
        rm -rf "$HOME_TARGET"
      else
        die "Aborted: existing $HOME_TARGET kept."
      fi
    fi
  fi

  info "Cloning $REPO_URL (branch: $CONFIG_BRANCH) -> $HOME_TARGET"
  git clone -b "$CONFIG_BRANCH" "$REPO_URL" "$HOME_TARGET"

  info "Creating symlink /etc/nixos -> /home/$USERNAME/NixConfig"
  mkdir -p "$MOUNT/etc"
  # Use a relative symlink so it resolves to /mnt/home/... during install and
  # /home/... after the target system boots.
  ln -sfn "../home/$USERNAME/NixConfig" "$TARGET"

  success "Config cloned and symlinked"
fi

# =============================================================================
# 6 / 8 · GENERATE HARDWARE CONFIG & INSTALLER OVERRIDES
# =============================================================================
heading "[ 6 / 8 ]  Hardware config and installer options"
if [[ "$DRY_RUN" == true ]]; then
  info "Dry-run: would run nixos-generate-config and save to $TARGET/modules/hosts/$HOST/_hardware-generated.nix"
  info "Dry-run: would write installer options to $TARGET/modules/hosts/$HOST/_installer-options.nix"
else
  info "Generating hardware config (fileSystems, swap) for host '$HOST'..."
  HW_FILE="$TARGET/modules/hosts/$HOST/_hardware-generated.nix"
  INSTALLER_OPTIONS_FILE="$TARGET/modules/hosts/$HOST/_installer-options.nix"

  mkdir -p "$(dirname "$HW_FILE")"
  mkdir -p "$TARGET/__gen_tmp"

  # CRITICAL FIX: --root /mnt ensures it scans the TARGET disk, not the live USB
  info "Running nixos-generate-config --root /mnt ..."
  nixos-generate-config --root /mnt --dir "$TARGET/__gen_tmp" || die "nixos-generate-config failed to run."

  if [[ ! -f "$TARGET/__gen_tmp/hardware-configuration.nix" ]]; then
    die "nixos-generate-config succeeded but did not create hardware-configuration.nix. Check /mnt mount."
  fi

  info "Moving generated config to $HW_FILE"
  mv "$TARGET/__gen_tmp/hardware-configuration.nix" "$HW_FILE" || die "Failed to move hardware config to $HW_FILE."

  rm -rf "$TARGET/__gen_tmp"
  success "Wrote $HW_FILE"

  info "Writing installer options (username, hostname) to $INSTALLER_OPTIONS_FILE"
  cat > "$INSTALLER_OPTIONS_FILE" <<EOF
{ lib, ... }:
{
  username = lib.mkForce "$USERNAME";
  networking.hostName = lib.mkForce "$HOSTNAME";
}
EOF
  success "Wrote $INSTALLER_OPTIONS_FILE"

  # Nix flakes only include files tracked by git. Stage the generated files so
  # the flake actually sees them during installation. _installer-options.nix is
  # gitignored, so it has to be force-added.
  info "Staging generated files for flake evaluation..."
  git -C "$HOME_TARGET" add "modules/hosts/$HOST/_hardware-generated.nix" || \
    warn "Could not stage hardware config; the flake may not see it."
  git -C "$HOME_TARGET" add -f "modules/hosts/$HOST/_installer-options.nix" || \
    warn "Could not stage installer options; the flake may not see them."
fi

# =============================================================================
# 7 / 8 · FLAKE VALIDATION & INSTALL
# =============================================================================
heading "[ 7 / 8 ]  Installing NixOS"
if [[ "$DRY_RUN" == true ]]; then
  info "Dry-run: would validate flake with 'nix flake metadata $TARGET'"
  info "Dry-run: would run nixos-install --flake ${TARGET}#${HOST}"
else
  info "Validating flake..."
  nix flake metadata "$TARGET" || die "Flake validation failed. Check the output above."
  success "Flake OK"

  if [[ "$UPDATE" == true ]]; then
    info "Updating flake inputs..."
    nix flake update "$TARGET" || die "nix flake update failed."
  fi

  info "Running nixos-install (this will take a while)..."
  nixos-install --flake "${TARGET}#${HOST}" --no-root-passwd
  success "NixOS installed"
fi

# =============================================================================
# 8 / 8 · POST-INSTALL
# =============================================================================
heading "[ 8 / 8 ]  Post-install setup"
if [[ "$DRY_RUN" == false ]]; then
  echo
  info "Set a password for root:"
  until nixos-enter --root "$MOUNT" -- passwd root; do warn "Try again."; done
  success "Root password set"

  echo
  info "Set a password for ${USERNAME}:"
  until nixos-enter --root "$MOUNT" -- passwd "$USERNAME"; do warn "Try again."; done
  success "Password set for ${USERNAME}"

  info "Fixing ownership of /home/${USERNAME}/NixConfig..."
  nixos-enter --root "$MOUNT" -- chown -R "$USERNAME" "/home/$USERNAME/NixConfig" || \
    warn "Could not fix ownership. After reboot run: sudo chown -R $USERNAME /home/$USERNAME/NixConfig"

  # SSH key from local file
  if [[ -n "$COPY_SSH_KEY" ]]; then
    if [[ -f "$COPY_SSH_KEY" ]]; then
      SSH_DIR="$MOUNT/home/$USERNAME/.ssh"
      mkdir -p "$SSH_DIR"
      cp "$COPY_SSH_KEY" "$SSH_DIR/authorized_keys"
      chmod 700 "$SSH_DIR"
      chmod 600 "$SSH_DIR/authorized_keys"
      nixos-enter --root "$MOUNT" -- chown -R "$USERNAME" "/home/$USERNAME/.ssh"
      success "Copied SSH key from $COPY_SSH_KEY"
    else
      warn "SSH key file not found: $COPY_SSH_KEY -- skipping."
    fi
  fi

  # SSH key from GitHub
  GH_USER="$SSH_KEY_GITHUB"
  if [[ -z "$GH_USER" && -z "$COPY_SSH_KEY" ]]; then
    ask GH_USER "  Import SSH keys from GitHub? Enter username (or Enter to skip)"
  fi
  if [[ -n "$GH_USER" && -z "$COPY_SSH_KEY" ]]; then
    SSH_DIR="$MOUNT/home/$USERNAME/.ssh"
    mkdir -p "$SSH_DIR"
    if curl -fsSL "https://github.com/${GH_USER}.keys" -o "$SSH_DIR/authorized_keys"; then
      chmod 700 "$SSH_DIR"; chmod 600 "$SSH_DIR/authorized_keys"
      nixos-enter --root "$MOUNT" -- chown -R "$USERNAME" "/home/$USERNAME/.ssh"
      success "SSH keys imported from github.com/${GH_USER}"
    else
      warn "Could not fetch keys -- skipping."
    fi
  fi

  info "Copying install log to target..."
  mkdir -p "$MOUNT/var/log"
  cp "$LOG_FILE" "$MOUNT/var/log/nixos-install.log" 2>/dev/null || \
    warn "Could not copy install log to /var/log"
fi

# =============================================================================
# DONE
# =============================================================================
heading "Summary"
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
