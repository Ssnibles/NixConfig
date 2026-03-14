#!/usr/bin/env bash
# =============================================================================
# NixOS Bootstrap Installer
# Run this from the minimal ISO after connecting to WiFi.
#
# Usage:
#   sudo bash install.sh [--disk /dev/sdX] [--swap <GB>]
# =============================================================================

set -euo pipefail

REPO_URL="https://github.com/Ssnibles/NixConfig.git"
FLAKE_HOST="nixos"
MOUNT="/mnt"
USERNAME="josh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}  →${NC} $*"; }
success() { echo -e "${GREEN}  ✓${NC} $*"; }
warn()    { echo -e "${YELLOW}  !${NC} $*"; }
die()     { echo -e "${RED}  ✗ ERROR:${NC} $*" >&2; exit 1; }
heading() { echo -e "\n${BOLD}$*${NC}"; }

# =============================================================================
# PREFLIGHT
# =============================================================================
heading "=== NixOS Bootstrap Installer ==="

[[ $EUID -ne 0 ]] && die "Run as root: sudo bash install.sh"
[[ -d /nix/store ]] || die "This doesn't look like a NixOS live environment."

# =============================================================================
# 1 · NETWORK
# =============================================================================
heading "[ 1 / 7 ]  Network"

if ! ping -c1 -W3 1.1.1.1 &>/dev/null; then
  warn "No internet connection detected."
  echo
  echo "  Connect to WiFi first, then re-run this script."
  echo "  Quick options:"
  echo
  echo "    nmtui                                   # text UI (easiest)"
  echo "    wpa_supplicant -B -i wlan0 \\"
  echo "      -c <(wpa_passphrase SSID PASS)        # manual"
  echo
  exit 1
fi
success "Network OK"

# =============================================================================
# 2 · DISK SELECTION
# =============================================================================
heading "[ 2 / 7 ]  Disk"

DISK=""
SWAP_GB=0

while [[ $# -gt 0 ]]; do
  case $1 in
    --disk) DISK="$2"; shift 2 ;;
    --swap) SWAP_GB="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [[ -z "$DISK" ]]; then
  echo
  echo "  Available block devices:"
  lsblk -d -o NAME,SIZE,MODEL --noheadings | grep -v "loop" | \
    awk '{printf "    /dev/%-10s %s  %s\n", $1, $2, $3}'
  echo
  read -rp "  Enter disk to install on (e.g. /dev/sda or /dev/nvme0n1): " DISK
fi

[[ -b "$DISK" ]] || die "Disk '$DISK' not found."

# Work out partition naming (nvme/mmcblk use p1/p2, sata/virtio use 1/2)
if [[ "$DISK" == *"nvme"* || "$DISK" == *"mmcblk"* ]]; then
  PART_ESP="${DISK}p1"
  PART_ROOT="${DISK}p2"
  PART_SWAP="${DISK}p3"
else
  PART_ESP="${DISK}1"
  PART_ROOT="${DISK}2"
  PART_SWAP="${DISK}3"
fi

# If swap requested, root moves to partition 3
if [[ "$SWAP_GB" -gt 0 ]]; then
  if [[ "$DISK" == *"nvme"* || "$DISK" == *"mmcblk"* ]]; then
    PART_ROOT="${DISK}p3"; PART_SWAP="${DISK}p2"
  else
    PART_ROOT="${DISK}3"; PART_SWAP="${DISK}2"
  fi
fi

echo
warn "This will ERASE all data on ${DISK}!"
read -rp "  Type 'yes' to continue: " CONFIRM
[[ "$CONFIRM" == "yes" ]] || { info "Aborted."; exit 0; }

# =============================================================================
# 3 · PARTITION & FORMAT
# =============================================================================
heading "[ 3 / 7 ]  Partitioning & formatting"

info "Wiping $DISK..."
wipefs -a "$DISK" &>/dev/null || true
sgdisk --zap-all "$DISK" &>/dev/null || true

