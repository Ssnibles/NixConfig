#!/usr/bin/env bash
# =============================================================================
# WRAMP Development Container Setup
# =============================================================================
# Creates (or recreates) a Distrobox / Podman Ubuntu 22.04 container and
# installs the complete WRAMP (Waikato RISC Architecture MicroProcessor)
# toolchain, simulator and utilities published by wandwramp.
#
# Installed inside the container (staged in /opt/wramp, symlinked onto PATH):
#   wasm, wlink, wobj   assembler, linker and object viewer (toolchain V3.0.1)
#   wcc, wcpp, rcc      WRAMP C compiler (wcc 1.1.1.1)
#   wsim                Mono/C# WinForms CPU simulator (v3.3.4)
#   remote, down        serial terminal for physical Basys3 boards (3.0.0)
#   trim                .srec -> Vivado .mem converter (3.0.0)
#   WRAMPmon            monitor firmware, built from source (monitor.mem)
#
# Usage: ./setup_wramp.sh [options]
# =============================================================================
set -e

CONTAINER_NAME="wramp"
KEEP_EXISTING=false

# Fully-qualified so Podman/Docker never prompt to disambiguate the registry.
IMAGE="docker.io/library/ubuntu:22.04"

# Pull a container image without any interactive prompt.
# distrobox create asks "Do you want to pull the image now? [Y/n]" when the
# image is missing; pre-pulling here avoids that.
pull_image() {
    local image="$1"
    if podman image exists "$image" 2>/dev/null; then
        return 0
    fi
    if command -v podman >/dev/null 2>&1; then
        podman pull "$image"
    elif command -v docker >/dev/null 2>&1; then
        docker pull "$image"
    else
        echo "Warning: neither podman nor docker found; letting distrobox pull $image" >&2
    fi
}

# Pinned wandwramp release artefacts.
WRAMP_TOOLCHAIN_URL="https://github.com/wandwramp/toolchain/releases/download/V3.0.1/toolchain-3.0.1.zip"
WRAMP_WCC_URL="https://github.com/wandwramp/wcc/releases/download/1.1.1.1/wcc-1.1.1.1.zip"
WRAMP_REMOTE_URL="https://github.com/wandwramp/remote/releases/download/3.0.0/remote-3.0.0.zip"
WRAMP_WSIM_URL="https://github.com/wandwramp/wsim/releases/download/v3.3.4/wsim-3.3.4.zip"
WRAMP_TRIM_URL="https://github.com/wandwramp/trim/releases/download/3.0.0/trim"
WRAMP_REMOTERC_URL="https://raw.githubusercontent.com/wandwramp/remote/3.0.0/remoterc.dfl"

print_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -k, --keep          Do NOT recreate/delete the container; use the existing one"
    echo "  -c, --name NAME     Custom distrobox name (Default: wramp)"
    echo "  -h, --help          Show this help message"
}

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -k|--keep)
            KEEP_EXISTING=true
            shift 1
            ;;
        -c|--name)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "Error: Unknown option $1" >&2
            print_usage
            exit 1
            ;;
    esac
done

# Flags required for GUI display rendering and optional USB passthrough to a
# physical Basys3 board (on-board USB-serial / JTAG programmer).
DISTROBOX_FLAGS="-e GDK_BACKEND=x11 --privileged -v /dev/bus/usb:/dev/bus/usb"

# Recreate or reuse the container
if [ "$KEEP_EXISTING" = true ]; then
    echo "=== [1/4] Keeping Existing Container ($CONTAINER_NAME) ==="
    if ! distrobox list | grep -q "^$CONTAINER_NAME "; then
        echo "Container '$CONTAINER_NAME' does not exist. Creating it anyway..."
        pull_image "$IMAGE"
        distrobox create --name "$CONTAINER_NAME" --image "$IMAGE" --additional-flags "$DISTROBOX_FLAGS"
    fi
else
    echo "=== [1/4] Removing Old Distrobox Container ($CONTAINER_NAME) ==="
    if distrobox list | grep -q "^$CONTAINER_NAME "; then
        distrobox stop "$CONTAINER_NAME" --yes || true
        distrobox rm "$CONTAINER_NAME" --yes || true
    fi
    echo "=== [2/4] Creating New Distrobox Container ($CONTAINER_NAME) ==="
    pull_image "$IMAGE"
    distrobox create --name "$CONTAINER_NAME" --image "$IMAGE" --additional-flags "$DISTROBOX_FLAGS"
