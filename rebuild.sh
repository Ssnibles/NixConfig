#!/usr/bin/env bash
# =============================================================================
# Quick NixOS Rebuild Helper
# =============================================================================
# Usage:
#   ./rebuild.sh          -> Rebuilds NixOS (auto-stages files in NixConfig)
#   ./rebuild.sh --boot   -> Rebuilds NixOS for next boot instead of switch
#   ./rebuild.sh --test   -> Rebuilds NixOS for testing current session only
# =============================================================================
set -euo pipefail

NIXCONFIG_DIR="/home/josh/NixConfig"
HOST="${NIXOS_HOST:-$(hostname)}"
ACTION="switch"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

for arg in "$@"; do
  case "$arg" in
    --boot|-b)
      ACTION="boot"
      ;;
    --test|-t)
      ACTION="test"
      ;;
    --help|-h)
      echo "Usage: rebuild.sh [--boot|--test] [host]"
      echo "  --boot, -b    Set action to 'boot' instead of 'switch'"
      echo "  --test, -t    Set action to 'test' instead of 'switch'"
      exit 0
      ;;
    *)
      HOST="$arg"
      ;;
  esac
done

echo -e "${BLUE}${BOLD}==> Step 1: Staging changes in ${NIXCONFIG_DIR}...${NC}"
git -C "$NIXCONFIG_DIR" add -A

BUILD_CMD=("sudo" "nixos-rebuild" "$ACTION" "--flake" "${NIXCONFIG_DIR}#${HOST}")

echo -e "${BLUE}${BOLD}==> Step 2: Running nixos-rebuild ${ACTION} for host '${HOST}'...${NC}"
echo -e "${YELLOW}Executing: ${BUILD_CMD[*]}${NC}\n"

"${BUILD_CMD[@]}"

GEN=$(nixos-rebuild list-generations 2>/dev/null | awk 'NR==2 {print $1}')
echo -e "\n${GREEN}${BOLD}✔ NixOS Rebuild Completed Successfully! (Generation ${GEN:-unknown})${NC}"
