#!/usr/bin/env bash
# =============================================================================
# Quick NixOS Rebuild Helper
# =============================================================================
# Usage:
#   ./rebuild.sh          -> Rebuilds NixOS (auto-stages files in NixConfig)
#   ./rebuild.sh --dwl    -> Rebuilds NixOS overriding dwl with local ~/dwl
#   ./rebuild.sh --boot   -> Rebuilds NixOS for next boot instead of switch
#   ./rebuild.sh --test   -> Rebuilds NixOS for testing current session only
# =============================================================================
set -euo pipefail

NIXCONFIG_DIR="/home/josh/NixConfig"
DWL_DIR="/home/josh/dwl"
HOST="${NIXOS_HOST:-$(hostname)}"
ACTION="switch"
OVERRIDE_DWL=false

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

for arg in "$@"; do
  case "$arg" in
    --dwl|-d)
      OVERRIDE_DWL=true
      ;;
    --boot|-b)
      ACTION="boot"
      ;;
    --test|-t)
      ACTION="test"
      ;;
    --help|-h)
      echo "Usage: rebuild.sh [--dwl] [--boot|--test] [host]"
      echo "  --dwl, -d     Override dwl flake input with local ~/dwl source code"
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

if [[ "$OVERRIDE_DWL" == true ]]; then
  echo -e "${BLUE}${BOLD}==> Step 2: Including local DWL override (${DWL_DIR})...${NC}"
  BUILD_CMD+=("--override-input" "dwl" "$DWL_DIR")
fi

echo -e "${BLUE}${BOLD}==> Step 3: Running nixos-rebuild ${ACTION} for host '${HOST}'...${NC}"
echo -e "${YELLOW}Executing: ${BUILD_CMD[*]}${NC}\n"

"${BUILD_CMD[@]}"

GEN=$(nixos-rebuild list-generations 2>/dev/null | awk 'NR==2 {print $1}')
echo -e "\n${GREEN}${BOLD}✔ NixOS Rebuild Completed Successfully! (Generation ${GEN:-unknown})${NC}"

if [[ "$OVERRIDE_DWL" == true ]]; then
  echo -e "${YELLOW}--> DWL local build was applied! To see changes in your current session:${NC}"
  echo -e "${YELLOW}    Exit your current DWL session and log back in (or restart the compositor).${NC}"
fi
