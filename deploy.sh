#!/usr/bin/env bash

# 1. Configuration variables
REPO_URL="https://github.com/Ssnibles/NixConfig.git"
TARGET_DIR="$HOME/NixConfig"

# 2. Clone the repo if it doesn't exist
if [ ! -d "$TARGET_DIR" ]; then
    echo "Cloning configuration..."
    git clone "$REPO_URL" "$TARGET_DIR"
fi

cd "$TARGET_DIR"

# 3. Handle hardware configuration
# If this is a brand new machine, generate the hardware file
if [ ! -f "./hardware-configuration.nix" ]; then
    echo "Generating hardware configuration..."
    sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
fi

# 4. Apply the configuration
# Replace 'nixos' with whatever hostname you define in flake.nix
echo "Deploying NixOS..."
sudo nixos-rebuild switch --flake .#nixos
