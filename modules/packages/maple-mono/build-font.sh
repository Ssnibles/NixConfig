#!/usr/bin/env bash
# =============================================================================
# Maple Mono Custom Font Builder
# =============================================================================
# Builds Maple Mono fonts using options from config.json.
# Requirements: git, uv, nix
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$(mktemp -d /tmp/maple-build-XXXXXX)"

cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

echo "==> Cloning Maple-font repository..."
git clone --depth 1 https://github.com/subframe7536/maple-font "$WORK_DIR/maple-font"

echo "==> Copying config.json..."
cp "$SCRIPT_DIR/config.json" "$WORK_DIR/maple-font/config.json"

echo "==> Setting up python virtualenv..."
PYTHON_BIN="$(nix build nixpkgs#python312 --no-link --print-out-paths)/bin/python3.12"
uv venv --python "$PYTHON_BIN" "$WORK_DIR/venv"
uv pip install -r "$WORK_DIR/maple-font/requirements.txt" --python "$WORK_DIR/venv/bin/python"

echo "==> Symlinking native ttfautohint..."
TTFAUTOHINT_BIN="$(nix build nixpkgs#ttfautohint --no-link --print-out-paths)/bin/ttfautohint"
ln -sf "$TTFAUTOHINT_BIN" "$WORK_DIR/venv/lib/python3.12/site-packages/ttfautohint/ttfautohint"

echo "==> Building fonts..."
CC_LIB="$(nix eval --raw nixpkgs#stdenv.cc.cc.lib)/lib"
export PATH="$WORK_DIR/venv/bin:$PATH"
export LD_LIBRARY_PATH="${CC_LIB}:${LD_LIBRARY_PATH:-}"

python "$WORK_DIR/maple-font/build.py" --ttf-only

echo "==> Copying built fonts to $SCRIPT_DIR/fonts..."
mkdir -p "$SCRIPT_DIR/fonts"
cp "$WORK_DIR/maple-font/fonts/NF"/*.ttf "$SCRIPT_DIR/fonts/"
cp "$WORK_DIR/maple-font/fonts/TTF-AutoHint"/*.ttf "$SCRIPT_DIR/fonts/"

echo "==> Successfully built and copied custom Maple Mono fonts!"
