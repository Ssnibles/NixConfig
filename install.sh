#!/usr/bin/env bash
# =============================================================================
# NixOS Bootstrap Installer
# Run this from the minimal ISO after connecting to WiFi.
#
# Usage:
#   sudo bash install.sh [--disk /dev/sdX] [--swap <GB>] [--dry-run]
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
DIM='\033[2m'
NC='\033[0m'

info()    { echo -e "${BLUE}  →${NC} $*"; }
success() { echo -e "${GREEN}  ✓${NC} $*"; }
warn()    { echo -e "${YELLOW}  !${NC} $*"; }
die()     { echo -e "${RED}  ✗ ERROR:${NC} $*" >&2; exit 1; }
heading() { echo -e "\n${BOLD}━━━  $*  ━━━${NC}"; }
dim()     { echo -e "${DIM}  $*${NC}"; }

DRY_RUN=false

# =============================================================================
# CLEANUP TRAP
# If anything fails mid-install, unmount cleanly so the disk isn't left in a
# partial state that makes re-running the script awkward.
# =============================================================================
cleanup() {
  local exit_code=$?
  if [[ $exit_code -ne 0 && "$DRY_RUN" == false ]]; then
    echo
    warn "Install failed (exit $exit_code) — cleaning up mounts..."
    # Unmount in reverse order; ignore errors (partitions may not be mounted yet)
    swapoff "$PART_SWAP" 2>/dev/null || true
    umount "$MOUNT/boot"  2>/dev/null || true
    umount "$MOUNT"       2>/dev/null || true
    echo -e "${RED}  ✗ Aborted. Disk has been unmounted.${NC}"
  fi
}
trap cleanup EXIT

# =============================================================================
# PREFLIGHT
# =============================================================================
heading "NixOS Bootstrap Installer"

[[ $EUID -ne 0 ]]   && die "Run as root: sudo bash install.sh"
[[ -d /nix/store ]] || die "This doesn't look like a NixOS live environment."

# =============================================================================
# ARGUMENT PARSING
# =============================================================================
DISK=""
SWAP_GB=""  # empty = not yet decided

while [[ $# -gt 0 ]]; do
  case $1 in
    --disk)    DISK="$2";    shift 2 ;;
    --swap)    SWAP_GB="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift   ;;
    -h|--help)
      echo "Usage: sudo bash install.sh [--disk /dev/sdX] [--swap <GB>] [--dry-run]"
      echo
      echo "  --disk    Target block device (prompted if omitted)"
      echo "  --swap    Swap partition size in GB (0 to skip; prompted if omitted)"
      echo "  --dry-run Show what would happen without touching the disk"
      exit 0
      ;;
    *) warn "Unknown argument: $1"; shift ;;
  esac
done

if [[ "$DRY_RUN" == true ]]; then
  warn "DRY-RUN mode — no changes will be made to disk."
fi

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

if [[ -z "$DISK" ]]; then
  echo
  echo "  Available block devices:"
  lsblk -d -o NAME,SIZE,MODEL --noheadings | grep -v "loop" | \
    awk '{printf "    /dev/%-12s %6s  %s\n", $1, $2, $3}'
  echo
  read -rp "  Enter disk to install on (e.g. /dev/sda or /dev/nvme0n1): " DISK
fi

[[ -b "$DISK" ]] || die "Disk '$DISK' not found."

# Show current partition table so the user knows what they're erasing
echo
info "Current layout of ${DISK}:"
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT "$DISK" 2>/dev/null | \
  sed 's/^/    /' || true
echo

# Prompt for swap size if not supplied via flag
if [[ -z "$SWAP_GB" ]]; then
  read -rp "  Swap size in GB (0 to skip, recommended 8 for 16 GB RAM): " SWAP_GB
  SWAP_GB="${SWAP_GB:-0}"
fi

# Work out partition naming (nvme/mmcblk use p1/p2, sata/virtio use 1/2)
if [[ "$DISK" == *"nvme"* || "$DISK" == *"mmcblk"* ]]; then
  PART_PREFIX="${DISK}p"
else
  PART_PREFIX="${DISK}"
fi

if [[ "$SWAP_GB" -gt 0 ]]; then
  PART_ESP="${PART_PREFIX}1"
  PART_SWAP="${PART_PREFIX}2"
  PART_ROOT="${PART_PREFIX}3"
