#!/usr/bin/env bash
# =============================================================================
# NixOS Bootstrap Installer - Disko Edition
# =============================================================================
# Automated installation script for fresh NixOS deployments.
# Handles partitioning, configuration cloning, and system installation.
#
# Usage:
#   sudo bash install.sh --host <desktop|laptop> [--disk /dev/sdX] [--dry-run]
#
# Prerequisites:
#   - Booted from NixOS Minimal ISO
#   - Internet connection established
#   - Target disk identified
#
# Safety Features:
#   - Dry-run mode to test without changes
#   - Confirmation prompt before disk wipe
#   - Cleanup trap on failure
#   - Test configurations available (desktop-test, laptop-test)
# =============================================================================
set -euo pipefail
REPO_URL="https://github.com/Ssnibles/NixConfig.git"
MOUNT="/mnt"
USERNAME="josh"

# ── Colours ───────────────────────────────────────────────────────────────
# ANSI colour codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Output functions for consistent formatting
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

# ── Cleanup trap ──────────────────────────────────────────────────────────
# Unmount filesystems on failure to prevent locked mounts
cleanup() {
  local code=$?
  if [[ $code -ne 0 && "$DRY_RUN" == false ]]; then
    warn "Install failed (exit $code) — cleaning up mounts..."
    umount -R "$MOUNT" 2>/dev/null || true
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
heading "[ 1 / 6 ]  Network"
ping -c1 -W3 1.1.1.1 &>/dev/null || {
  warn "No internet connection. Connect first, then re-run."
  echo "  nmtui   — text UI (easiest)"
  exit 1
}
success "Network OK"

# =============================================================================
# 2 · DISK SELECTION
# =============================================================================
heading "[ 2 / 6 ]  Disk"
if [[ -z "$DISK" ]]; then
  echo "  Available block devices:"
  lsblk -d -o NAME,SIZE,MODEL --noheadings | grep -v loop \
    | awk '{printf "    /dev/%-12s %6s  %s\n", $1, $2, $3}'
  echo
  read -rp "  Enter disk (e.g. /dev/sda or /dev/nvme0n1): " DISK
fi
[[ -b "$DISK" ]] || die "Disk '$DISK' not found."
echo
warn "This will ERASE all data on ${DISK}!"
if [[ "$DRY_RUN" == false ]]; then
  read -rp "  Type 'yes' to continue: " CONFIRM
  [[ "$CONFIRM" == "yes" ]] || { info "Aborted."; exit 0; }
fi

# =============================================================================
# 3 · CLONE CONFIG
# =============================================================================
heading "[ 3 / 6 ]  Cloning NixOS config"
TARGET="$MOUNT/etc/nixos"
if [[ "$DRY_RUN" == false ]]; then
  if [[ -d "$TARGET/.git" ]]; then
    warn "Repo already present — pulling latest..."
    git -C "$TARGET" pull
  else
    info "Cloning $REPO_URL → $TARGET"
    git clone "$REPO_URL" "$TARGET"
  fi
  success "Config cloned"
fi

# =============================================================================
# 4 · DISKO PARTITIONING
# =============================================================================
heading "[ 4 / 6 ]  Disk Partitioning (Disko)"
if [[ "$DRY_RUN" == false ]]; then
  # Extract disko revision from flake.lock for reproducible partitioning
  DISKO_REV=$(jq -r '.nodes.root.inputs.disko' "$TARGET/flake.lock" 2>/dev/null | \
    xargs -I{} jq -r ".nodes.\"{}\".locked.rev" "$TARGET/flake.lock" 2>/dev/null || \
    echo "latest")
  info "Using disko revision: $DISKO_REV"
  info "Target device: $DISK"

  # Run disko to partition and format the disk
  nix --extra-experimental-features "nix-command flakes" run \
    "github:nix-community/disko/$DISKO_REV" -- --mode disko \
    --argstr diskDevice "$DISK" \
    "$TARGET#${HOST}"
  success "Disk partitioned and formatted"
fi

# =============================================================================
# 5 · INSTALL
# =============================================================================
heading "[ 5 / 6 ]  Installing NixOS"
if [[ "$DRY_RUN" == true ]]; then
  info "Dry-run: would run nixos-install --flake ${TARGET}#${HOST}"
else
  info "Running nixos-install (this will take a while)..."
  nixos-install --flake "${TARGET}#${HOST}" --no-root-passwd
  success "NixOS installed"
fi

# =============================================================================
# 6 · POST-INSTALL
# =============================================================================
heading "[ 6 / 6 ]  Post-install setup"
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
    su - "$USERNAME" -c "git clone $REPO_URL /home/$USERNAME/NixConfig"

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
echo -e "  ${DIM}2. Config is at ~/NixConfig${NC}"
echo -e "  ${DIM}3. Rebuild: nixos-rebuild switch --flake ~/NixConfig#${HOST}${NC}"
echo
[[ "$DRY_RUN" == true ]] && { warn "Dry-run complete — nothing was changed."; exit 0; }
echo -e "${GREEN}${BOLD}  Rebooting in 5 seconds...${NC}  (Ctrl-C to cancel)"
sleep 5
reboot
