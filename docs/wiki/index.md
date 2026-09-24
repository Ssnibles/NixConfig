# NixConfig Feature Wiki & User Guide

Welcome to the **NixConfig Feature Wiki**. This collection of guides provides in-depth documentation, architecture references, and workflow manuals for the subsystems, tools, and environments configured in this repository.

---

## Wiki Articles

### Core Desktop & Shell Frameworks
- **[Wayland Compositors Guide](compositors.md)**  
  Architecture and configuration for MangoWC (DWM-style tiling, gestures, OCR screenshots), Niri (infinite scrollable tiling), Hyprland (Lua configuration), Shikane multi-monitor display daemon, and Vicinae application launcher.
- **[Quickshell Desktop Shell Bar](quickshell.md)**  
  Modular QML desktop shell architecture: singletons (`Colors.qml`, `Config.qml`), status bars (`bar.qml`, `niri-bar.qml`), multi-compositor routing (`WmService.qml`), Command Centre dashboard, session lock screen, and notification daemon.
- **[Terminal Workflow: Kitty, Tmux, Yazi & Pet](terminal-workflow.md)**  
  Terminal stack optimisations: Kitty in single-instance shared GPU memory mode, Tmux multiplexer with Sesh and floating popups, Yazi file manager, Pet fuzzy snippet picker (`Ctrl+P`), and Fish shell with cached FZF directory indexing.

### Developer Toolchains & Editors
- **[Declarative Neovim & Lua Plugins](neovim.md)**  
  Declarative Neovim built with `nvf` and customised via modular Lua plugins in `modules/features/nvim-src/`. Covers language servers (`qmlls` and `zls` wrappers), Blink.cmp, Conform formatters, Gitsigns, Oil image pasting, and floating `jjui` integration.
- **[Jujutsu (jj) Cheat Sheet](jujutsu.md)**  
  Complete reference for the Git-compatible Jujutsu VCS: Git vs jj mental models, daily workflows, bookmarks, remote push/pull flows, history rewriting, conflict resolution, and shell aliases.

### Artificial Intelligence & Autonomous Agents
- **[AI Development Tools: Pi Coding Agent & Hermes](ai-tools.md)**  
  Terminal AI workflows: Pi coding agent harness (`pi.nix`) with prompt extensions and Bubblewrap sandboxing (`jail.nix`), and Hermes AI agent configured with remote homeserver Ollama inference offloading over Tailscale.

### Hardware, Embedded & Engineering
- **[ESP32 & Arduino Development](esp32-arduino.md)**  
  Toolchain and workflow for programming Espressif ESP32 microcontrollers using `arduino-cli`, `esptool`, workflow scripts (`esp-init`, `esp-compile`, `esp-upload`, `esp-monitor`), and automatic Neovim / Clangd LSP compilation database generation (`esp-gen-lsp`).
- **[AMD Vivado FPGA Container Environment](vivado-fpga.md)**  
  Containerised workflow for running AMD Vivado Design Suite inside an isolated Ubuntu 22.04 Distrobox container with full Wayland/X11 GUI passthrough and JTAG USB programming permissions.

### Media, Audio & Applications
- **[Media, Document Viewer & Audio Stack](media-audio.md)**  
  High-performance media tools: MPV video player with Vulkan `gpu-next` pipeline and custom scripts (`modernz`, `thumbfast`), Zathura PDF reader with theme-aware dark mode and SyncTeX Neovim jumping, PipeWire low-latency audio, and `ytplay`.
- **[Firefox & Sidebery Customisation](firefox.md)**  
  Guide for customising Firefox Developer Edition native UI (`userChrome.css`), Sidebery vertical tab bar (`userContent.css`), offline startpage WebExtension, and Helium browser alternative.
- **[Gaming, Steam & DualSense Controllers](gaming.md)**  
  Gaming configuration on NixOS: Steam with Millennium UI skinning overlay, Gamescope sandboxed micro-compositor sessions, MangoHud performance overlay, and PlayStation 5 DualSense controller pairing via `dualsense-pair`.

### Networking & Synchronisation
- **[Networking, Tailscale & Syncthing Synchronisation](networking-sync.md)**  
  Encrypted mesh networking with Tailscale, battery-optimised peer-to-peer folder synchronisation with Syncthing, systemd-resolved DNS-over-TLS, and iwd wireless configuration with Opportunistic Wireless Encryption.

---

## Configuration Map

| Subsystem | Primary Nix Module Location | Custom Config / Source | Wiki Guide |
| :--- | :--- | :--- | :--- |
| **Compositors** | `modules/features/desktop-env/` | `mangowc/`, `niri/`, `hyprland/`, `shikane/` | [compositors.md](compositors.md) |
| **Quickshell UI** | `modules/features/desktop-env/quickshell/` | `modules/features/desktop-env/quickshell/config/` | [quickshell.md](quickshell.md) |
| **Terminal & Multiplexer** | `modules/features/apps/kitty.nix`, `modules/features/shell/` | `modules/packages/pet/`, `tmux.nix`, `shell.nix` | [terminal-workflow.md](terminal-workflow.md) |
| **Declarative Neovim** | `modules/features/apps/neovim.nix` | `modules/features/nvim-src/` | [neovim.md](neovim.md) |
| **Jujutsu (jj)** | `modules/features/shell/cli.nix` | `~/.config/jj/config.toml` | [jujutsu.md](jujutsu.md) |
| **Pi Agent & Hermes** | `modules/features/apps/pi-agent.nix`, `hermes.nix` | `~/.hermes/config.yaml`, `pi.nix` | [ai-tools.md](ai-tools.md) |
| **ESP32 & Arduino** | `modules/features/apps/development.nix` | `templates/esp32-arduino/` | [esp32-arduino.md](esp32-arduino.md) |
| **AMD Vivado FPGA** | `modules/features/apps/vivado.nix` | `assets/setup_vivado.sh` | [vivado-fpga.md](vivado-fpga.md) |
| **Media & Audio** | `modules/features/apps/media.nix`, `system/pipewire.nix` | `mpv.conf`, `zathurarc` | [media-audio.md](media-audio.md) |
| **Firefox & Helium** | `modules/features/apps/firefox/`, `apps/helium.nix` | `userChrome.css`, `userContent.css` | [firefox.md](firefox.md) |
| **Gaming & PS5** | `modules/features/apps/gaming.nix` | `modules/packages/dualsense-pair/` | [gaming.md](gaming.md) |
| **Tailscale & Syncthing** | `modules/features/system/tailscale.nix`, `syncthing.nix` | Tailscale client, Syncthing service | [networking-sync.md](networking-sync.md) |