else
  PART_ESP="${PART_PREFIX}1"
  PART_ROOT="${PART_PREFIX}2"
  PART_SWAP=""
fi

# Summary before the point of no return
echo
echo -e "  ${BOLD}Planned layout:${NC}"
echo "    ${PART_ESP}   →  512 MB   EFI System Partition (vfat)"
if [[ "$SWAP_GB" -gt 0 ]]; then
  echo "    ${PART_SWAP}   →  ${SWAP_GB} GB     Swap"
fi
echo "    ${PART_ROOT}   →  rest     Root / (ext4)"
echo

warn "This will ERASE all data on ${DISK}!"
if [[ "$DRY_RUN" == true ]]; then
  info "Dry-run: skipping confirmation and disk operations."
else
  read -rp "  Type 'yes' to continue: " CONFIRM
  [[ "$CONFIRM" == "yes" ]] || { info "Aborted."; exit 0; }
fi

# =============================================================================
# 3 · PARTITION & FORMAT
# =============================================================================
heading "[ 3 / 7 ]  Partitioning & formatting"

if [[ "$DRY_RUN" == true ]]; then
  info "Dry-run: would partition, format, and mount ${DISK}."
else
  info "Wiping $DISK..."
  wipefs -a "$DISK"       &>/dev/null || true
  sgdisk --zap-all "$DISK" &>/dev/null || true

  if [[ "$SWAP_GB" -gt 0 ]]; then
    info "Creating ESP + ${SWAP_GB} GB swap + root..."
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

  # Wait for the kernel to register the new partitions before formatting.
  # udevadm settle is more reliable than a bare sleep.
  partprobe "$DISK" 2>/dev/null || true
  udevadm settle
  sleep 1

  info "Formatting..."
  mkfs.fat -F 32 -n ESP "$PART_ESP"
  mkfs.ext4 -L nixos "$PART_ROOT" -F
  [[ -n "$PART_SWAP" ]] && mkswap -L swap "$PART_SWAP"

  info "Mounting..."
  mount "$PART_ROOT" "$MOUNT"
  mkdir -p "$MOUNT/boot"
  mount "$PART_ESP" "$MOUNT/boot"
  [[ -n "$PART_SWAP" ]] && swapon "$PART_SWAP"

  success "Disk ready"
fi

# =============================================================================
# 4 · GIT
# =============================================================================
heading "[ 4 / 7 ]  Installing git"

if ! command -v git &>/dev/null; then
  [[ "$DRY_RUN" == false ]] && nix-env -iA nixos.git --quiet
fi
success "git available"

# =============================================================================
# 5 · CLONE & HARDWARE CONFIG
# =============================================================================
heading "[ 5 / 7 ]  Cloning NixOS config"

TARGET="$MOUNT/etc/nixos"

if [[ "$DRY_RUN" == false ]]; then
  if [[ -d "$TARGET/.git" ]]; then
    warn "Repo already present — pulling latest..."
    git -C "$TARGET" pull
  else
    info "Cloning $REPO_URL → $TARGET"
    git clone "$REPO_URL" "$TARGET"
  fi

  # -------------------------------------------------------------------------
  # Generate hardware-configuration.nix for THIS machine and write it into
  # both the system location and the repo copy.  This is the fix for the UUID
  # mismatch bug: the repo copy must always reflect the actual hardware.
  # -------------------------------------------------------------------------
  info "Generating hardware-configuration.nix for this machine..."
  nixos-generate-config --root "$MOUNT" --show-hardware-config \
    > "$TARGET/hardware-configuration.nix"

  # Fix /boot mount permissions — FAT32 has no Unix permissions, so systemd-boot
  # warns about world-readable files unless fmask/dmask=0077 are set.
  info "Fixing /boot mount permissions..."
  sed -i 's/fmask=0022/fmask=0077/g; s/dmask=0022/dmask=0077/g' \
    "$TARGET/hardware-configuration.nix"
  if ! grep -q "fmask=0077" "$TARGET/hardware-configuration.nix"; then
    sed -i '/fsType = "vfat"/a\      options = [ "fmask=0077" "dmask=0077" ];' \
      "$TARGET/hardware-configuration.nix"
  fi

  success "Config ready"
fi

