# ESP32 & Arduino Microcontroller Development Guide

This guide details how to develop software for Espressif ESP32 series microcontrollers (ESP32, ESP32-S2, ESP32-S3, ESP32-C3, NodeMCU-32S) using the Arduino framework, `arduino-cli`, `esptool`, `devenv`, and Neovim / Clangd LSP integration in `NixConfig`.

---

## ⚡ Quick Start: Creating a New Project

You can instantiate a ready-to-use ESP32 project from anywhere on your system using the flake template:

```bash
mkdir my-esp32-project
cd my-esp32-project
nix flake init -t /home/josh/NixConfig#esp32-arduino
# or via remote GitHub flake URL:
# nix flake init -t github:Ssnibles/NixConfig#esp32-arduino
```

---

## 🛠️ Step-by-Step Workflow

### 1. Activate Development Shell
Enter the nix development shell (or rely on `direnv`):
```bash
nix develop
# or with direnv:
direnv allow
```

### 2. Download Board Index & Install ESP32 Core
Run `esp-init` (first time setup per workspace):
```bash
esp-init
```
*This updates the `arduino-cli` board manager using the Espressif package URL (`https://espressif.github.io/arduino-esp32/package_esp32_index.json`) and installs the `esp32:esp32` core.*

### 3. Check Connected Serial Devices
Plug in your ESP32 board via USB and list connected boards:
```bash
esp-boards
```

### 4. Compile the Sketch
Compile `src/src.ino`:
```bash
esp-compile
```

### 5. Generate LSP Compilation Database for Neovim / Clangd
Generate `compile_commands.json` in your workspace root so Neovim LSP immediately recognizes ESP32 Arduino libraries, includes, and pins:
```bash
esp-gen-lsp
```

### 6. Flash the Microcontroller
Flash the compiled binary to your board:
```bash
esp-upload /dev/ttyUSB0
# Or for native USB devices (ESP32-S3 / ESP32-C3):
esp-upload /dev/ttyACM0
```

### 7. Monitor Serial Output
Launch the `picocom` terminal emulator @ 115200 baud:
```bash
esp-monitor /dev/ttyUSB0 115200
```
*(To exit `picocom`, press **`Ctrl+A`** then **`Ctrl+Q`**).*

---

## 📋 Helper Commands Summary

| Command | Description |
|---|---|
| `esp-init` | Update board manager index and install `esp32:esp32` core |
| `esp-boards` | List connected microcontrollers and identified serial ports |
| `esp-compile [FQBN]` | Compile `src/sketch.ino` (Default FQBN: `esp32:esp32:esp32`) |
| `esp-upload [PORT] [FQBN]` | Flash compiled binary to connected ESP32 board |
| `esp-monitor [PORT] [BAUD]` | Launch `picocom` serial monitor |
| `esp-gen-lsp [FQBN]` | Build `compile_commands.json` for Clangd autocomplete & diagnostics |

---

## 🎯 Target Boards & FQBN Reference

Pass custom Fully Qualified Board Names (FQBN) to `esp-compile` or `esp-upload` for specific chip variants:

- **Generic ESP32 Dev Module**: `esp32:esp32:esp32` (default)
- **ESP32-S3 Dev Module**: `esp32:esp32:esp32s3`
- **ESP32-C3 Dev Module**: `esp32:esp32:esp32c3`
- **ESP32-S2 Dev Module**: `esp32:esp32:esp32s2`
- **NodeMCU-32S**: `esp32:esp32:nodemcu-32s`

To search all installed ESP32 board targets:
```bash
arduino-cli board listall esp32
```

---

## 🔐 System Permissions & Group Membership

Access to USB-to-serial chips (CP210x, CH340, FT232, native USB CDC) on Linux requires serial port permissions. In `NixConfig`, the primary user account (`josh`) is automatically added to the `dialout` system group in `modules/features/system/user.nix`:

```nix
users.users.${config.username}.extraGroups = [
  "networkmanager"
  "wheel"
  "plugdev"
  "dialout"
];
```
No `sudo` is required to flash or monitor devices!
