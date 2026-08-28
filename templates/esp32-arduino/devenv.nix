# =============================================================================
# ESP32 Arduino Development Environment (devenv)
# =============================================================================
{ pkgs, lib, config, inputs, ... }:

{
  # ── Environment Variables ──────────────────────────────────────────────────
  env = {
    ARDUINO_BOARD_MANAGER_ADDITIONAL_URLS = "https://espressif.github.io/arduino-esp32/package_esp32_index.json";
    ESP32_DEFAULT_FQBN = "esp32:esp32:esp32";
  };

  # ── Package Toolchain ──────────────────────────────────────────────────────
  packages = with pkgs; [
    arduino-cli
    esptool
    python3
    python3Packages.pyserial
    picocom
    clang-tools
  ];

  # ── Helper Commands & Workflow Scripts ─────────────────────────────────────
  scripts = {
    "esp-init".exec = ''
      echo "⚡ Updating Arduino board index for ESP32..."
      arduino-cli core update-index --config-file "$DEVENV_ROOT/arduino-cli.yaml"
      echo "📦 Installing ESP32 board core (esp32:esp32)..."
      arduino-cli core install esp32:esp32 --config-file "$DEVENV_ROOT/arduino-cli.yaml"
      echo "✅ ESP32 core installation complete!"
    '';

    "esp-boards".exec = ''
      echo "🔍 Searching for connected microcontrollers..."
      arduino-cli board list --config-file "$DEVENV_ROOT/arduino-cli.yaml"
    '';

    "esp-compile".exec = ''
      FQBN=''${1:-$ESP32_DEFAULT_FQBN}
      echo "🔨 Compiling sketch for board: $FQBN..."
      arduino-cli compile --config-file "$DEVENV_ROOT/arduino-cli.yaml" --fqbn "$FQBN" "$DEVENV_ROOT/src/sketch.ino"
    '';

    "esp-upload".exec = ''
      PORT="$1"
      FQBN=''${2:-$ESP32_DEFAULT_FQBN}
      if [ -z "$PORT" ]; then
        PORT=$(ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null | head -n 1)
      fi

      if [ -z "$PORT" ]; then
        echo "❌ No serial port detected! Please specify serial port (e.g. esp-upload /dev/ttyUSB0)."
        exit 1
      fi

      echo "🚀 Flashing ESP32 on $PORT using $FQBN..."
      arduino-cli upload --config-file "$DEVENV_ROOT/arduino-cli.yaml" -p "$PORT" --fqbn "$FQBN" "$DEVENV_ROOT/src/sketch.ino"
    '';

    "esp-monitor".exec = ''
      PORT="$1"
      BAUD=''${2:-115200}
      if [ -z "$PORT" ]; then
        PORT=$(ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null | head -n 1)
      fi

      if [ -z "$PORT" ]; then
        echo "❌ No serial port detected! Please specify serial port (e.g. esp-monitor /dev/ttyUSB0)."
        exit 1
      fi

      echo "📺 Opening serial monitor on $PORT @ $BAUD baud (Press Ctrl+A then Ctrl+Q to exit)..."
      picocom -b "$BAUD" "$PORT"
    '';

    "esp-gen-lsp".exec = ''
      FQBN=''${1:-$ESP32_DEFAULT_FQBN}
      echo "⚙️ Generating compilation database (compile_commands.json) for $FQBN..."
      arduino-cli compile --config-file "$DEVENV_ROOT/arduino-cli.yaml" --fqbn "$FQBN" --only-compilation-database "$DEVENV_ROOT/src/sketch.ino"
      
      BUILD_PATH="$DEVENV_ROOT/src/build"
      if [ -f "$BUILD_PATH/compile_commands.json" ]; then
        cp "$BUILD_PATH/compile_commands.json" "$DEVENV_ROOT/compile_commands.json"
        echo "✨ Saved compile_commands.json to $DEVENV_ROOT/compile_commands.json"
      else
        echo "⚠️ Could not locate generated compile_commands.json in $BUILD_PATH"
      fi
    '';
  };

  # ── Shell Entry Hook ───────────────────────────────────────────────────────
  enterShell = ''
    echo "====================================================================="
    echo "⚡ ESP32 Arduino Development Environment"
    echo "====================================================================="
    echo " Commands available:"
    echo "   esp-init      - Download board index & install ESP32 core"
    echo "   esp-boards    - List connected microcontrollers & serial ports"
    echo "   esp-compile   - Compile sketch (optional: pass custom FQBN)"
    echo "   esp-upload    - Flash compiled sketch to board (e.g. esp-upload /dev/ttyUSB0)"
    echo "   esp-monitor   - Open serial terminal (e.g. esp-monitor /dev/ttyUSB0 115200)"
    echo "   esp-gen-lsp   - Generate compile_commands.json for Clangd / Neovim LSP"
    echo "====================================================================="
  '';
}
