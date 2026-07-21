#!/usr/bin/env bash
# =============================================================================
# NixOS Bootstrap Installer
# =============================================================================
set -euo pipefail

REPO_URL="https://github.com/Ssnibles/NixConfig.git"
CONFIG_BRANCH="dendritic"
MOUNT="/mnt"
USERNAME="josh"

# ── Colours ───────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

info()    { echo -e "${BLUE}  →${NC} $*"; }
success() { echo -e "${GREEN}  ✓${NC} $*"; }
warn()    { echo -e "${YELLOW}  !${NC} $*"; }
die()     { echo -e "${RED}  ✗ ERROR:${NC} $*" >&2; exit 1; }
heading() { echo -e "\n${BOLD}━━━  $*  ━━━${NC}"; }

# ── Argument parsing ──────────────────────────────────────────────────────
DISK=""
DRY_RUN=false
HOST=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --host)    HOST="$2";    shift 2 ;;
    --disk)    DISK="$2";    shift 2 ;;
    --dry-run) DRY_RUN=true; shift   ;;
    -h|--help)
      echo "Usage: sudo bash install.sh --host <desktop|laptop> [--disk /dev/sdX] [--dry-run]"
      exit 0 ;;
    *) warn "Unknown argument: $1"; shift ;;
  esac
done

if [[ -z "$HOST" ]]; then
  die "Host required. Use --host desktop or --host laptop"
fi

case "$HOST" in
  desktop|laptop) ;;
  *) die "Unknown host '$HOST'. Available: desktop, laptop" ;;
esac

# ── Cleanup trap ──────────────────────────────────────────────────────────
cleanup() {
  local code=$?
  if [[ $code -ne 0 && "$DRY_RUN" == false ]]; then
    warn "Install failed (exit $code) — cleaning up mounts..."
    umount -R "$MOUNT" 2>/dev/null || true
    swapoff -a 2>/dev/null || true
    echo -e "${RED}  ✗ Aborted. Disk unmounted.${NC}"
  fi
}
trap cleanup EXIT

# ── Preflight ─────────────────────────────────────────────────────────────
heading "NixOS Bootstrap Installer - $HOST"
[[ $EUID -ne 0 ]]   && die "Run as root: sudo bash install.sh"
[[ -d /nix/store ]] || die "This doesn't look like a NixOS live environment."
[[ "$DRY_RUN" == true ]] && warn "DRY-RUN — no disk changes will be made."

# =============================================================================
# 1 · NETWORK
# =============================================================================
heading "[ 1 / 7 ]  Network"
ping -c1 -W3 1.1.1.1 &>/dev/null || {
  warn "No internet connection. Connect first, then re-run."
  echo "  nmtui   — text UI (easiest)"
  exit 1
}
success "Network OK"

# =============================================================================
# 2 · DISK SELECTION
# =============================================================================
heading "[ 2 / 7 ]  Disk"
if [[ -z "$DISK" ]]; then
  echo "  Available block devices:"
  lsblk -d -o NAME,SIZE,MODEL --noheadings | grep -v loop \
    | awk '{printf "    /dev/%-12s %6s  %s\n", $1, $2, $3}'
  echo
  read -rp "  Enter disk (e.g., /dev/sda or /dev/nvme0n1): " DISK
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
if [[ "$DRY_RUN" == false ]]; then
  read -rp "  Type 'yes' to continue: " CONFIRM
  [[ "$CONFIRM" == "yes" ]] || { info "Aborted."; exit 0; }
fi

# =============================================================================
# 3 · PARTITIONING (UEFI + ext4)
# =============================================================================
heading "[ 3 / 7 ]  Partitioning"
if [[ "$DRY_RUN" == true ]]; then
  info "Dry-run: would wipe $DISK and create:"
  echo "    $PART_EFI   — 512 MiB EFI System Partition (FAT32)"
  echo "    $PART_ROOT  — remainder, ext4 (root)"
