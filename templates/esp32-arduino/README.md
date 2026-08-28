# ESP32 Arduino Development Environment

This directory provides a complete, nix-backed development shell for programming ESP32 series microcontrollers using the Arduino framework, `arduino-cli`, `esptool`, and Clangd/Neovim LSP integration.

---

## 🚀 Quick Start & New Project Setup

### 1. Initialize a New Project

To create a new ESP32 project anywhere on your system:

```bash
mkdir my-esp32-project
cd my-esp32-project
nix flake init -t github:Ssnibles/NixConfig#esp32-arduino
# or locally from NixConfig directory:
# nix flake init -t /home/josh/NixConfig#esp32-arduino
```

### 2. Workflow & Commands

1. **Activate Development Shell**:
   ```bash
   nix develop
   # or with direnv:
   direnv allow
   ```

2. **Initialize Board Core (First Time Setup)**:
   ```bash
   esp-init
   ```
   *This downloads Espressif board package indices and installs `esp32:esp32` core.*

3. **Check Connected Microcontrollers**:
   ```bash
   esp-boards
   ```

4. **Compile Sketch**:
   ```bash
   esp-compile
   ```

5. **Generate LSP Compilation Database (for Neovim / Clangd Autocompletion)**:
   ```bash
   esp-gen-lsp
   ```

6. **Flash Microcontroller**:
   ```bash
   esp-upload /dev/ttyUSB0
   # or if using native USB (e.g., ESP32-S3/C3):
   esp-upload /dev/ttyACM0
   ```

7. **Open Serial Monitor**:
   ```bash
   esp-monitor /dev/ttyUSB0 115200
   ```

---

## 🛠 Available Helper Commands

| Command | Description |
|---|---|
| `esp-init` | Update board manager index & install `esp32:esp32` core package |
| `esp-boards` | List connected microcontrollers and identified serial ports |
| `esp-compile [FQBN]` | Compile `src/src.ino` (Default FQBN: `esp32:esp32:esp32`) |
| `esp-upload [PORT] [FQBN]` | Flash compiled binary to connected ESP32 board |
| `esp-monitor [PORT] [BAUD]` | Launch `picocom` serial monitor (Exit: `Ctrl+A` then `Ctrl+Q`) |
| `esp-gen-lsp [FQBN]` | Build `compile_commands.json` for Clangd autocomplete & diagnostics |

---

## 🎯 Target Boards & FQBN Examples

To target specific ESP32 variants, pass the appropriate Fully Qualified Board Name (FQBN) to `esp-compile` or `esp-upload`:

- **Generic ESP32 Dev Module**: `esp32:esp32:esp32` (default)
- **ESP32-S3 Dev Module**: `esp32:esp32:esp32s3`
- **ESP32-C3 Dev Module**: `esp32:esp32:esp32c3`
- **ESP32-S2 Dev Module**: `esp32:esp32:esp32s2`
- **NodeMCU-32S**: `esp32:esp32:nodemcu-32s`

You can search all available board target names with:
```bash
arduino-cli board listall esp32
```