# =============================================================================
# 6 · INSTALL
# =============================================================================
heading "[ 6 / 7 ]  Installing NixOS"

if [[ "$DRY_RUN" == true ]]; then
  info "Dry-run: would run nixos-install --flake ${TARGET}#${FLAKE_HOST}"
else
  info "Running nixos-install (this will take a while)..."
  echo
  nixos-install --flake "${TARGET}#${FLAKE_HOST}" --no-root-passwd
fi

# =============================================================================
# 7 · POST-INSTALL SETUP
# =============================================================================
heading "[ 7 / 7 ]  Post-install setup"

if [[ "$DRY_RUN" == false ]]; then

  # --- Passwords -----------------------------------------------------------
  echo
  info "Set a password for root:"
  until nixos-enter --root "$MOUNT" -- passwd root; do
    warn "Something went wrong — try again."
  done
  success "Root password set"

  echo
  info "Set a password for ${USERNAME}:"
  until nixos-enter --root "$MOUNT" -- passwd "$USERNAME"; do
    warn "Something went wrong — try again."
  done
  success "Password set for ${USERNAME}"

  # --- Clone config into home dir ------------------------------------------
  info "Cloning config into /home/${USERNAME}/NixConfig..."
  nixos-enter --root "$MOUNT" -- \
    su - "$USERNAME" -c "git clone $REPO_URL /home/$USERNAME/NixConfig"

  # -------------------------------------------------------------------------
  # Copy the freshly-generated hardware-configuration.nix into the home repo
  # and commit it.  Without this step the home repo still has the old UUIDs
  # from whatever machine the config was last committed from, which causes the
  # emergency-shell UUID mismatch bug on every fresh install.
  # -------------------------------------------------------------------------
  info "Syncing hardware-configuration.nix into ~/NixConfig..."
  cp "$TARGET/hardware-configuration.nix" \
     "$MOUNT/home/$USERNAME/NixConfig/hardware-configuration.nix"

  nixos-enter --root "$MOUNT" -- \
    su - "$USERNAME" -c "
      cd ~/NixConfig
      git config user.email '${USERNAME}@nixos'
      git config user.name  '${USERNAME}'
      git add hardware-configuration.nix
      git commit -m 'chore: update hardware-configuration.nix for this machine'
    "
  success "hardware-configuration.nix committed to ~/NixConfig"

  # --- Optional: import SSH keys from GitHub -------------------------------
  echo
  read -rp "  Import SSH keys from GitHub? Enter username (or press Enter to skip): " GH_USER
  if [[ -n "$GH_USER" ]]; then
    info "Fetching keys for GitHub user '${GH_USER}'..."
    SSH_DIR="$MOUNT/home/$USERNAME/.ssh"
    mkdir -p "$SSH_DIR"
    if curl -fsSL "https://github.com/${GH_USER}.keys" -o "$SSH_DIR/authorized_keys"; then
      chmod 700 "$SSH_DIR"
      chmod 600 "$SSH_DIR/authorized_keys"
      nixos-enter --root "$MOUNT" -- \
        chown -R "$USERNAME:users" "/home/$USERNAME/.ssh"
      success "SSH keys imported from github.com/${GH_USER}"
    else
      warn "Could not fetch keys — skipping. You can add them manually later."
    fi
  fi

fi

# =============================================================================
# SUMMARY
# =============================================================================
heading "Summary"

echo -e "  ${GREEN}${BOLD}Installation complete!${NC}"
echo
echo -e "  ${BOLD}Disk layout:${NC}"
if [[ "$DRY_RUN" == false ]]; then
  lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT "$DISK" | sed 's/^/    /'
fi
echo
echo -e "  ${BOLD}What to do after reboot:${NC}"
dim "1. Log in as ${USERNAME}"
dim "2. Your config is at ~/NixConfig"
dim "3. Edit and rebuild with:  nixos-rebuild switch --flake ~/NixConfig#${FLAKE_HOST}"
dim "4. hardware-configuration.nix is already committed — no UUID mismatch!"
echo

if [[ "$DRY_RUN" == true ]]; then
  warn "Dry-run complete — nothing was changed."
  exit 0
fi

echo -e "${GREEN}${BOLD}  Rebooting in 5 seconds...${NC}  (Ctrl-C to cancel)"
sleep 5
reboot