else
  info "Stopping swap and forcefully unmounting ANY active partitions on $DISK..."
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
# 4 · MOUNT
# =============================================================================
heading "[ 4 / 7 ]  Mounting"
if [[ "$DRY_RUN" == false ]]; then
  umount -R "$MOUNT" 2>/dev/null || true
  rm -rf "$MOUNT"/* 2>/dev/null || true
  
  mount -t ext4 "$PART_ROOT" "$MOUNT"
  mkdir -p "$MOUNT/boot"
  mount "$PART_EFI" "$MOUNT/boot"
  success "Mounted root ($PART_ROOT) and EFI ($PART_EFI)"
fi

# =============================================================================
# 5 · CLONE CONFIG
# =============================================================================
heading "[ 5 / 7 ]  Cloning NixOS config"
TARGET="$MOUNT/etc/nixos"
if [[ "$DRY_RUN" == false ]]; then
  mkdir -p "$TARGET"
  info "Cloning $REPO_URL (branch: $CONFIG_BRANCH) → $TARGET"
  git clone -b "$CONFIG_BRANCH" "$REPO_URL" "$TARGET"
  chown -R "$USERNAME:users" "$TARGET"
  success "Config cloned"
fi

# =============================================================================
# 6 · GENERATE HARDWARE CONFIG & INSTALL
# =============================================================================
heading "[ 6 / 7 ]  Installing NixOS"
if [[ "$DRY_RUN" == true ]]; then
  info "Dry-run: would run nixos-generate-config and save to $TARGET/modules/hosts/$HOST/_hardware-generated.nix"
  info "Dry-run: would run nixos-install --flake ${TARGET}#${HOST}"
else
  info "Generating hardware config (fileSystems, swap) for host '$HOST'..."
  HW_FILE="$TARGET/modules/hosts/$HOST/_hardware-generated.nix"
  
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
  chown "$USERNAME:users" "$HW_FILE"
  success "Wrote $HW_FILE"

  info "Running nixos-install (this will take a while)..."
  nixos-install --flake "${TARGET}#${HOST}" --no-root-passwd
  success "NixOS installed"
fi

# =============================================================================
# 7 · POST-INSTALL
# =============================================================================
heading "[ 7 / 7 ]  Post-install setup"
if [[ "$DRY_RUN" == false ]]; then
  echo
  info "Set a password for root:"
  until nixos-enter --root "$MOUNT" -- passwd root; do warn "Try again."; done
  success "Root password set"

  echo
  info "Set a password for ${USERNAME}:"
  until nixos-enter --root "$MOUNT" -- passwd "$USERNAME"; do warn "Try again."; done
  success "Password set for ${USERNAME}"

  info "Cloning config into /home/${USERNAME}/NixConfig..."
  nixos-enter --root "$MOUNT" -- \
    su - "$USERNAME" -c "git clone -b $CONFIG_BRANCH $REPO_URL /home/$USERNAME/NixConfig" || \
    warn "Clone into home failed; config is still at /etc/nixos."

  echo
  read -rp "  Import SSH keys from GitHub? Enter username (or Enter to skip): " GH_USER
  if [[ -n "$GH_USER" ]]; then
    SSH_DIR="$MOUNT/home/$USERNAME/.ssh"
    mkdir -p "$SSH_DIR"
    if curl -fsSL "https://github.com/${GH_USER}.keys" -o "$SSH_DIR/authorized_keys"; then
      chmod 700 "$SSH_DIR"; chmod 600 "$SSH_DIR/authorized_keys"
      nixos-enter --root "$MOUNT" -- chown -R "$USERNAME:users" "/home/$USERNAME/.ssh"
      success "SSH keys imported from github.com/${GH_USER}"
    else
      warn "Could not fetch keys — skipping."
    fi
  fi
fi

# =============================================================================
# DONE
# =============================================================================
heading "Summary"
echo -e "  ${GREEN}${BOLD}Installation complete!${NC}"
[[ "$DRY_RUN" == false ]] && lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT "$DISK" | sed 's/^/    /'
echo
echo -e "  ${BOLD}After reboot:${NC}"
echo -e "  ${DIM}1. Log in as ${USERNAME}${NC}"
echo -e "  ${DIM}2. Config is at ~/NixConfig (and /etc/nixos)${NC}"
echo -e "  ${DIM}3. Rebuild:  sudo nixos-rebuild switch --flake ~/NixConfig#${HOST}${NC}"
echo
[[ "$DRY_RUN" == true ]] && { warn "Dry-run complete — nothing was changed."; exit 0; }
echo -e "${GREEN}${BOLD}  Rebooting in 5 seconds...${NC}  (Ctrl-C to cancel)"
sleep 5
reboot
