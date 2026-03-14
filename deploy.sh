#!/usr/bin/env bash
# =============================================================================
# NixOS Bootstrap Installer
# Run this from the minimal ISO after connecting to WiFi.
#
# Usage:
#   bash install.sh [--disk /dev/sdX] [--swap <GB>]
#
# What it does:
#   1. Checks you're running from the NixOS ISO
#   2. Lists disks and asks which one to use
#   3. Partitions, formats, and mounts (ESP + root + optional swap)
#   4. Clones your NixOS config from GitHub
#   5. Generates hardware-configuration.nix for this machine
#   6. Runs nixos-install
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIG — edit these if needed
# =============================================================================
REPO_URL="https://github.com/Ssnibles/NixConfig.git"
FLAKE_HOST="nixos"
MOUNT="/mnt"

# =============================================================================
# COLOURS
# =============================================================================
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

# Check we're on the NixOS live ISO
[[ -f /etc/nixos/configuration.nix || -d /nix/store ]] \
  || die "This doesn't look like a NixOS live environment."

# =============================================================================
# WIFI CHECK
# =============================================================================
heading "[ 1 / 6 ]  Network"

if ! ping -c1 -W3 1.1.1.1 &>/dev/null; then
  warn "No internet connection detected."
  echo
  echo "  Connect to WiFi first, then re-run this script."
  echo "  Quick options:"
  echo
  echo "    nmtui                              # text UI (easiest)"
  echo "    iwctl                              # iwd interactive shell"
  echo "    wpa_supplicant -B -i wlan0 \\"
  echo "      -c <(wpa_passphrase SSID PASS)   # manual"
  echo
  exit 1
fi
success "Network OK"

# =============================================================================
# DISK SELECTION
# =============================================================================
heading "[ 2 / 6 ]  Disk"

DISK=""

# Allow --disk flag
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

# Work out partition naming (nvme uses p1/p2, sata/virtio uses 1/2)
if [[ "$DISK" == *"nvme"* || "$DISK" == *"mmcblk"* ]]; then
  PART_ESP="${DISK}p1"
  PART_ROOT="${DISK}p2"
  PART_SWAP="${DISK}p3"
else
  PART_ESP="${DISK}1"
  PART_ROOT="${DISK}2"
  PART_SWAP="${DISK}3"
fi

SWAP_GB="${SWAP_GB:-0}"

echo
warn "This will ERASE all data on ${DISK}!"
read -rp "  Type 'yes' to continue: " CONFIRM
[[ "$CONFIRM" == "yes" ]] || { info "Aborted."; exit 0; }

# =============================================================================
# PARTITION & FORMAT
# =============================================================================
heading "[ 3 / 6 ]  Partitioning & formatting"

info "Wiping and partitioning $DISK..."

# Wipe existing partition table
wipefs -a "$DISK" &>/dev/null || true
sgdisk --zap-all "$DISK" &>/dev/null || true

if [[ "$SWAP_GB" -gt 0 ]]; then
  info "Creating ESP + root + ${SWAP_GB}GB swap..."
  parted -s "$DISK" -- \
    mklabel gpt \
    mkpart ESP fat32 1MB 512MB \
    set 1 esp on \
    mkpart swap linux-swap 512MB "$((512 + SWAP_GB * 1024))MB" \
    mkpart primary ext4 "$((512 + SWAP_GB * 1024))MB" 100%
  PART_ROOT="${DISK}$([ "$DISK" == *nvme* ] && echo p3 || echo 3)"
  PART_SWAP="${DISK}$([ "$DISK" == *nvme* ] && echo p2 || echo 2)"
  PART_ROOT="${DISK}$([ "$DISK" == *"nvme"* ] && echo p3 || echo 3)"
  PART_SWAP="${DISK}$([ "$DISK" == *"nvme"* ] && echo p2 || echo 2)"
else
  info "Creating ESP + root (no swap)..."
  parted -s "$DISK" -- \
    mklabel gpt \
    mkpart ESP fat32 1MB 512MB \
    set 1 esp on \
    mkpart primary ext4 512MB 100%
fi

# Give the kernel a moment to see the new partitions
sleep 1
partprobe "$DISK" 2>/dev/null || true
sleep 1

info "Formatting partitions..."
mkfs.fat -F 32 -n ESP "$PART_ESP"
mkfs.ext4 -L nixos "$PART_ROOT" -F

if [[ "$SWAP_GB" -gt 0 ]]; then
  mkswap -L swap "$PART_SWAP"
fi

info "Mounting..."
mount "$PART_ROOT" "$MOUNT"
mkdir -p "$MOUNT/boot"
mount "$PART_ESP" "$MOUNT/boot"

if [[ "$SWAP_GB" -gt 0 ]]; then
  swapon "$PART_SWAP"
fi

success "Disk ready"

# =============================================================================
# INSTALL GIT
# =============================================================================
heading "[ 4 / 6 ]  Installing git"

if ! command -v git &>/dev/null; then
  info "Installing git into the live environment..."
  nix-env -iA nixos.git --quiet
fi
success "git available"

# =============================================================================
# CLONE CONFIG
# =============================================================================
heading "[ 5 / 6 ]  Cloning NixOS config"

TARGET="$MOUNT/etc/nixos"

if [[ -d "$TARGET/.git" ]]; then
  warn "Config already cloned at $TARGET — pulling latest..."
  git -C "$TARGET" pull
else
  info "Cloning $REPO_URL → $TARGET"
  git clone "$REPO_URL" "$TARGET"
fi

# Generate hardware config for this machine and drop it into the cloned repo.
# hardware-configuration.nix is in .gitignore so this file stays local.
info "Generating hardware-configuration.nix for this machine..."
nixos-generate-config --root "$MOUNT" --show-hardware-config \
  > "$TARGET/hardware-configuration.nix"

success "Config ready"

# =============================================================================
# INSTALL
# =============================================================================
heading "[ 6 / 6 ]  Installing NixOS"

info "Running nixos-install --flake ${TARGET}#${FLAKE_HOST}"
info "This will take a while on first install (downloading packages)..."
echo

nixos-install --flake "${TARGET}#${FLAKE_HOST}" --no-root-passwd

# =============================================================================
# DONE
# =============================================================================
echo
echo -e "${GREEN}${BOLD}  Installation complete!${NC}"
echo
echo "  Next steps:"
echo "    1. Set a root password:   nixos-enter --root $MOUNT -- passwd"
echo "    2. Reboot:                reboot"
echo "    3. Clone your config:     git clone $REPO_URL ~/NixConfig"
echo "    4. Future rebuilds:       rebuild  (fish abbreviation)"
echo