if [[ "$SWAP_GB" -gt 0 ]]; then
  info "Creating ESP + ${SWAP_GB}GB swap + root..."
  parted -s "$DISK" -- \
    mklabel gpt \
    mkpart ESP fat32 1MB 512MB \
    set 1 esp on \
    mkpart swap linux-swap 512MB "$((512 + SWAP_GB * 1024))MB" \
    mkpart primary ext4 "$((512 + SWAP_GB * 1024))MB" 100%
else
  info "Creating ESP + root..."
  parted -s "$DISK" -- \
    mklabel gpt \
    mkpart ESP fat32 1MB 512MB \
    set 1 esp on \
    mkpart primary ext4 512MB 100%
fi

sleep 1; partprobe "$DISK" 2>/dev/null || true; sleep 1

info "Formatting..."
mkfs.fat -F 32 -n ESP "$PART_ESP"
mkfs.ext4 -L nixos "$PART_ROOT" -F
[[ "$SWAP_GB" -gt 0 ]] && mkswap -L swap "$PART_SWAP"

info "Mounting..."
mount "$PART_ROOT" "$MOUNT"
mkdir -p "$MOUNT/boot"
mount "$PART_ESP" "$MOUNT/boot"
[[ "$SWAP_GB" -gt 0 ]] && swapon "$PART_SWAP"

success "Disk ready"

# =============================================================================
# 4 · GIT
# =============================================================================
heading "[ 4 / 7 ]  Installing git"

if ! command -v git &>/dev/null; then
  nix-env -iA nixos.git --quiet
fi
success "git available"

# =============================================================================
# 5 · CLONE & HARDWARE CONFIG
# =============================================================================
heading "[ 5 / 7 ]  Cloning NixOS config"

TARGET="$MOUNT/etc/nixos"

if [[ -d "$TARGET/.git" ]]; then
  warn "Repo already present — pulling latest..."
  git -C "$TARGET" pull
else
  info "Cloning $REPO_URL → $TARGET"
  git clone "$REPO_URL" "$TARGET"
fi

info "Generating hardware-configuration.nix for this machine..."
nixos-generate-config --root "$MOUNT" --show-hardware-config \
  > "$TARGET/hardware-configuration.nix"

# Fix /boot mount permissions — FAT32 doesn't support Unix permissions so
# systemd-boot warns about world-accessible files unless fmask/dmask are set.
# Replace the default 0022 masks if present, then verify 0077 is in place.
info "Fixing /boot mount permissions..."
sed -i 's/fmask=0022/fmask=0077/g; s/dmask=0022/dmask=0077/g' \
  "$TARGET/hardware-configuration.nix"
if ! grep -q "fmask=0077" "$TARGET/hardware-configuration.nix"; then
  sed -i '/fsType = "vfat"/a\      options = [ "fmask=0077" "dmask=0077" ];' \
    "$TARGET/hardware-configuration.nix"
fi

success "Config ready"

# =============================================================================
# 6 · INSTALL
# =============================================================================
heading "[ 6 / 7 ]  Installing NixOS"

info "Running nixos-install (this will take a while)..."
echo

nixos-install --flake "${TARGET}#${FLAKE_HOST}" --no-root-passwd

# =============================================================================
# 7 · PASSWORDS & POST-INSTALL SETUP
# =============================================================================
heading "[ 7 / 7 ]  Post-install setup"

# Root password
echo
info "Set a password for root:"
until nixos-enter --root "$MOUNT" -- passwd root; do
  warn "Something went wrong — try again."
done
success "Root password set"

# User password
echo
info "Set a password for ${USERNAME}:"
until nixos-enter --root "$MOUNT" -- passwd "$USERNAME"; do
  warn "Something went wrong — try again."
done
success "Password set for ${USERNAME}"

# Clone config into the user's home so the `rebuild` fish abbreviation works
info "Cloning config into /home/${USERNAME}/NixConfig..."
nixos-enter --root "$MOUNT" -- \
  su - "$USERNAME" -c "git clone $REPO_URL /home/$USERNAME/NixConfig"
success "Config cloned to ~/NixConfig"

# =============================================================================
# DONE
# =============================================================================
echo
echo -e "${GREEN}${BOLD}  All done — rebooting in 5 seconds...${NC}"
echo "  (Ctrl-C to cancel)"
echo
sleep 5
reboot
