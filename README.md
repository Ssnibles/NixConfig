# NixConfig

<div align="center">

[![NixOS 26.05](https://img.shields.io/badge/NixOS-26.05%20(Stable)-5277C3?style=for-the-badge&logo=nixos&logoColor=white)](https://nixos.org)
[![Nixpkgs Unstable](https://img.shields.io/badge/Nixpkgs-Unstable-5277C3?style=for-the-badge&logo=nixos&logoColor=white)](https://github.com/nixos/nixpkgs)
[![Flake-Parts](https://img.shields.io/badge/Flake--Parts-Modular-blueviolet?style=for-the-badge&logo=nixos&logoColor=white)](https://flake.parts)
[![Dendritic](https://img.shields.io/badge/Architecture-Dendritic-2ea44f?style=for-the-badge)](https://github.com/mightyiam/dendritic)
[![Hjem](https://img.shields.io/badge/Dotfiles-Hjem-orange?style=for-the-badge)](https://github.com/feel-co/hjem)
[![Limine](https://img.shields.io/badge/Bootloader-Limine-333333?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://limine-bootloader.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

A clean, modern, and high-performance **[dendritic](https://github.com/mightyiam/dendritic)** NixOS configuration designed for daily workstation productivity, embedded systems engineering, and low-latency gaming across `desktop` (NVIDIA) and `laptop` (AMD) hardware.

</div>

---

## Overview

**NixConfig** implements the dendritic architecture pattern using **`flake-parts`** and **`import-tree`**. Every `.nix` file within `modules/` is automatically discovered and composed without manual import lists.

The system pins **`nixos-26.05`** for rock-solid base operating system stability while seamlessly layering an integrated **`nixos-unstable`** overlay for bleeding-edge desktop software, terminal tooling, and development packages.

User environments and dotfiles are managed declaratively using **[hjem](https://github.com/feel-co/hjem)**, a lightweight, module-native alternative to Home Manager that integrates directly into NixOS options.

---

## Table of Contents

- [Overview](#overview)
- [System Architecture](#system-architecture)
- [Key Features](#key-features)
  - [Core System & Boot](#core-system--boot)
  - [Wayland Desktop & Compositors](#wayland-desktop--compositors)
  - [Quickshell Desktop Shell](#quickshell-desktop-shell)
  - [Terminal, Shell & Multiplexer](#terminal-shell--multiplexer)
  - [Declarative Neovim & Development](#declarative-neovim--development)
  - [Hardware, Microcontrollers & FPGA](#hardware-microcontrollers--fpga)
  - [Browsers, Media & Gaming](#browsers-media--gaming)
- [Repository Structure](#repository-structure)
- [Hosts Comparison](#hosts-comparison)
- [Wiki & Feature Guides](#-wiki--feature-guides)
- [Installation](#installation)
  - [1. Boot NixOS Minimal ISO](#1-boot-nixos-minimal-iso)
  - [2. Automated Bootstrap (`install.sh`)](#2-automated-bootstrap-installsh)
  - [3. Manual Installation](#3-manual-installation)
- [Daily Workflow & Rebuilds](#daily-workflow--rebuilds)
  - [Conventional Commit Builder (`build.sh`)](#conventional-commit-builder-buildsh)
  - [Fast Rebuild Helper (`rebuild.sh`)](#fast-rebuild-helper-rebuildsh)
  - [Fish Abbreviations & Functions](#fish-abbreviations--functions)
- [Themes & Wallpaper Management](#themes--wallpaper-management)
  - [Color Palettes](#color-palettes)
  - [Typography](#typography)
  - [Wallpapers](#wallpapers)
- [Custom Flake Packages](#custom-flake-packages)
- [Flake Templates & Developer Shell](#flake-templates--developer-shell)
  - [Developer Shell (`nix develop`)](#developer-shell-nix-develop)
  - [ESP32 Arduino Template (`esp32-arduino`)](#esp32-arduino-template-esp32-arduino)
  - [Generic Dendritic Template (`generic`)](#generic-dendritic-template-generic)
- [Scaffolding with `boilerplate`](#scaffolding-with-boilerplate)
- [Troubleshooting & Maintenance](#troubleshooting--maintenance)
- [Learning Resources](#learning-resources)

---

## System Architecture

The configuration is organized into deferred module groups defined in [`modules/core/module-groups.nix`](file:///home/josh/NixConfig/modules/core/module-groups.nix):

- **`config.nixos.modules.shared`**: Common base configuration, kernel optimizations, systemd services, shell environment, and desktop applications applied to all hosts.
- **`config.nixos.modules.desktop`**: Workstation-specific hardware configuration (NVIDIA proprietary drivers, ASUS WMI rfkill unblocking, gaming stack, and workstation compositors).
- **`config.nixos.modules.laptop`**: Laptop-specific hardware configuration (AMD graphics, TLP battery optimization profiles, ELAN ACPI touchpad fixes, and ath11k Wi-Fi modules).

```
+---------------------------------------------------------------------------------+
|                                   flake.nix                                     |
|    inputs: nixpkgs (26.05), nixpkgs-unstable, flake-parts, import-tree,         |
|            hjem, nvf, mangowc, dwl, millennium, zen-browser, devenv ...         |
+----------------------------------------+----------------------------------------+
                                         |
                                         | inputs.import-tree ./modules
                                         v
                         +-------------------------------+
                         |     modules/ (Auto-Discovery) |
                         +---------------+---------------+
                                         |
         +-------------------------------+-------------------------------+
         |                               |                               |
         v                               v                               v
+------------------+           +--------------------+          +--------------------+
|  modules/core/   |           | modules/features/  |          | modules/packages/  |
|  - module-groups |           | - system/          |          | - boilerplate      |
|  - options       |           | - shell/           |          | - dualsense-pair   |
|  - parts         |           | - desktop-env/     |          | - html-server      |
|  - devshell      |           | - apps/            |          | - plsfail          |
|  - templates     |           | - nvim-src/        |          | - tuxedo, fonts... |
+--------+---------+           +---------+----------+          +---------+----------+
         |                               |                               |
         +-------------------------------+-------------------------------+
                                         |
                                         v
                   +--------------------------------------------+
                   |          Module Group Composition          |
                   |  nixos.modules.shared                      |
                   |  nixos.modules.desktop / laptop            |
                   +---------------------+----------------------+
                                         |
                    +--------------------+--------------------+
                    |                                         |
                    v                                         v
         +----------------------+                  +----------------------+
         | flake.nixos          |                  | flake.nixos          |
         | Configurations       |                  | Configurations       |
         | .desktop             |                  | .laptop              |
         +----------------------+                  +----------------------+
```

Every module declares its settings inside `nixos.modules.shared`, `nixos.modules.desktop`, or `nixos.modules.laptop`, eliminating cross-file imports and cyclic dependencies.

---

## Key Features

### Core System & Boot
- **Limine Bootloader**: Fast, modern EFI bootloader configured with a 5-second timeout and 10-generation history retention.
- **Plymouth Boot Splash**: Clean, graphical boot screen using the Catppuccin Mocha theme with silent boot parameters (`quiet`, `splash`, `loglevel=3`).
- **Display Manager**: Lightweight TTY-based [Ly](https://github.com/fairyglade/ly) login manager with GNOME Keyring PAM integration.
- **Hardware Keyboard Mapping**: Kernel-level Caps Lock $\leftrightarrow$ Escape swap configured via udev hwdb (`evdev:atkbd` and `evdev:input`).
- **Kernel & Performance Tuning**: Latest mainline kernel (`linuxPackages_latest`) with CPU vulnerability mitigations disabled (`mitigations=off`), `nowatchdog`, zstd-compressed initrd, aggressive swappiness (`10`), and VFS cache pressure (`200`).
- **DNS-over-TLS**: Encrypted systemd-resolved DNS using Cloudflare (`1.1.1.1`, `1.0.0.1`) with Google DNS fallback (`8.8.8.8`).
- **Wi-Fi & Networking**: NetworkManager paired with the high-performance `iwd` backend with Opportunistic Wireless Encryption (OWE) enabled.
- **Boot Error Notifier**: Custom daemon ([`journal-error-notify.nix`](file:///home/josh/NixConfig/modules/features/system/journal-error-notify.nix)) that scans boot logs for critical errors, filters out benign noise, and dispatches a desktop notification upon login.
- **Automated Maintenance**: Fast builds via `nh`, automatic store deduplication (`nix.optimise`), and automated garbage collection keeping the latest 3 generations / 30 days.

### Wayland Desktop & Compositors
- **Multi-Compositor Choice**: Choose between dynamically tiled, manual, or scrollable Wayland sessions:
  - **Hyprland**: Dynamic Wayland compositor configured through [`hyprland.lua`](file:///home/josh/NixConfig/modules/features/desktop-env/hyprland/hyprland.lua) with theme palette integration.
  - **DWL (dwm for Wayland)**: Fast, suckless-inspired Wayland compositor equipped with an autostart wrapper and Quickshell status bar support.
  - **MangoWC**: Modern DWM-style compositor with dwindle layouts, special workspace tags, and dynamic border coloration.
  - **Niri**: Scrollable-tiling Wayland compositor with `niri-float-sticky` and `xwayland-satellite` support.
- **Shikane Display Daemon**: Dynamic multi-monitor profile manager ([`shikane/default.nix`](file:///home/josh/NixConfig/modules/features/desktop-env/shikane/default.nix)) automatically adapting layouts for laptop-only, dual-display, and external monitor setups.
- **Vicinae Application Launcher**: Fast layer-shell launcher running as a systemd user daemon with custom theme styling and integrated fuzzy clipboard history search.
- **Wayland Clipboard Suite**: Session persistence via `wl-clip-persist` (for both regular and primary selections) and text/image history powered by `cliphist`.
- **System Cursors & Fonts**: Bibata Modern Ice cursor theme across GTK, Xcursor, and Hyprcursor, paired with SF Pro Text, Instrument Serif, and JetBrains Mono Nerd Font.

### Quickshell Desktop Shell
- **Unified QML Shell Framework**: Highly modular desktop shell written in QML, providing consistent widgets and bars across all compositors.
- **Multi-Compositor Routing**: Abstract `WmService.qml` routing events across DWL, Hyprland, Mango, Niri, and River.
- **Command Center & Lock Screen**: Pull-down system control center with quick toggles, sliders, media controls, and a dedicated lock screen overlay.
- **Rich Status Bar**: Modular status bar featuring workspaces, active window titles, volume, battery percentage, Bluetooth devices, network telemetry, and clock widgets.
- **Notification Daemon**: Built-in notification overlay and notification store replacement.

### Terminal, Shell & Multiplexer
- **Fish Shell 4+**: Bleeding-edge Fish shell as the default login shell, featuring auto-pairing, Bass script runner, and custom shortcuts.
- **Cached FZF File & Directory Navigation**: Custom Fish caching engine (`__fzf_cache_fd`) that caches `fd` traversal per directory for 5 minutes, making file and directory searches instantaneous even in large codebases.
- **Starship Prompt**: Custom Starship configuration with runtime language indicators (Rust, Python, Node.js, Nix shell), Git status indicators, and clean transient execution (`>>`).
- **Zsh Fallback**: Configured with Oh-My-Zsh plugins (`git`, `direnv`, `z`) and syntax highlighting.
- **Advanced Tmux Multiplexer**:
  - Interactive FZF window switcher (`tmux-window-picker`) with live pane previews.
  - Smart pane path formatter (`tmux-path-formatter`) that truncates long paths.
  - Nix store path sanitizer (`tmux-resurrect-save`) that cleans wrapped store hashes from resurrect files so sessions restore reliably across NixOS updates.
  - Plugins: `resurrect`, `extrakto`, and `floax`.
- **Modern CLI Utilities**: `zoxide` (smart directory jumping), `direnv` with `nix-direnv`, `bat`, `btop`, `ripgrep`, `fd`, `microfetch`, `croc`, and `nix-index` for command-not-found package lookup.

### Declarative Neovim & Development
- **Declarative Neovim via NVF**: Neovim managed through [nvf](https://github.com/NotAShelf/nvf), linked directly to a modular Lua configuration tree under [`modules/features/nvim-src/`](file:///home/josh/NixConfig/modules/features/nvim-src/).
- **Language Support & LSPs**: Complete LSP, DAP, formatter, and linter configurations for Rust, Zig, Go, C/C++, Python, TypeScript/JavaScript, Kotlin, Java, Typst, Nix, and QML.
- **Specialized LSP Wrappers**:
  - `qmlls`: Wrapped with QtQuick and Quickshell include paths for type checking.
  - `zls`: Wrapped with Wayland, wlroots, and libinput system headers for Wayland compositor development.
- **Neovim Plugins**: Blink.cmp completion, Treesitter, FZF-Lua, Oil.nvim, Mini.nvim, Copilot, Neogit, Grug-far, DAP UI, Tiny Inline Diagnostics, and custom plugins (`sshinator`, `indentinator`, `zline`).
- **AI-Assisted Engineering**: Integrated with `antigravity-cli`.

### Hardware, Microcontrollers & FPGA
- **ESP32 & Arduino Development**: Built-in developer workflow with `arduino-cli`, `esptool`, and automated Neovim / Clangd LSP compilation database generators.
- **AMD Vivado Design Suite 2024.2**: Containerized FPGA workflow running inside an isolated Ubuntu 22.04 Distrobox container with full X11/GUI passthrough and desktop launcher integration.
- **Hardware Debugging & Udev Rules**: OpenOCD, DFU utilities (`dfu-util`), and udev permissions for CP210x, CH340, FTDI FT2232, and Meshtastic hardware.

### Browsers, Media & Gaming
- **Firefox Developer Edition**: High-performance browser setup with FastFox optimizations, custom `userChrome.css` and `userContent.css`, Sidebery vertical tab bar integration, and an embedded offline startpage WebExtension.
- **Zen Browser**: Configured with enterprise privacy policies (telemetry disabled, tracking protection enabled) and XDG MIME associations.
- **Gaming Suite**: Steam with the Millennium skinning framework, Gamescope session integration, GameMode daemon, and MangoHud performance overlay.
- **PlayStation 5 DualSense Controllers**: Full kernel driver support via `hid-playstation` and a custom Bluetooth pairing utility script (`dualsense-pair`).
- **Media & Documents**: Spotify, Feh image viewer, and Zathura PDF reader configured with theme colors and SyncTeX Neovim reverse jumping (`nvr --remote-silent`).

---

## Repository Structure

```
NixConfig/
├── flake.nix                          # Flake inputs and dendritic entry point
├── build.sh                           # Rebuild script with conventional commit generation
├── rebuild.sh                         # Fast rebuild helper (DWL override, boot, test)
├── install.sh                         # Bootstrap installer for NixOS Minimal ISOs
├── todo.txt                           # Project task tracking
│
├── assets/
│   ├── setup_vivado.sh                # Container setup script for AMD Vivado 2024.2
│   └── wallpapers/                    # Managed wallpaper library
│       ├── blackbird.jpg              # Default system wallpaper
│       ├── girl-standing-at-sea.jpg
│       ├── lighthouse.jpg
│       ├── sheppard.jpg
│       ├── spiral-dark.png
│       └── stardew-valley-night.png
│
├── docs/
│   └── wiki/                          # Detailed subsystem documentation guides
│       ├── index.md                   # Wiki homepage & reference index
│       ├── esp32-arduino.md           # ESP32 & Arduino toolchain guide
│       ├── quickshell.md              # Quickshell QML shell & widget architecture
│       ├── compositors.md             # Hyprland, DWL, MangoWC, and Niri guide
│       ├── neovim.md                  # NVF declarative Neovim & Lua plugins
│       ├── firefox.md                 # Firefox userChrome & Sidebery customization
│       ├── vivado-fpga.md             # AMD Vivado Distrobox container guide
│       └── gaming.md                  # Steam, Millennium, and PS5 controller setup
│
├── templates/
│   ├── generic/                       # Minimal dendritic flake template
│   └── esp32-arduino/                 # Complete ESP32 Arduino development template
│
└── modules/
    ├── core/                          # Flake-parts infrastructure & system options
    │   ├── devshell.nix               # Developer environment (Rust, Nix tools, Fish)
    │   ├── module-groups.nix          # Declaration of shared, desktop, laptop groups
    │   ├── options.nix                # System options (username, active wallpaper)
    │   ├── parts.nix                  # Platform architectures (x86_64-linux)
    │   └── templates.nix              # Exported flake templates
    │
    ├── hosts/                         # Host machine definitions
    │   ├── shared.nix                 # Common base (Limine, Ly, kernel tuning, swap)
    │   ├── desktop/
    │   │   ├── default.nix            # nixosConfigurations.desktop entry point
    │   │   ├── configuration.nix      # Workstation overrides (NVIDIA, rfkill, audio)
    │   │   ├── _hardware-generated.nix# System hardware configuration
    │   │   └── _installer-options.nix # Identity options generated during install
    │   └── laptop/
    │       ├── default.nix            # nixosConfigurations.laptop entry point
    │       ├── configuration.nix      # Laptop overrides (TLP, touchpad, ath11k Wi-Fi)
    │       ├── _hardware-generated.nix# System hardware configuration
    │       └── _installer-options.nix # Identity options generated during install
    │
    ├── features/                      # System capabilities and user environments
    │   ├── system/                    # Core system layers
    │   │   ├── base.nix               # Nixpkgs overlays, caches, network, nh GC
    │   │   ├── bluetooth.nix          # Bluetooth stack & Blueman service
    │   │   ├── journal-error-notify.nix # Boot error detection notification daemon
    │   │   ├── nvidia.nix             # Proprietary NVIDIA GPU drivers & Wayland flags
    │   │   ├── pipewire.nix           # Low-latency PipeWire & WirePlumber audio
    │   │   ├── plymouth.nix           # Catppuccin Mocha boot splash screen
    │   │   ├── podman-vm.nix          # Podman, Distrobox, and Boxbuddy containers
    │   │   ├── startup.nix            # Clipboard persistence & session targets
    │   │   ├── user.nix               # User account definition & Hjem setup
    │   │   └── wallpapers.nix         # Declarative wallpaper symlinking via Hjem
    │   │
    │   ├── shell/                     # Interactive shell & multiplexer
    │   │   ├── cli.nix                # Common CLI tools & Git identity configuration
    │   │   ├── shell.nix              # Fish 4+, Starship prompt, FZF cached search
    │   │   └── tmux.nix               # Tmux setup, window picker, resurrect sanitizer
    │   │
    │   ├── desktop-env/               # Graphical environment & window managers
    │   │   ├── cursors.nix            # Bibata Modern Ice cursor configuration
    │   │   ├── fonts.nix              # Typography definitions (SF Pro, Inter, Noto)
    │   │   ├── dwl/                   # DWL Wayland compositor & autostart wrapper
    │   │   ├── hyprland/              # Hyprland compositor & hyprland.lua
    │   │   ├── mangowc/               # Mango Wayland compositor configuration
    │   │   ├── niri/                  # Niri scrollable compositor configuration
    │   │   ├── quickshell/            # Quickshell QML shell, widgets, and lock screen
    │   │   ├── shikane/               # Shikane dynamic display profile daemon
    │   │   └── vicinae/               # Vicinae launcher daemon & theme styling
    │   │
    │   ├── apps/                      # User applications & development tools
    │   │   ├── communications.nix     # Vesktop / Discord client
    │   │   ├── content-creation.nix   # Audacity, FFmpeg, FLAC, GIMP 3
    │   │   ├── development.nix        # Runtimes, Antigravity CLI, compilers, Android Studio
    │   │   ├── firefox/               # Firefox Developer Edition, CSS, Sidebery
    │   │   ├── gaming.nix             # Steam, Millennium, Gamescope, MangoHud
    │   │   ├── media.nix              # Spotify, Feh, and Zathura PDF reader
    │   │   ├── neovim.nix             # NVF Neovim configuration & packages
    │   │   ├── vivado.nix             # AMD Vivado Distrobox integration
    │   │   └── zen-browser.nix        # Zen Browser with enterprise privacy policies
    │   │
    │   └── nvim-src/                  # Modular Lua source tree for Neovim
    │       ├── init.lua               # Neovim entry point
    │       └── lua/                   # Plugins, keymaps, autocommands, diagnostics
    │
    ├── packages/                      # Custom packages exported by this flake
    │   ├── boilerplate/               # Module scaffolding generator CLI
    │   ├── dualsense-pair/            # DualSense PS5 controller Bluetooth pairing tool
    │   ├── foot/                      # Foot terminal package & theme configuration
    │   ├── html-server/               # Go web server with live reloading
    │   ├── instrument-serif/          # Instrument Serif font derivation
    │   ├── plsfail/                   # Command failure stress-testing utility
    │   ├── sf-pro/                    # Apple San Francisco Pro font derivation
    │   └── tuxedo/                    # Rust todo.txt TUI client derivation
    │
    └── themes/                        # Dynamic styling engine
        ├── default.nix                # Theme schema options (config.theme.active)
        └── palette.nix                # Curated color palettes (11 schemes)
```

---

## Hosts Comparison

| Specification / Layer | Workstation (`desktop`) | Laptop (`laptop`) |
| :--- | :--- | :--- |
| **Primary Target** | High-performance workstation & gaming | Ultraportable productivity & battery life |
| **Graphics Hardware** | Dedicated NVIDIA GPU (Proprietary driver) | Integrated AMD Radeon Graphics |
| **Kernel & Modules** | Pinned `linuxPackages` with NVIDIA DRM & fbdev | `linuxPackages_latest` with `amdgpu` |
| **Power Management** | AC performance mode, no throttling | TLP battery profiles, ASPM power savings, AMDGPU ABM |
| **Display Manager** | Ly TTY Login Manager | Ly TTY Login Manager |
| **Bootloader** | Limine (EFI) with Plymouth Catppuccin splash | Limine (EFI) with Plymouth Catppuccin splash |
| **Active Compositors** | Hyprland, DWL, MangoWC | DWL, MangoWC |
| **Hardware Quirks** | ASUS WMI Bluetooth rfkill unblock service | ELAN ACPI touchpad polling workaround, ath11k Wi-Fi |
| **Peripheral Stack** | Logitech wireless support, DualSense kernel driver | DFU / OpenOCD / Meshtastic serial udev permissions |
| **Audio & Media** | Low-latency PipeWire, Amberol, Spotify | Low-latency PipeWire, Gowall, Spotify |

---

## 📚 Wiki & Feature Guides

Comprehensive documentation, architecture references, and step-by-step workflow manuals are available in the **[NixConfig Wiki](docs/wiki/index.md)**:

| Feature / Subsystem | Guide Link | Description |
| :--- | :--- | :--- |
| **ESP32 & Arduino** | [esp32-arduino.md](docs/wiki/esp32-arduino.md) | ESP32 toolchains, `arduino-cli`, `esptool`, Neovim Clangd LSP compilation database generation (`esp-gen-lsp`), and project templates |
| **Quickshell UI** | [quickshell.md](docs/wiki/quickshell.md) | Quickshell QML framework architecture, status bar widgets, Command Center, Lock Screen, and IPC control |
| **Wayland Compositors** | [compositors.md](docs/wiki/compositors.md) | Configuration guide for Hyprland (with Lua), DWL, MangoWC, and Niri tiling compositors |
| **Declarative Neovim** | [neovim.md](docs/wiki/neovim.md) | NVF Neovim setup, custom Lua plugins in `modules/features/nvim-src/`, language servers, DAPs, and formatting |
| **Firefox & Sidebery** | [firefox.md](docs/wiki/firefox.md) | Custom `userChrome.css` styling, Sidebery vertical tab bar setup, startpage WebExtension, and live CSS debugging |
| **AMD Vivado FPGA** | [vivado-fpga.md](docs/wiki/vivado-fpga.md) | Distrobox Ubuntu 22.04 container setup, GUI/X11 forwarding, desktop shortcut integration, and high-DPI scaling |
| **Gaming & Controllers** | [gaming.md](docs/wiki/gaming.md) | Steam with Millennium skinning, Gamescope composited sessions, MangoHud overlay, and DualSense PS5 controller kernel drivers |

---

## Installation

The automated installer is designed to run directly from an official NixOS Minimal Live ISO.

### 1. Boot NixOS Minimal ISO

Boot your target system using a NixOS Minimal Installation ISO and establish a network connection:

```bash
# Connect to Wi-Fi if using wireless
nmtui

# Verify internet connectivity
ping -c 3 1.1.1.1
```

### 2. Automated Bootstrap (`install.sh`)

Execute the bootstrap installer directly via `curl`:

```bash
# Interactive mode (prompts for host target, installation disk, username, and hostname):
curl -fsSL https://raw.githubusercontent.com/Ssnibles/NixConfig/HEAD/install.sh | sudo bash
```

#### Unattended One-Liners

You can perform completely unattended installations by passing arguments directly:

```bash
# Desktop Workstation install
curl -fsSL https://raw.githubusercontent.com/Ssnibles/NixConfig/HEAD/install.sh | \
  sudo bash -s -- --host desktop --disk /dev/nvme0n1 --user josh --hostname desktop

# Laptop install
curl -fsSL https://raw.githubusercontent.com/Ssnibles/NixConfig/HEAD/install.sh | \
  sudo bash -s -- --host laptop --disk /dev/nvme0n1 --user josh --hostname laptop
```

#### Useful Installer Flags

| Flag | Argument | Description |
| :--- | :--- | :--- |
| `--host`, `-H` | `<host>` | Flake host configuration (`desktop` or `laptop`) |
| `--disk`, `-d` | `<path>` | Installation target drive (e.g., `/dev/nvme0n1`, `/dev/sda`) |
| `--user`, `-u` | `<name>` | Primary username to configure (defaults to `josh`) |
| `--hostname`, `-n` | `<name>` | Machine network hostname |
| `--ssh-key`, `-k` | `<path>` | Local public key file to install into `~/.ssh/authorized_keys` |
| `--github-ssh`, `-g`| `<user>` | Fetch and install public SSH keys from `github.com/<user>.keys` |
| `--skip-format` | — | Reinstall system packages while preserving disk partition tables |
| `--no-reboot` | — | Keep the installation mounted under `/mnt` after completion |
| `--dry-run` | — | Print planned commands without partitioning or writing to disk |
| `--overwrite` | — | Overwrite existing `~/NixConfig` directory without prompting |

### 3. Manual Installation

To install manually from the ISO without the automated script:

```bash
# 1. Partition the target disk (GPT: 512MB EFI vfat, remainder ext4 nixos)
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 513MiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart nixos ext4 513MiB 100%

# 2. Format filesystems
mkfs.fat -F 32 -n EFI /dev/nvme0n1p1
mkfs.ext4 -L nixos -F /dev/nvme0n1p2

# 3. Mount filesystems
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/EFI /mnt/boot

# 4. Clone NixConfig
mkdir -p /mnt/home/josh
git clone https://github.com/Ssnibles/NixConfig.git /mnt/home/josh/NixConfig
mkdir -p /mnt/etc
ln -sfn ../home/josh/NixConfig /mnt/etc/nixos

# 5. Generate hardware configuration
mkdir -p /mnt/etc/nixos/__gen_tmp
nixos-generate-config --root /mnt --dir /mnt/etc/nixos/__gen_tmp
mv /mnt/etc/nixos/__gen_tmp/hardware-configuration.nix \
   /mnt/etc/nixos/modules/hosts/desktop/_hardware-generated.nix
rm -rf /mnt/etc/nixos/__gen_tmp

# 6. Configure host options
cat > /mnt/etc/nixos/modules/hosts/desktop/_installer-options.nix <<'EOF'
{ lib, ... }:
{
  username = lib.mkForce "josh";
  networking.hostName = lib.mkForce "desktop";
}
EOF

# 7. Install NixOS and set password
nixos-install --flake /mnt/etc/nixos#desktop
nixos-enter --root /mnt -- passwd josh

# 8. Reboot into new system
reboot
```

---

## Daily Workflow & Rebuilds

### Conventional Commit Builder (`build.sh`)

The repository includes a comprehensive rebuild tool ([`build.sh`](file:///home/josh/NixConfig/build.sh)) that automates system rebuilds, tracks system generations, captures kernel and flake lock changes, and creates conventional Git commits:

```bash
cd ~/NixConfig

# Rebuild current host and commit changes
./build.sh desktop switch

# Rebuild with a conventional commit type, scope, and message
./build.sh desktop switch -t feat -s hyprland -m "add custom window workspace rules"

# Build for next boot on laptop
./build.sh laptop boot -t fix -s power -m "tune tlp battery thresholds"

# Test build in memory without creating a Git commit
./build.sh desktop test --no-commit

# Commit staged changes without triggering nixos-rebuild
./build.sh desktop --no-build -m "docs: update system architecture details"
```

### Fast Rebuild Helper (`rebuild.sh`)

For rapid development cycles or local compositor testing, [`rebuild.sh`](file:///home/josh/NixConfig/rebuild.sh) stages modified files and initiates rebuilds instantly:

```bash
# Quick switch for the current host
./rebuild.sh

# Rebuild NixOS with a local DWL source code override from ~/dwl
./rebuild.sh --dwl

# Test current session only
./rebuild.sh --test
```

### Fish Abbreviations & Functions

Defined in [`modules/features/shell/shell.nix`](file:///home/josh/NixConfig/modules/features/shell/shell.nix):

| Shortcut | Type | Action / Expansion |
| :--- | :--- | :--- |
| `rebuild` | Alias | `sudo nixos-rebuild switch --flake ~/NixConfig#<host>` |
| `update` | Alias | `sudo nixos-rebuild switch --flake ~/NixConfig#<host> --upgrade` |
| `clean` | Alias | `nh clean all` (Automated generation cleanup) |
| `nixclean` | Abbreviation | `sudo nix-collect-garbage --delete-older-than 30d` |
| `lg` | Abbreviation | `lazygit` (Git TUI client) |
| `y` | Abbreviation | `yazi` (Terminal file manager) |
| `nixconf` | Function | Jump to `~/NixConfig` directory and print Git branch status |
| `nixup` | Function | Pull upstream Git changes and rebuild using `nh os switch` |
| `mkcd <dir>`| Function | Create directory `<dir>` and `cd` into it immediately |

---

## Themes & Wallpaper Management

System styling is controlled centrally in [`modules/themes/`](file:///home/josh/NixConfig/modules/themes/). Selecting an active palette automatically propagates color variables (`bg`, `fg`, `accent`, `border`, `teal`, `purple`, etc.) into Quickshell, Vicinae, Neovim, Foot terminal, Tmux, Firefox, and Zathura.

### Color Palettes

Change the global palette in [`modules/themes/default.nix`](file:///home/josh/NixConfig/modules/themes/default.nix):

```nix
options.theme.active = lib.mkOption {
  type = lib.types.str;
  default = "vague"; # Set your active palette here
};
```

#### Curated Palettes in [`palette.nix`](file:///home/josh/NixConfig/modules/themes/palette.nix):
- **`vague`** *(Default)* — Warm, low-contrast muted aesthetic
- **`catppuccin-mocha`** — Vibrant modern pastel theme
- **`gruvbox-dark`** / **`gruvbox-dark-hard`** / **`gruvbox-light-hard`** — Classic retro groove schemes
- **`rose-pine`** / **`rose-pine-moon`** / **`rose-pine-dawn`** — Minimalist Soho-inspired elegance
- **`default-dark`** / **`default-light`** — Clean neutral base palettes
- **`everforest-light`** — Natural, low-strain green hues

### Typography

Configured in [`modules/themes/default.nix`](file:///home/josh/NixConfig/modules/themes/default.nix):

- **Sans-Serif**: `SF Pro Text` (Apple San Francisco Pro)
- **Monospace**: `JetBrainsMono Nerd Font`
- **Serif**: `Instrument Serif`

### Wallpapers

Wallpapers live in [`assets/wallpapers/`](file:///home/josh/NixConfig/assets/wallpapers/). Change the active wallpaper in [`modules/core/options.nix`](file:///home/josh/NixConfig/modules/core/options.nix):

```nix
options.wallpaper = lib.mkOption {
  type = lib.types.str;
  default = "blackbird.jpg"; # Options: blackbird.jpg, lighthouse.jpg, sheppard.jpg, etc.
};
```

Whenever compositors declare `wallpaper-destinations = [ "Pictures/wallpaper" ];`, Hjem links the chosen wallpaper into `~/Pictures/wallpaper`.

---

## Custom Flake Packages

This repository exports custom packages under `self.packages.${system}`:

- **`boilerplate`**: Python CLI utility for rapid scaffolding of layers, features, hosts, and packages.
- **`dualsense-pair`**: Bluetooth helper script to pair and configure Sony PlayStation 5 DualSense controllers.
- **`foot`**: Pre-configured Foot terminal emulator with active palette color schemes.
- **`html-server`**: High-performance Go web server with live reloading for quick local HTML/CSS previews.
- **`instrument-serif`**: Custom font derivation packaging Google's Instrument Serif.
- **`sf-pro`**: Custom font derivation packaging Apple's San Francisco Pro font family.
- **`plsfail`**: Diagnostic utility that runs a command repeatedly in a loop until it encounters an error.
- **`tuxedo`**: Rust-based `todo.txt` terminal UI client.

---

## Flake Templates & Developer Shell

### Developer Shell (`nix develop`)

Enter the complete development environment with Rust and Nix language servers:

```bash
# Enter the developer shell
nix develop

# Or automatically load with direnv:
direnv allow
```

**Included Toolchains**:
- **Rust**: `rustc`, `cargo`, `rust-analyzer`, `clippy`, `rustfmt`, `bacon`, `sea-orm-cli`
- **Nix**: `nixfmt`, `nil` (Nix language server), `alejandra`
- **Shell**: Unstable Fish 4+
- **Scaffolding**: `boilerplate`

### ESP32 Arduino Template (`esp32-arduino`)

Initialize an embedded microcontroller project anywhere:

```bash
mkdir my-project && cd my-project
nix flake init -t github:Ssnibles/NixConfig#esp32-arduino
direnv allow

# Initialize Espressif board core & indices
esp-init

# Build and flash sketch
esp-compile
esp-upload

# Generate LSP compile flags for Neovim / Clangd autocompletion
esp-gen-lsp
```

### Generic Dendritic Template (`generic`)

Scaffold a clean, minimal dendritic flake configuration:

```bash
mkdir my-flake && cd my-flake
nix flake init -t github:Ssnibles/NixConfig#generic
```

---

## Scaffolding with `boilerplate`

The `boilerplate` CLI automates the creation of new hosts, features, layers, and packages while following dendritic conventions:

```bash
# List all available module kinds and templates
boilerplate -l

# Scaffold a shared feature layer
boilerplate layer audio-equalizer

# Scaffold an application feature
boilerplate feature obsidian -t app

# Scaffold a new host configuration
boilerplate host server-node

# Scaffold custom packages
boilerplate package my-daemon -t python    # Python 3 binary script
boilerplate package my-crate -t rust       # Rust buildRustPackage derivation
boilerplate package custom-tool -t stdenv  # stdenvNoCC derivation
```

---

## Troubleshooting & Maintenance

### Evaluating Flake Outputs

Validate syntax and configuration evaluation before rebuilding:

```bash
NIXPKGS_ALLOW_UNFREE=1 nix flake check --impure
```

### System Rollbacks

If a rebuild introduces regressions, instantly revert to a previous generation:

```bash
# Roll back the running system
sudo nixos-rebuild switch --rollback

# Or select an earlier generation from the Limine boot menu on startup
```

### Systemd & Service Logs

Inspect background services and desktop daemons:

```bash
# Inspect boot errors detected on login
journalctl -b -p err

# View Vicinae launcher server logs
journalctl --user -u vicinae-server -f

# View Shikane display manager daemon logs
journalctl --user -u shikane -f

# Follow Wayland session output
journalctl --user -u wayland-session -f
```

---

## Learning Resources

Curated guides and references for mastering NixOS and dendritic flake architectures:

- 📖 [Nix Reference Manual](https://nix.dev/manual/nix/latest/) — Official documentation for Nix language semantics and primitives.
- 🐧 [NixOS Manual](https://nixos.org/manual/nixos/stable/) — Comprehensive guide for configuring NixOS system options and services.
- ⚡ [Zero to Nix](https://zero-to-nix.com/) — Modern, beginner-friendly introduction to flakes by Determinate Systems.
- 🧩 [Flake-Parts Documentation](https://flake.parts/) — Framework for composing modular, multi-system flake configurations.
- 🌳 [Dendritic Architecture Pattern](https://github.com/mightyiam/dendritic) — Design pattern enabling filesystem-as-module-tree composition.
- 🏠 [Hjem User Environment Manager](https://github.com/feel-co/hjem) — Lightweight, module-native user file management.
- 🔎 [Noogle](https://noogle.dev/) — Search Nix library functions (`lib.*`, `builtins.*`).
- 🔍 [NixOS Package & Option Search](https://search.nixos.org/) — Search packages and standard NixOS configuration options.

---

<div align="center">

*Configured and maintained by [Josh](https://github.com/Ssnibles).*

</div>
