# 🌟 NixOS Configuration

> Professional multi-host NixOS configuration with Hyprland, Neovim, and declarative system management.

[![NixOS](https://img.shields.io/badge/NixOS-25.11-blue.svg?logo=nixos&logoColor=white)](https://nixos.org)
[![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-5e81ac.svg)](https://hyprland.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 📋 Table of Contents

- [Features](#-features)
- [System Architecture](#-system-architecture)
- [Quick Start](#-quick-start)
  - [Fresh Installation](#fresh-installation)
  - [Rebuilding](#rebuilding)
  - [Testing Changes](#testing-changes)
- [Structure](#-structure)
- [Host Configurations](#-host-configurations)
- [Keybindings](#-keybindings)
- [Customization](#-customization)
- [Secrets Management](#-secrets-management)
- [Troubleshooting](#-troubleshooting)
- [Tips & Tricks](#-tips--tricks)

---

## ✨ Features

### **System-Level**
- 🔹 **Dual-channel Nixpkgs**: Stable system base + unstable user packages
- 🔹 **Multi-host support**: Desktop (NVIDIA) + Laptop (TLP) from single codebase
- 🔹 **Declarative everything**: Disk partitioning (Disko), secrets (Agenix), users (Home Manager)
- 🔹 **Wayland-first**: Hyprland compositor with XDG portal screen sharing
- 🔹 **Security**: DNS-over-TLS, firewall, kernel hardening
- 🔹 **Performance**: zram swap, SSD TRIM, low-latency audio (PipeWire ~21ms)

### **Developer Experience**
- 🔹 **Neovim IDE**: 40+ plugins, LSP for 8+ languages, tree-sitter, GitHub Copilot
- 🔹 **Fish Shell**: Modern shell with abbreviations, syntax highlighting, Pure prompt
- 🔹 **Tmux**: Terminal multiplexer with TPM plugin management
- 🔹 **Git Workflow**: LazyGit, Neogit, GitSigns integration
- 🔹 **Fast Rebuilds**: `nh` helper with automatic garbage collection

### **Desktop Environment**
- 🔹 **Hyprland**: Dynamic tiling Wayland compositor
- 🔹 **Waybar**: Customizable status bar
- 🔹 **SwayNC**: Notification center
- 🔹 **Zen Browser**: Privacy-focused Firefox fork
- 🔹 **Consistent Theming**: Vague colorscheme across Neovim, terminals, Fish

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         flake.nix                               │
│  (Inputs: nixpkgs 25.11, home-manager, disko, agenix, etc.)   │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │   lib/mkHost.nix     │
              │  (Host Builder Fn)   │
              └──────────┬───────────┘
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
  ┌──────────┐   ┌──────────┐   ┌──────────┐
  │ Desktop  │   │  Laptop  │   │  *-test  │
  │ (NVIDIA) │   │  (TLP)   │   │ (No Disko)│
  └────┬─────┘   └────┬─────┘   └────┬─────┘
       │              │              │
       ▼              ▼              ▼
  ┌────────────────────────────────────────┐
  │      modules/nixos/common.nix          │
  │  (Boot, Network, Audio, Services...)  │
  └────────────────────────────────────────┘
       │              │              │
       ▼              ▼              ▼
  ┌────────────────────────────────────────┐
  │       hosts/<name>/default.nix         │
  │    (Host-specific overrides)          │
  └────────────────────────────────────────┘
       │              │              │
       ▼              ▼              ▼
  ┌────────────────────────────────────────┐
  │         Home Manager Integration       │
  │  modules/home/* (Shell, Desktop, Nvim) │
  └────────────────────────────────────────┘
```

**Key Concepts:**
- **mkHost** abstracts away boilerplate (overlays, modules, Home Manager)
- **hostProfile** flags (`hasNvidia`, `isLaptop`) enable conditional configuration
- **Dual nixpkgs**: `stable` for system, `unstable` overlay for user packages
- **Test configs**: Rebuild safely without Disko repartitioning

---

## 🚀 Quick Start

### Fresh Installation

1. **Boot NixOS minimal ISO** (25.11 or later)
2. **Connect to WiFi** (if needed):
   ```bash
   sudo systemctl start wpa_supplicant
   wpa_cli
   # ... configure WiFi ...
   ```
3. **Run installer**:
   ```bash
   # For desktop (will format /dev/nvme0n1):
   sudo bash <(curl -L https://raw.githubusercontent.com/yourusername/NixConfig/main/install.sh) \
     --host desktop --disk /dev/nvme0n1

   # For laptop:
   sudo bash <(curl -L https://raw.githubusercontent.com/yourusername/NixConfig/main/install.sh) \
     --host laptop --disk /dev/nvme0n1
   ```
4. **Reboot** and log in with Ly display manager

### Rebuilding

After making changes to your configuration:

```bash
# Quick rebuild (recommended)
rebuild

# Manual (equivalent to above fish abbreviation)
git -C ~/NixConfig add -u
sudo nixos-rebuild switch --flake ~/NixConfig#desktop
```

### Testing Changes

Use the test configuration to rebuild without Disko (safe, no repartitioning):

```bash
sudo nixos-rebuild switch --flake ~/NixConfig#desktop-test
# or
sudo nixos-rebuild switch --flake ~/NixConfig#laptop-test
```

---

## 📁 Structure

```
NixConfig/
├── flake.nix                    # Flake inputs/outputs, host definitions
├── flake.lock                   # Dependency lock file (auto-generated)
├── secrets.nix                  # Agenix public key declarations
├── install.sh                   # Bootstrap script for fresh installs
│
├── lib/
│   └── mkHost.nix               # Host builder abstraction
│
├── disko/
│   ├── desktop.nix              # Disk layout for desktop (NVMe, no swap)
│   └── laptop.nix               # Disk layout for laptop (NVMe + zram)
│
├── hosts/
│   ├── desktop/
│   │   ├── default.nix          # Desktop-specific config (NVIDIA, performance)
│   │   └── hardware-configuration.nix
│   └── laptop/
│       ├── default.nix          # Laptop-specific config (TLP, WiFi, lid)
│       └── hardware-configuration.nix
│
├── modules/
│   ├── nixos/                   # System-level NixOS modules
│   │   ├── common.nix           # Shared config (all hosts)
│   │   └── hardware/
│   │       └── nvidia.nix       # NVIDIA driver configuration
│   └── home/                    # Home Manager modules (user-level)
│       ├── desktop/
│       │   ├── hyprland.nix     # Compositor, keybindings, autostart
│       │   ├── waybar.nix       # Status bar config
│       │   └── swaync.nix       # Notification daemon
│       ├── shell/
│       │   ├── fish.nix         # Shell config, abbrs, prompt
│       │   └── tmux.nix         # Terminal multiplexer
│       ├── git.nix              # Git identity & settings
│       ├── neovim.nix           # Neovim plugins & LSP tools (Nix)
│       ├── packages.nix         # User package list
│       ├── programs.nix         # Configured programs (spotify-player, etc.)
│       └── scripts.nix          # Custom shell scripts
│
├── users/
│   └── josh/
│       └── default.nix          # Home Manager entry point
│
├── nvim/                        # Neovim Lua configuration
│   ├── init.lua                 # Entry point
│   └── lua/
│       ├── options.lua          # Editor settings
│       ├── keymaps.lua          # Key bindings
│       ├── autocommands.lua     # Event-based logic
│       ├── lib/                 # Helper functions (health, highlights)
│       └── plugins/             # Plugin configurations
│           ├── lsp.lua          # LSP client setup
│           ├── completion.lua   # blink.cmp, copilot, snippets
│           ├── fzf.lua          # Fuzzy finder
│           ├── conform.lua      # Autoformatting
│           ├── treesitter.lua   # Syntax highlighting
│           ├── ui.lua           # UI plugins (gitsigns, oil, noice)
│           └── ...
│
└── wallpapers/                  # Wallpaper assets for awww
```

---

## 🖥️ Host Configurations

| Host | Hardware | Disko | Power | Special Features |
|------|----------|-------|-------|------------------|
| **desktop** | AMD CPU + NVIDIA GPU | ✅ | Performance governor | Gamemode, Ollama LLM |
| **desktop-test** | AMD CPU + NVIDIA GPU | ❌ | Performance governor | Safe rebuild testing |
| **laptop** | AMD CPU + iGPU | ✅ | TLP (battery 40-85%) | WiFi tweaks, lid handling |
| **laptop-test** | AMD CPU + iGPU | ❌ | TLP | Safe rebuild testing |

### Desktop-Specific Features
- NVIDIA proprietary drivers (stable kernel)
- USB autosuspend disabled (prevents keyboard/mouse wake issues)
- NVMe read-ahead: 2048KB (optimized for large sequential reads)
- Ollama service for local LLM inference

### Laptop-Specific Features
- TLP power management (CPU boost on AC only)
- Battery charge thresholds (40-85% for longevity)
- Realtek WiFi driver optimizations (RTW89)
- Lid switch: suspend (unless docked)
- wlsunset blue-light filter
- Brightnessctl for screen brightness

---

## ⌨️ Keybindings

### Neovim (Leader: `Space`)

#### General
| Key | Mode | Action |
|-----|------|--------|
| `jk` | Insert | Exit insert mode |
| `U` | Normal | Redo |
| `Esc` | Normal | Clear search highlight |

#### Navigation
| Key | Mode | Action |
|-----|------|--------|
| `Ctrl-d` / `Ctrl-u` | Normal | Scroll down/up (centered) |
| `n` / `N` | Normal | Next/prev search match (centered) |
| `]d` / `[d` | Normal | Next/prev diagnostic |
| `]e` / `[e` | Normal | Next/prev error |

#### Window Management
| Key | Mode | Action |
|-----|------|--------|
| `<leader>wv` | Normal | Vertical split |
| `<leader>wh` | Normal | Horizontal split |
| `<leader>wx` | Normal | Close window |
| `Ctrl-h/j/k/l` | Normal | Navigate windows (Tmux-aware) |

#### LSP
| Key | Mode | Action |
|-----|------|--------|
| `gd` | Normal | Go to definition |
| `gr` | Normal | References |
| `K` | Normal | Hover documentation |
| `<leader>ca` | Normal/Visual | Code action |
| `<leader>cr` | Normal | Rename symbol |
| `<leader>cf` | Normal/Visual | Format |

#### Fuzzy Finding (fzf-lua)
| Key | Mode | Action |
|-----|------|--------|
| `<leader>ff` | Normal | Find files |
| `<leader>fg` | Normal | Live grep |
| `<leader>fb` | Normal | Buffers |
| `<leader>fh` | Normal | Help tags |
| `<leader>fr` | Normal | Recent files |

#### Git
| Key | Mode | Action |
|-----|------|--------|
| `<leader>gg` | Normal | Neogit status |
| `<leader>gb` | Normal | Blame line |
| `<leader>gd` | Normal | Diff this |

#### File Explorer (Oil)
| Key | Mode | Action |
|-----|------|--------|
| `-` | Normal | Open parent directory |
| `<leader>o` | Normal | Open Oil |

#### Toggles
| Key | Mode | Action |
|-----|------|--------|
| `<leader>tw` | Normal | Toggle line wrap |
| `<leader>ts` | Normal | Toggle spell check |
| `<leader>th` | Normal | Toggle LSP inlay hints |
| `<leader>tc` | Normal | Toggle cursor word highlight |

### Hyprland (Leader: `Super/Win`)

| Key | Action |
|-----|--------|
| `Super + Enter` | Terminal (Ghostty) |
| `Super + Q` | Close window |
| `Super + M` | Exit Hyprland |
| `Super + Space` | Vicinae launcher |
| `Super + H/J/K/L` | Focus window (vim keys) |
| `Super + Shift + H/J/K/L` | Move window |
| `Super + 1-9` | Switch workspace |
| `Super + Shift + 1-9` | Move to workspace |
| `Super + F` | Toggle fullscreen |
| `Super + V` | Toggle floating |

### Fish Shell Abbreviations

| Abbr | Expands To | Description |
|------|------------|-------------|
| `v` | `nvim` | Open Neovim |
| `rebuild` | `git -C ~/NixConfig add -u && nh os switch` | Rebuild system |
| `clean` | `nh clean all` | Garbage collect old generations |

---

## 🎨 Customization

### Adding a New Host

1. **Create host directory**:
   ```bash
   mkdir -p hosts/newhost
   cp hosts/desktop/hardware-configuration.nix hosts/newhost/
   ```

2. **Create host config** (`hosts/newhost/default.nix`):
   ```nix
   { config, pkgs, lib, hostProfile, ... }:
   {
     imports = [ ./hardware-configuration.nix ];
     
     # Host-specific settings here
     powerManagement.cpuFreqGovernor = "performance";
   }
   ```

3. **Add to flake.nix**:
   ```nix
   nixosConfigurations.newhost = mkHost {
     hostName = "newhost";
     # ... flags ...
   };
   ```

4. **Create Disko layout** (if useDisko = true):
   ```bash
   cp disko/desktop.nix disko/newhost.nix
   # Edit partition layout as needed
   ```

### Adding a New User

1. **Create user directory**:
   ```bash
   mkdir -p users/newuser
   ```

2. **Create home.nix** (`users/newuser/default.nix`):
   ```nix
   { config, pkgs, ... }:
   {
     home = {
       username = "newuser";
       homeDirectory = "/home/newuser";
       stateVersion = "24.11";
     };

     # Import shared modules
     imports = [
       ../../modules/home/shell/fish.nix
       ../../modules/home/neovim.nix
       # ... more modules ...
     ];
   }
   ```

3. **Add user to system config** (`modules/nixos/common.nix`):
   ```nix
   users.users.newuser = {
     isNormalUser = true;
     shell = pkgs.fish;
     extraGroups = [ "wheel" "networkmanager" ];
   };
   ```

4. **Update mkHost** to use the new user (or keep as parameter).

### Customizing Neovim Plugins

Add plugins to `modules/home/neovim.nix`:

```nix
plugins = with pkgs.vimPlugins; [
  # ... existing plugins ...
  my-new-plugin
];
```

Configure in `nvim/lua/plugins/my-plugin.lua`:

```lua
-- Plugin setup
require("my-plugin").setup({
  -- options here
})
```

---

## 🔐 Secrets Management

This configuration uses **Agenix** for encrypted secrets (SSH keys, API tokens, etc.).

### Initial Setup

1. **Generate age key**:
   ```bash
   mkdir -p ~/.config/agenix
   age-keygen -o ~/.config/agenix/key.txt
   # Note the public key (age1...)
   ```

2. **Add public key to `secrets.nix`**:
   ```nix
   let
     josh-desktop = "age1...";
   in {
     "secrets/spotify-id.age".publicKeys = [ josh-desktop ];
   }
   ```

3. **Encrypt a secret**:
   ```bash
   # Create plaintext file
   echo "my-secret-value" > /tmp/my-secret.txt
   
   # Encrypt with age
   age -r <public-key> -o secrets/my-secret.age /tmp/my-secret.txt
   
   # Securely delete plaintext
   shred -u /tmp/my-secret.txt
   ```

4. **Use in configuration**:
   ```nix
   age.secrets.spotify-id = {
     file = ../secrets/spotify-id.age;
     owner = "josh";
   };
   
   # Access at: /run/agenix/spotify-id
   ```

---

## 🔧 Troubleshooting

### Boot Issues

**Problem**: System won't boot after rebuild

**Solution**:
1. Reboot and select previous generation from GRUB/systemd-boot
2. Check journal: `journalctl -xb`
3. Rebuild with test config: `sudo nixos-rebuild switch --flake .#desktop-test`

### NVIDIA Black Screen

**Problem**: Black screen after NVIDIA driver update

**Solution**:
1. Boot to previous generation
2. Pin NVIDIA driver version in `modules/nixos/hardware/nvidia.nix`:
   ```nix
   package = pkgs.linuxPackages.nvidiaPackages.legacy_535;
   ```

### WiFi Disconnects

**Problem**: Random WiFi disconnections on laptop

**Solution**:
1. Disable WiFi power saving (already done in `common.nix`)
2. Check driver: `sudo dmesg | grep rtw89`
3. If still problematic, switch to wpa_supplicant backend:
   ```nix
   networking.networkmanager.wifi.backend = "wpa_supplicant";
   ```

### Neovim LSP Not Starting

**Problem**: LSP server fails to attach

**Solution**:
1. Check LSP status: `:LspInfo`
2. Verify tool is installed: `which nixd`
3. Check logs: `:lua vim.cmd('e ' .. vim.lsp.get_log_path())`
4. Restart LSP: `:LspRestart`

### Slow Rebuilds

**Problem**: `nixos-rebuild` takes too long

**Solution**:
1. Use `nh` instead: `nh os switch`
2. Enable binary cache (already configured)
3. Check cache hits: `nix store ping --store https://cache.nixos.org`
4. Clear old generations: `nh clean all`

---

## 💡 Tips & Tricks

### Development Workflow

**Quick iteration on Neovim config**:
```bash
# Edit Lua files
nvim ~/NixConfig/nvim/lua/options.lua

# Changes apply immediately (no rebuild needed)
# Reload with :luafile %
```

**Testing Nix changes without rebuild**:
```bash
# Evaluate configuration (syntax check)
nix eval .#nixosConfigurations.desktop.config.system.build.toplevel

# Build without switching
nixos-rebuild build --flake .#desktop
```

### Performance Optimization

**Check Neovim startup time**:
```bash
nvim --startuptime startup.log +q
# or from within Neovim:
<leader>cl  # Plugin load times
```

**Check system boot time**:
```bash
systemd-analyze  # Total boot time
systemd-analyze blame  # Per-service breakdown
```

### Useful Commands

```bash
# List all NixOS generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Roll back to previous generation
sudo nixos-rebuild switch --rollback

# Update flake inputs
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs-unstable

# Diff configurations
nix-diff \
  /run/current-system \
  $(nix build --no-link --print-out-paths .#nixosConfigurations.desktop.config.system.build.toplevel)

# Search for package
nix search nixpkgs <package-name>

# Check binary cache coverage
nix path-info --store https://cache.nixos.org --all --json | jq '.[] | .path'
```

### Tmux Setup

TPM (Tmux Plugin Manager) is not managed by Nix. Bootstrap once:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Then inside tmux: `<prefix> + I` to install plugins.

---

## 📚 Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Hyprland Wiki](https://wiki.hyprland.org/)
- [Neovim Documentation](https://neovim.io/doc/)
- [Agenix Documentation](https://github.com/ryantm/agenix)

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

---

**Made with ❤️ using NixOS**
