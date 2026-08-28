{
  description = "ESP32 Arduino development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSystem = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forEachSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          espInit = pkgs.writeShellScriptBin "esp-init" ''
            DEVENV_ROOT="''${DEVENV_ROOT:-$PWD}"
            echo "⚡ Updating Arduino board index for ESP32..."
            ${pkgs.arduino-cli}/bin/arduino-cli core update-index --config-file "$DEVENV_ROOT/arduino-cli.yaml"
            echo "📦 Installing ESP32 board core (esp32:esp32)..."
            ${pkgs.arduino-cli}/bin/arduino-cli core install esp32:esp32 --config-file "$DEVENV_ROOT/arduino-cli.yaml"
            echo "✅ ESP32 core installation complete!"
          '';

          espBoards = pkgs.writeShellScriptBin "esp-boards" ''
            DEVENV_ROOT="''${DEVENV_ROOT:-$PWD}"
            echo "🔍 Searching for connected microcontrollers..."
            ${pkgs.arduino-cli}/bin/arduino-cli board list --config-file "$DEVENV_ROOT/arduino-cli.yaml"
          '';

          espCompile = pkgs.writeShellScriptBin "esp-compile" ''
            DEVENV_ROOT="''${DEVENV_ROOT:-$PWD}"
            FQBN=''${1:-esp32:esp32:esp32}
            echo "🔨 Compiling sketch for board: $FQBN..."
            ${pkgs.arduino-cli}/bin/arduino-cli compile --config-file "$DEVENV_ROOT/arduino-cli.yaml" --fqbn "$FQBN" "$DEVENV_ROOT/src/src.ino"
          '';

          espUpload = pkgs.writeShellScriptBin "esp-upload" ''
            DEVENV_ROOT="''${DEVENV_ROOT:-$PWD}"
            PORT="$1"
            FQBN=''${2:-esp32:esp32:esp32}
            if [ -z "$PORT" ]; then
              PORT=$(ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null | head -n 1)
            fi

            if [ -z "$PORT" ]; then
              echo "❌ No serial port detected! Please specify serial port (e.g. esp-upload /dev/ttyUSB0)."
              exit 1
            fi

            echo "🚀 Flashing ESP32 on $PORT using $FQBN..."
            ${pkgs.arduino-cli}/bin/arduino-cli upload --config-file "$DEVENV_ROOT/arduino-cli.yaml" -p "$PORT" --fqbn "$FQBN" "$DEVENV_ROOT/src/src.ino"
          '';

          espMonitor = pkgs.writeShellScriptBin "esp-monitor" ''
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
            ${pkgs.picocom}/bin/picocom -b "$BAUD" "$PORT"
          '';

          espGenLsp = pkgs.writeShellScriptBin "esp-gen-lsp" ''
            DEVENV_ROOT="''${DEVENV_ROOT:-$PWD}"
            FQBN=''${1:-esp32:esp32:esp32}
            echo "⚙️ Generating compilation database (compile_commands.json) for $FQBN..."
            ${pkgs.arduino-cli}/bin/arduino-cli compile --config-file "$DEVENV_ROOT/arduino-cli.yaml" --fqbn "$FQBN" --only-compilation-database "$DEVENV_ROOT/src/src.ino"
            
            BUILD_PATH="$DEVENV_ROOT/src/build"
            if [ -f "$BUILD_PATH/compile_commands.json" ]; then
              cp "$BUILD_PATH/compile_commands.json" "$DEVENV_ROOT/compile_commands.json"
              echo "✨ Saved compile_commands.json to $DEVENV_ROOT/compile_commands.json"
            else
              echo "⚠️ Could not locate generated compile_commands.json in $BUILD_PATH"
            fi
          '';
        in
        {
          default = pkgs.mkShell {
            name = "esp32-arduino-shell";

            buildInputs = with pkgs; [
              arduino-cli
              esptool
              python3
              python3Packages.pyserial
              picocom
              clang-tools
              
              espInit
              espBoards
              espCompile
              espUpload
              espMonitor
              espGenLsp
            ];

            ARDUINO_BOARD_MANAGER_ADDITIONAL_URLS = "https://espressif.github.io/arduino-esp32/package_esp32_index.json";
            ESP32_DEFAULT_FQBN = "esp32:esp32:esp32";

            shellHook = ''
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
          };
        }
      );
    };
}