fi

echo "=== [3/4] Installing WRAMP Toolchain, Simulator & Utilities ==="
distrobox enter "$CONTAINER_NAME" -- bash -c '
  set -e
  export DEBIAN_FRONTEND=noninteractive

  sudo apt-get update
  # wsim is a Mono/C# WinForms GUI; the remaining tools are native binaries.
  # libncurses5/libtinfo5 satisfy the prebuilt remote binary, while fontconfig
  # and DejaVu fonts let the WinForms GUI render text.
  sudo apt-get install -y \
    make \
    unzip \
    wget \
    ca-certificates \
    git \
    mono-complete \
    libgdiplus \
    libncurses5 \
    libtinfo5 \
    fontconfig \
    fonts-dejavu-core

  # Fetch the pinned wandwramp releases
  rm -rf /tmp/wramp-dl
  mkdir -p /tmp/wramp-dl
  cd /tmp/wramp-dl
  wget -q -O toolchain.zip "'"$WRAMP_TOOLCHAIN_URL"'"
  wget -q -O wcc.zip       "'"$WRAMP_WCC_URL"'"
  wget -q -O remote.zip    "'"$WRAMP_REMOTE_URL"'"
  wget -q -O wsim.zip      "'"$WRAMP_WSIM_URL"'"
  wget -q -O trim          "'"$WRAMP_TRIM_URL"'"
  wget -q -O remoterc.dfl  "'"$WRAMP_REMOTERC_URL"'"

  # Stage the toolchain under /opt/wramp
  sudo rm -rf /opt/wramp
  sudo mkdir -p /opt/wramp/bin /opt/wramp/wsim /opt/wramp/WRAMPmon
  sudo unzip -oq toolchain.zip -d /opt/wramp/bin
  sudo unzip -oq wcc.zip       -d /opt/wramp/bin
  sudo unzip -oq remote.zip    -d /opt/wramp/bin
  sudo unzip -oq wsim.zip      -d /opt/wramp/wsim
  sudo install -m 0755 trim /opt/wramp/bin/trim
  install -m 0644 remoterc.dfl "$HOME/.remoterc.dfl"
  sudo chmod 0755 /opt/wramp/bin/* /opt/wramp/wsim/RexSimulatorGui.exe

  # The released wsim launcher has no shebang and resolves paths from $0, so it
  # breaks when invoked from PATH. Replace it with a proper launcher.
  # MONO_WINFORMS_XIM_STYLE=disabled avoids a Mono 6.x WinForms segfault in
  # Xutf8LookupString while translating key events (X11Keyboard.SetupXIM).
  sudo tee /opt/wramp/wsim/wsim >/dev/null <<WSIM
#!/bin/sh
export MONO_WINFORMS_XIM_STYLE=disabled
exec mono /opt/wramp/wsim/RexSimulatorGui.exe "\$@"
WSIM
  sudo chmod 0755 /opt/wramp/wsim/wsim

  # Expose the toolchain on PATH
  for tool in wasm wlink wobj wcc wcpp rcc remote down trim; do
    sudo ln -sf "/opt/wramp/bin/$tool" "/usr/local/bin/$tool"
  done
  sudo ln -sf /opt/wramp/wsim/wsim /usr/local/bin/wsim

  # WRAMPmon has no release artefacts; build the monitor firmware from source.
  rm -rf /tmp/WRAMPmon
  git clone -q --depth 1 https://github.com/wandwramp/WRAMPmon.git /tmp/WRAMPmon
  if make -C /tmp/WRAMPmon; then
    sudo install -m 0644 /tmp/WRAMPmon/monitor.srec /tmp/WRAMPmon/monitor.mem /opt/wramp/WRAMPmon/
  else
    echo "WARNING: WRAMPmon build failed; monitor.mem was not produced." >&2
  fi

  echo "Mono runtime: $(mono --version 2>/dev/null | head -n 1)"
  echo "WRAMP tooling installed in /opt/wramp:"
  ls /opt/wramp/bin
'

echo "=== [4/4] Setup Complete! Entering Distrobox Container ==="
distrobox enter "$CONTAINER_NAME"
