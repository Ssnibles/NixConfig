# NixConfig Feature Wiki & User Guide

Welcome to the **NixConfig Feature Wiki**. This collection of guides provides in-depth documentation, architecture references, and workflow instructions for the key features, development environments, and desktop tools configured in this repository.

---

## 📚 Wiki Articles

### ⚡ Embedded & Microcontroller Development
- **[ESP32 & Arduino Development](esp32-arduino.md)**  
  Complete guide for programming ESP32 series microcontrollers using `arduino-cli`, `esptool`, `devenv`, helper workflow scripts (`esp-init`, `esp-compile`, `esp-upload`, `esp-monitor`), and automatic Neovim / Clangd LSP compilation database generation (`esp-gen-lsp`).

### 🎨 Desktop Environment & UI Frameworks
- **[Quickshell Desktop Shell Bar](quickshell.md)**  
  Architecture reference for the Quickshell QML framework. Documents singletons (`Colors.qml`, `Config.qml`), status bars (`niri-bar.qml`, `bar.qml`), backend routers (`WmService.qml`, `NiriService.qml`), Command Center dashboard, lock screen (`LockScreen.qml`), and IPC controls.
- **[Wayland Compositors](compositors.md)**  
  Guide to configured Wayland compositors: Hyprland (with noctalia shell), Niri (scrollable tiling), and MangoWC (DWM-inspired minimal compositor).

### 🛠️ Developer Toolchains & Applications
- **[Declarative Neovim & Lua Plugins](neovim.md)**  
  Overview of Neovim built with `nvf` and customized via Lua plugins in `modules/features/nvim-src/`. Covers LSP integration, C/C++ include flag generation (`GenerateCompileFlags`), inlay hints, and file navigation.
- **[AMD Vivado FPGA Environment](vivado-fpga.md)**  
  Setup and usage guide for running AMD Vivado Design Suite 2024.1 in an isolated Distrobox Ubuntu 22.04 container with GUI passthrough and wrapper launch scripts.
- **[Firefox & Sidebery Customization](firefox.md)**  
  Guide for customizing Firefox native UI (`userChrome.css`), WebExtensions/Sidebery (`userContent.css`), theme color tokens (`colors.css`), and using the Browser Toolbox inspector.

### 🎮 Gaming & Hardware
- **[Gaming, Steam & DualSense Controllers](gaming.md)**  
  Configuration guide for gaming on NixOS. Covers Steam with Millennium skinning framework, Gamescope composited sessions, MangoHud performance overlay, and Sony PlayStation 5 DualSense / DualSense Edge kernel driver (`hid-playstation`) & udev setup.

---

## 🔗 Quick Links & Configuration Map

| Feature Area | Primary Nix Module Location | Custom Config / Source | Wiki Guide |
|---|---|---|---|
| **ESP32 / Arduino** | `modules/features/apps/development.nix` | `templates/esp32-arduino/` | [esp32-arduino.md](esp32-arduino.md) |
| **Quickshell** | `modules/features/desktop-env/quickshell/` | `modules/features/desktop-env/quickshell/config/` | [quickshell.md](quickshell.md) |
| **Firefox & Sidebery** | `modules/features/apps/firefox/` | `modules/features/apps/firefox/userChrome.css` | [firefox.md](firefox.md) |
| **Vivado FPGA** | `modules/features/apps/vivado.nix` | `assets/setup_vivado.sh` | [vivado-fpga.md](vivado-fpga.md) |
| **Neovim** | `modules/features/apps/neovim.nix` | `modules/features/nvim-src/` | [neovim.md](neovim.md) |
| **Wayland Compositors** | `modules/features/desktop-env/` | `hyprland/`, `niri/`, `mangowc/` | [compositors.md](compositors.md) |
| **Gaming & PS5 Controllers** | `modules/features/apps/gaming.nix` | `modules/packages/dualsense-pair/` | [gaming.md](gaming.md) |
