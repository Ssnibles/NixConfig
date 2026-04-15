# Module reference

## NixOS modules

| Path | Responsibility |
|---|---|
| `modules/nixos/common.nix` | Core shared system config: boot, networking, firewall, DNS, audio, users, base packages, Nix settings |
| `modules/nixos/hardware/nvidia.nix` | NVIDIA-specific kernel/driver/Wayland settings when `hasNvidia = true` |

## Home Manager entry

| Path | Responsibility |
|---|---|
| `users/josh/default.nix` | Imports all HM modules and sets base user/session values |

## Home modules

| Path | Responsibility |
|---|---|
| `modules/home/packages.nix` | User package set (including host-conditional desktop/laptop packages) |
| `modules/home/programs.nix` | spotify-player, direnv, pet snippets/config |
| `modules/home/stylix.nix` | Stylix theme base + target selection for supported applications, plus disabled example for unsupported app theming |
| `modules/home/scripts.nix` | custom scripts (`toggle-float`, `toggle-focus-mode`, `stylix-switch`, `aicommit`, `setup-fo-prism`, etc.) |
| `modules/home/git.nix` | Git identity + delta config |
| `modules/home/neovim.nix` | Neovim plugins, LSP tools, formatters, runtime config source |
| `modules/home/qutebrowser.nix` | Declarative qutebrowser settings, keybinds, search engines, and theme |
| `modules/home/shell/fish.nix` | Fish config, abbreviations, plugins, Ghostty/Foot config |
| `modules/home/shell/tmux.nix` | tmux behavior/theme/plugins |
| `modules/home/shell/zellij.nix` | zellij config and keybinds |
| `modules/home/desktop/hyprland.nix` | Hyprland config, keybinds, startup apps, Vicinae theme |
| `modules/home/desktop/hyprlock.nix` | Hyprlock visual/behavior settings |
| `modules/home/desktop/waybar.nix` | Waybar modules and style |
| `modules/home/desktop/swaync.nix` | SwayNC settings and style |
| `modules/home/services/wayland.nix` | User systemd services for `awww` and `vicinae` |

## Secrets wiring

- Rule definitions: `secrets.nix`
- Encrypted payload files: `secrets/*.age`
- Runtime mount points from NixOS module:
  - `/run/agenix/spotify-id`
  - `/run/agenix/spotify-secret`
