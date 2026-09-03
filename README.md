# NixConfig

A modern, [dendritic](https://github.com/mightyiam/dendritic) NixOS flake configuration for `desktop` and `laptop` machines. It uses `flake-parts` + `import-tree`, allowing the directory tree under `modules/` to act as the module tree — every `.nix` file is automatically discovered and exported as a flake output without requiring manual import lists.

The configuration pins `nixos-26.05` (stable) for system base components and integrates `nixos-unstable` for select bleeding-edge packages (including Fish 4+, Starship, Neovim, and custom desktop tools).

---

## Table of Contents

- [Features](#features)
- [Wiki & Feature Guides](#-wiki--feature-guides)
- [Architecture & Module Organization](#architecture--module-organization)
- [Project Directory Structure](#project-directory-structure)
- [Hosts Comparison](#hosts-comparison)
- [Installation](#installation)
  - [1. Boot NixOS Minimal ISO](#1-boot-nixos-minimal-iso)
  - [2. Automated Install Script (`install.sh`)](#2-automated-install-script-installsh)
  - [3. Manual Installation](#3-manual-installation)
- [Post-Install & Daily Workflow](#post-install--daily-workflow)
  - [Rebuild Script (`build.sh`)](#rebuild-script-buildsh)
  - [Fish Abbreviations & Custom Functions](#fish-abbreviations--custom-functions)
- [Development Shell](#development-shell--flake-templates)
- [Module Scaffolding (`boilerplate`)](#module-scaffolding-boilerplate)
- [Theme & Wallpaper Customization](#theme--wallpaper-customization)
- [Nix & NixOS Learning Resources](#nix--nixos-learning-resources)
- [Troubleshooting](#troubleshooting)

---

## 📚 Wiki & Feature Guides

In-depth documentation, architecture references, and workflow guides for specific sub-systems and developer toolchains are available in the **[NixConfig Wiki](docs/wiki/index.md)**:

| Feature / Subsystem          | Guide Link                                     | Description                                                                                                                       |
| :--------------------------- | :--------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------- |
| **ESP32 & Arduino**          | [esp32-arduino.md](docs/wiki/esp32-arduino.md) | ESP32 microcontroller dev, `arduino-cli`, `esptool`, `esp-init`/`esp-compile`/`esp-upload` workflow scripts, and Neovim LSP setup |
| **Quickshell UI**            | [quickshell.md](docs/wiki/quickshell.md)       | Quickshell QML framework, status bars, Command Center dashboard, Lock Screen, and IPC commands                                    |
| **Firefox & Sidebery**       | [firefox.md](docs/wiki/firefox.md)             | `userChrome.css` native styling, `userContent.css` Sidebery customization, and Browser Toolbox debugging                          |
| **AMD Vivado FPGA**          | [vivado-fpga.md](docs/wiki/vivado-fpga.md)     | Distrobox Ubuntu 22.04 container setup, GUI/X11 forwarding, and desktop launch wrapper                                            |
| **Declarative Neovim**       | [neovim.md](docs/wiki/neovim.md)               | `nvf` Neovim setup, custom Lua plugins, `:GenerateCompileFlags` Nix include parser, and LSP hints                                 |
| **Wayland Compositors**      | [compositors.md](docs/wiki/compositors.md)     | Hyprland, Niri (scrollable tiling), and MangoWC (DWM-style minimal compositor)                                                    |
| **Gaming & PS5 Controllers** | [gaming.md](docs/wiki/gaming.md)               | Steam with Millennium skinning, Gamescope, MangoHud, and DualSense PS5 controller kernel drivers                                  |

---

## Features

### System & Core Architecture

- **Dendritic Architecture**: Built on `flake-parts` and `import-tree`. Filesystem placement determines module registration automatically.
- **Dual-Channel Nixpkgs**: Stable `nixos-26.05` base with an integrated `nixos-unstable` overlay for cutting-edge packages.
- **Declarative User Environment**: Managed via [hjem](https://github.com/feel-co/hjem) instead of Home Manager for clean, lightweight dotfile management.
- **Bootloader**: Modern [Limine](https://limine-bootloader.org/) bootloader configured on all hosts with EFI support.
- **Display Manager**: Lightweight TTY-based [Ly](https://github.com/fairyglade/ly) display manager on all hosts.
- **Audio & Networking**: Low-latency PipeWire + WirePlumber setup with systemd-resolved DNS-over-TLS (Cloudflare 1.1.1.1 + Google fallback) and NetworkManager + iwd.
- **System Maintenance**: `nh` tool for fast nixos-rebuild execution and automated garbage collection (`nh clean all`).

### Desktop, Compositors & Shell

- **Compositors**:
  - **Hyprland**: Modern Wayland dynamic tiling compositor.
  - **Niri**: Scrollable-tiling Wayland compositor.
  - **MangoWC**: DWM-inspired Wayland compositor.
- **Unified Shell Bar**: Quickshell QML framework supplying unified status bar widgets, notifications, and menus across compositors.
- **Application Launcher**: Vicinae launcher running as a systemd user service with customized theme palette integration.
- **Clipboard Management**: Wayland session clipboard persistence via `wl-clip-persist` and text/image clipboard history powered by `cliphist`.
- **Gaming & Hardware**: Steam with Millennium skinning framework, Gamescope session support, MangoHud overlay, and Sony PlayStation 5 (DualSense / DualSense Edge) controller kernel driver (`hid-playstation`) & udev rule support.

### Shell & Command-Line Workflow

- **Interactive Shells**: Unstable Fish 4+ (`pkgs.unstable.fish`) as the primary user shell, alongside Zsh with `oh-my-zsh`.
- **Prompt**: Unstable Starship (`pkgs.unstable.starship`) with custom transient prompt execution (`>>`).
- **Terminal Utilities**: `zoxide` (smart cd), `direnv` with `nix-direnv`, `bat` (cat substitute), `btop`, `fd`, `ripgrep`, `chafa` (terminal image viewing with Sixel support), `croc` file transfer, and `nix-index` for command-not-found suggestion.
- **Terminal Multiplexer**: Customized `tmux` setup featuring interactive FZF session/window picker and pane path truncation.

### Development Environment

- **Neovim**: Configured declaratively via [nvf](https://github.com/NotAShelf/nvf) with custom Lua plugins under `modules/features/nvim-src/`.
- **ESP32 & Microcontroller Dev**: ESP32 Arduino framework integration with `arduino-cli`, `esptool`, and auto-generated `compile_commands.json` for Neovim / Clangd LSP autocompletion (`esp32-arduino` template).
- **FPGA & Embedded Tools**: AMD Vivado Design Suite 2024.1 running in an isolated Distrobox Ubuntu 22.04 container with X11/GUI passthrough and custom launcher scripts (`assets/setup_vivado.sh` & `vivado.nix`).
- **Development Toolchains**: Rust toolchain (`rustc`, `cargo`, `rust-analyzer`, `clippy`, `rustfmt`, `bacon`), Node.js, Python 3, Android Studio, `yazi` file manager, `zellij`, and `lazygit`.
- **Custom Utilities**: `boilerplate` (Nix module scaffolding generator) and `plsfail` (robust command failure tester).

---

## Architecture & Module Organization

```
+-------------------------------------------------------------+
|                         flake.nix                           |
|   inputs: nixpkgs 26.05, nixpkgs-unstable, flake-parts,    |
|           hjem, nvf, millennium, mangowc, dwl ...          |
+------------------------------+------------------------------+
                               | import-tree ./modules
                               v
                 +---------------------------+
                 |      modules/*.nix        |
                 |    (auto-discovered)      |
                 +-------------+-------------+
                               |
      +------------------------+------------------------+
      v                        v                        v
+-----------+            +-----------+            +-------------------+
|  desktop  |            |  laptop   |            |   devShells /     |
|   nixos   |            |   nixos   |            |   templates /     |
|  config   |            |  config   |            |    packages       |
+-----+-----+            +-----+-----+            +-------------------+
      |                        |
      +------------+-----------+
                   |
                   v
+-------------------------------------------------------------+
|                    Module Group Composition                 |
|   config.nixos.modules.shared                               |
|   config.nixos.modules.desktop / laptop                     |
+------------------------------+------------------------------+
                               |
      +------------------------+------------------------+
      v                                                 v
+-----------------------------+           +-----------------------------+
|    Feature Layers (shared)  |           |     Desktop / Compositors   |
| base, shell, cli, gaming,   |           | hyprland, niri,             |
| media, development, user... |           | mangowc, dwl, quickshell... |
+-----------------------------+           +-----------------------------+
```

### Key Architectural Concepts

1. **Auto-Discovery via `import-tree`**: Every `.nix` file placed inside `modules/` is automatically discovered by `flake-parts`.
2. **Deferred Module Groups**: Defined in `modules/module-groups.nix`. Modules merge their configurations into `nixos.modules.shared`, `nixos.modules.desktop`, or `nixos.modules.laptop`.
3. **No Cross-Imports**: Feature layers self-register into module groups. Host configurations (`modules/hosts/desktop/default.nix`) compose the required module groups without manually listing file imports.

---

## Project Directory Structure

```
flake.nix                          | Entry point: flake-parts + import-tree
build.sh                           | Rebuild helper script with conventional git commits
install.sh                         | Bootstrap installer script for fresh NixOS ISOs
assets/
├── setup_vivado.sh                | Helper script to set up Ubuntu 22.04 container for Vivado
└── wallpapers/                    | Managed wallpaper images
modules/
├── devshell.nix                   | Developer shell (`nix develop`) configuration
├── module-groups.nix              | Declaration of nixos.modules.* groups (shared, desktop, laptop)
├── options.nix                    | Global configuration options (username, theme, wallpaper)
├── parts.nix                      | System architectures (x86_64-linux)
├── templates.nix                  | Generic flake template exports
├── hosts/
│   ├── shared.nix                 | System settings shared across all hosts
│   ├── desktop/
│   │   ├── configuration.nix       | Desktop host overrides (NVIDIA, ports, Bluetooth)
│   │   ├── default.nix             | nixosConfigurations.desktop definition
│   │   ├── _hardware-generated.nix | Generated system hardware config
│   │   └── _installer-options.nix  | Host identity generated during installation
│   └── laptop/
│       ├── configuration.nix       | Laptop host overrides (Power/TLP, touchpad, Wi-Fi)
│       ├── default.nix             | nixosConfigurations.laptop definition
│       ├── _hardware-generated.nix | Generated system hardware config
│       └── _installer-options.nix  | Host identity generated during installation
├── features/
│   ├── layers/                    | System concerns self-registering into module groups
│   │   ├── base.nix               | Core Nix settings, timezone, locale, network, iwd
│   │   ├── bluetooth.nix          | Bluetooth hardware support
│   │   ├── cli.nix                | Command-line utilities (bat, btop, fzf, ripgrep, git, nix-index)
│   │   ├── communications.nix     | Vesktop / Discord messaging
│   │   ├── content-creation.nix   | Audacity, GIMP, ffmpeg
│   │   ├── cursors.nix            | Bibata cursor theme
│   │   ├── development.nix        | Toolchains (Cargo, Node, Neovim, Yazi, Zellij)
│   │   ├── fonts.nix              | JetBrainsMono, Noto, Instrument Serif, SF Pro
│   │   ├── gaming.nix             | Steam, Gamescope, MangoHud, DualSense PS5 controller driver
│   │   ├── media.nix              | Spotify, Zathura PDF reader
│   │   ├── nvidia.nix             | Proprietary NVIDIA GPU drivers & kernel patches
│   │   ├── pipewire.nix           | PipeWire audio & wireplumber configuration
│   │   ├── shell.nix              | Unstable Fish shell, Zsh, Starship prompt, Zoxide, Direnv
│   │   ├── startup.nix            | Wayland clipboard persistence services
│   │   ├── user.nix               | User account definition & hjem setup
│   │   └── wallpapers.nix         | Declarative wallpaper symlinks via hjem
│   ├── dwl/                       | DWL (dwm for Wayland) compositor
│   ├── hyprland/                  | Hyprland dynamic tiling compositor
│   ├── mangowc/                   | MangoWC Wayland compositor
│   ├── niri/                      | Niri scrollable tiling compositor
│   ├── quickshell/                | Unified QML desktop shell bar
│   ├── vicinae/                   | Vicinae launcher service & theme settings
│   ├── firefox/                   | Firefox browser custom profile
│   ├── neovim.nix                 | Declarative Neovim built with nvf
│   ├── nvim-src/                  | Custom Lua Neovim configuration source
│   ├── zen-browser.nix            | Zen Browser configuration
│   ├── vivado.nix                 | AMD Vivado launcher wrapper & desktop shortcut
│   └── podman-vm.nix              | Podman, Distrobox, and Boxbuddy virtualization
├── packages/                      | Custom flake packages (`pkgs.<name>`)
│   ├── boilerplate/               | Module & package scaffolding tool (`boilerplate.py`)
│   ├── dualsense-pair/            | Utility script to pair DualSense controllers
│   ├── foot/                      | Foot terminal configuration & package wrapper
│   ├── html-server/               | Quick local HTML preview web server
│   ├── plsfail/                   | Command failure stress-testing utility
│   └── tuxedo/                    | Tuxedo todo.txt TUI client
└── themes/
    ├── default.nix                | Theme options (active palette selector)
    └── palette.nix                | Curated color schemes (vague, catppuccin, gruvbox, rose-pine...)
```

---

## Hosts Comparison

| Host          | Primary Compositor          | Display Manager | Bootloader   | GPU Hardware       | Primary Target                             |
| :------------ | :-------------------------- | :-------------- | :----------- | :----------------- | :----------------------------------------- |
| **`desktop`** | Hyprland + DWL + Quickshell | Ly              | Limine (EFI) | NVIDIA Proprietary | High-Performance Workstation & Gaming      |
| **`laptop`**  | DWL + MangoWC + Quickshell  | Ly              | Limine (EFI) | AMD iGPU           | Portable Productivity & Battery Efficiency |

Both hosts inherit all shared feature layers (`base`, `shell`, `cli`, `development`, `gaming`, `pipewire`, etc.). Host-specific `configuration.nix` files add tailored hardware settings (such as NVIDIA drivers on `desktop` or power management on `laptop`).

---

## Installation

The automated installer is designed to be executed directly from a NixOS Minimal Live ISO.

### 1. Boot NixOS Minimal ISO

Boot your USB drive with the NixOS ISO and connect to Wi-Fi if needed:

```bash
nmtui
# Verify connection
ping -c3 1.1.1.1
```

### 2. Automated Install Script (`install.sh`)

Run the bootstrap installer script directly via `curl`:

```bash
# Interactive mode (prompts for host, disk, user, and hostname)
curl -fsSL https://raw.githubusercontent.com/Ssnibles/NixConfig/HEAD/install.sh | sudo bash

# Unattended install for desktop host
curl -fsSL https://raw.githubusercontent.com/Ssnibles/NixConfig/HEAD/install.sh | \
  sudo bash -s -- --host desktop --disk /dev/nvme0n1 --user josh --hostname desktop

# Unattended install for laptop host
curl -fsSL https://raw.githubusercontent.com/Ssnibles/NixConfig/HEAD/install.sh | \
  sudo bash -s -- --host laptop --disk /dev/nvme0n1 --user josh --hostname laptop
```

#### Useful Installer Flags

- `--dry-run`: Test formatting and installation steps without executing disk writes.
- `--skip-format`: Reinstall system packages while preserving partition tables.
- `--no-reboot`: Keep system mounted after install for manual inspection.
- `--overwrite`: Overwrite existing `~/NixConfig` directory without prompting.

### 3. Manual Installation

If you prefer installing manually:

```bash
# 1. Format disk (GPT, 512M FAT32 EFI, remainder ext4 nixos)
# 2. Mount partitions
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/EFI /mnt/boot

# 3. Clone config
mkdir -p /mnt/home/josh
git clone https://github.com/Ssnibles/NixConfig.git /mnt/home/josh/NixConfig
mkdir -p /mnt/etc
ln -sfn ../home/josh/NixConfig /mnt/etc/nixos

# 4. Generate hardware config
mkdir -p /mnt/etc/nixos/__gen_tmp
nixos-generate-config --root /mnt --dir /mnt/etc/nixos/__gen_tmp
mv /mnt/etc/nixos/__gen_tmp/hardware-configuration.nix \
   /mnt/etc/nixos/modules/hosts/desktop/_hardware-generated.nix
rm -rf /mnt/etc/nixos/__gen_tmp

# 5. Write installer options
cat > /mnt/etc/nixos/modules/hosts/desktop/_installer-options.nix <<'EOF'
{ lib, ... }:
{
  username = lib.mkForce "josh";
  networking.hostName = lib.mkForce "desktop";
}
EOF

# 6. Install & reboot
nixos-install --flake /mnt/etc/nixos#desktop
nixos-enter --root /mnt -- passwd josh
reboot
```

---

## Post-Install & Daily Workflow

### Rebuild Script (`build.sh`)

This repository ships with a comprehensive rebuild and git tracking script (`./build.sh`). It executes `nixos-rebuild`, queries the new system generation number, logs metadata (kernel version, changed flake locks, changed files), and creates a standardized conventional commit:

```bash
cd ~/NixConfig

# Basic rebuild & commit for desktop
./build.sh desktop switch

# Rebuild with a conventional commit type & message
./build.sh desktop switch -t feat -s hyprland -m "add custom window workspace rules"

# Build for boot on laptop
./build.sh laptop boot -t fix -m "adjust tlp battery threshold"

# Test build without creating a git commit
./build.sh desktop test --no-commit

# Commit staged changes without triggering a rebuild
./build.sh desktop --no-build -m "docs: update readme with new feature"
```

### Fish Abbreviations & Custom Functions

Custom shell shortcuts defined in `modules/features/layers/shell.nix`:

| Shortcut     | Expands to / Description                                             |
| :----------- | :------------------------------------------------------------------- |
| `rebuild`    | `sudo nixos-rebuild switch --flake ~/NixConfig#<hostname>`           |
| `update`     | `sudo nixos-rebuild switch --flake ~/NixConfig#<hostname> --upgrade` |
| `clean`      | `nh clean all`                                                       |
| `lg`         | `lazygit`                                                            |
| `y`          | `yazi`                                                               |
| `nixconf`    | Jump to `~/NixConfig` directory and show git branch status           |
| `nixup`      | Pull latest configuration changes and rebuild with `nh os switch`    |
| `mkcd <dir>` | Create directory `<dir>` and `cd` into it immediately                |

---

## Development Shell & Flake Templates

Enter the isolated development environment using Nix flakes or Direnv:

```bash
nix develop
# Or with direnv:
direnv allow
```

**Tools Included in DevShell**:

- Rust: `rustc`, `cargo`, `rust-analyzer`, `clippy`, `rustfmt`, `bacon`, `sea-orm-cli`
- Nix: `nixfmt`, `nil` (Nix LSP), `alejandra`
- Shell: Unstable Fish shell 4+
- Scaffolding: `boilerplate`

### Project Templates

#### ESP32 Arduino (`esp32-arduino`)

Initialize a new ESP32 microcontroller project anywhere:

```bash
mkdir my-esp32-project && cd my-esp32-project
nix flake init -t /home/josh/NixConfig#esp32-arduino
```

Once initialized:

1. Run `nix develop` (or `direnv allow`).
2. Run `esp-init` to download board definitions and install the ESP32 core.
3. Use `esp-compile`, `esp-upload`, `esp-monitor`, and `esp-gen-lsp` for building, flashing, monitoring, and Neovim LSP setup.

---

## Module Scaffolding (`boilerplate`)

The `boilerplate` tool automates creating new hosts, layers, features, and packages with proper module structure:

```bash
# View all available module kinds and specialized templates
boilerplate -l

# Scaffold basic items
boilerplate layer my-layer                  # Creates modules/features/layers/my-layer.nix
boilerplate feature my-feature              # Creates modules/features/my-feature.nix
boilerplate host work-station               # Creates modules/hosts/work-station/ & updates module-groups.nix

# Create specialized package types
boilerplate package my-rust-app -t rust     # Creates Rust buildRustPackage derivation
boilerplate package my-script -t python     # Creates Python 3 binary writer script
boilerplate package my-tool -t stdenv       # Creates standard stdenv.mkDerivation package

# Create specialized feature types
boilerplate feature app-daemon -t service   # Creates systemd user service feature
boilerplate feature app-theme -t theme      # Creates theme-integrated dotfile feature
boilerplate layer widget --target desktop   # Targets desktop host specifically
```

---

## Theme & Wallpaper Customization

### Palette Switcher

Edit `modules/options.nix` to change the global active color palette:

```nix
config.theme.active = "vague"; # Choices: vague, catppuccin, gruvbox, rose-pine...
```

The selected scheme dynamically propagates color variables (`c.bg`, `c.fg`, `c.accent`, `c.purple`, etc.) across Neovim, Fish, Vicinae, Quickshell, and Foot terminal.

### Wallpaper Management

Wallpapers are stored in `assets/wallpapers/`. Configure default wallpaper selection in `modules/options.nix`:

```nix
options.wallpaper = lib.mkOption {
  default = "nordic-landscape.png";
};
```

---

## Nix & NixOS Learning Resources

Whether you are starting out or mastering advanced flake architectures, here are curated resources to deepen your understanding:

### Core Concepts & Official Guides

- 📖 [Nix Reference Manual](https://nix.dev/manual/nix/latest/) — Essential reference for the Nix language, expressions, and built-in functions.
- 🐧 [NixOS Official Manual](https://nixos.org/manual/nixos/stable/) — Comprehensive guide for configuring NixOS services, modules, and hardware options.
- 🚀 [Nix.dev Tutorials](https://nix.dev/) — Opinionated, official documentation for getting started with reproducible environments.
- 💊 [Nix Pills](https://nixos.org/guides/nix-pills/) — The classic deep-dive tutorial explaining how Nix derivations, closures, and the store work step-by-step from first principles.

### Flakes & Modular Architecture

- ⚡ [Zero to Nix](https://zero-to-nix.com/) — Modern, beginner-friendly guide to Nix Flakes by Determinate Systems.
- 🧩 [Flake-Parts Documentation](https://flake.parts/) — Framework for composing modular, multi-system flake configurations.
- 🌳 [Dendritic Architecture Pattern](https://github.com/mightyiam/dendritic) — The filesystem-as-module-tree design pattern implemented in this repository.
- 🏠 [Hjem User Environment Manager](https://github.com/feel-co/hjem) — Lightweight, module-native user file management used in place of Home Manager.

### Search & Community Tools

- 🔍 [NixOS Package & Option Search](https://search.nixos.org/) — Search millions of Nix packages and standard system options.
- 🔎 [Noogle (Nix Function Search)](https://noogle.dev/) — Search Nix language library functions (`lib.*`, `builtins.*`).
- 💬 [NixOS Discourse Forum](https://discourse.nixos.org/) — Active community Q&A and architecture discussions.

---

## Troubleshooting

### Evaluation Errors (`nix flake check`)

Run a full syntax and evaluation check before rebuilding:

```bash
NIXPKGS_ALLOW_UNFREE=1 nix flake check --impure
```

### Rolling Back System Generations

If a rebuild introduces unexpected issues, roll back to a previous working state:

```bash
# Roll back running system
sudo nixos-rebuild switch --rollback

# Or select a previous generation entry from the Limine bootloader menu on boot
```

### Log Inspection

- **Vicinae Server**: `journalctl --user -u vicinae-server -f`
- **Wayland Session**: `journalctl --user-unit wayland-session -f`
- **System Rebuild Logs**: `/var/log/nixos-install.log`

---

_Configured and maintained by yours truly :)._
