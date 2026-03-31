# NixOS Configuration

Multi-host NixOS configuration with Home Manager, Hyprland, and Neovim.

## Structure

```
NixConfig/
├── flake.nix                      # Inputs, overlays, host builder
├── secrets.nix                    # Agenix public-key declarations
├── disko/
│   ├── desktop.nix                # Disk layout – desktop
│   └── laptop.nix                 # Disk layout – laptop (with swap)
├── hosts/
│   ├── desktop/
│   │   ├── configuration.nix      # Desktop-specific overrides
│   │   └── hardware-configuration.nix
│   └── laptop/
│       ├── configuration.nix      # Laptop-specific overrides (TLP, lid, WiFi)
│       └── hardware-configuration.nix
├── modules/
│   ├── nixos/                     # System-level NixOS modules
│   │   ├── common.nix             # Shared config (boot, network, audio, users…)
│   │   └── hardware/
│   │       └── nvidia.nix         # Proprietary NVIDIA drivers (hasNvidia = true)
│   └── home/                      # Home Manager modules
│       ├── desktop/
│       │   ├── hyprland.nix       # Compositor, keybindings, Vicinae launcher
│       │   ├── waybar.nix         # Status bar
│       │   └── swaync.nix         # Notification daemon
│       ├── shell/
│       │   ├── fish.nix           # Fish shell, plugins, Ghostty & Foot theming
│       │   └── tmux.nix           # Terminal multiplexer
│       ├── git.nix                # Git identity & settings
│       ├── neovim.nix             # Neovim plugins & LSP tools
│       ├── packages.nix           # User package list (host-conditional)
│       ├── programs.nix           # Configured programs (spotify-player, java)
│       └── scripts.nix            # Custom shell scripts
├── users/
│   └── josh/
│       └── home.nix               # Home Manager entry point
├── nvim/                          # Lua Neovim config (sourced by neovim.nix)
└── wallpapers/
```

## Hosts

| Name | Disko | NVIDIA | Power |
|------|-------|--------|-------|
| `desktop` | ✓ | ✓ | performance governor |
| `desktop-test` | ✗ | ✓ | performance governor |
| `laptop` | ✓ | ✗ | TLP |
| `laptop-test` | ✗ | ✗ | TLP |

## Quick Start

### Fresh install

```bash
# Boot NixOS minimal ISO, connect to WiFi, then:
sudo bash install.sh --host desktop --disk /dev/nvme0n1
# or for laptop:
sudo bash install.sh --host laptop  --disk /dev/nvme0n1
```

### Rebuild (after boot)

```bash
# The 'rebuild' shell abbreviation does this automatically:
git -C ~/NixConfig add -u
sudo nixos-rebuild switch --flake ~/NixConfig#desktop
```

### Test rebuild (no Disko, safe)

```bash
sudo nixos-rebuild switch --flake ~/NixConfig#desktop-test
```

## Tmux (TPM bootstrap)

TPM is not managed by Nix – clone it once after first boot:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Then press `prefix + I` inside tmux to install plugins.

## Secrets (Agenix)

1. Generate an age key: `age-keygen -o ~/.config/agenix/key.txt`
2. Copy the public key from stdout into `secrets.nix`
3. Encrypt: `age -r <public-key> -o secrets/spotify-id.age secrets/spotify-id.txt`
