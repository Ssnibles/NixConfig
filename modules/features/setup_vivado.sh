#!/usr/bin/env bash
# Exit immediately on errors
set -e

CONTAINER_NAME="vivado"
INSTALLER_FILE=""
SCALE_FACTOR=""
KEEP_EXISTING=false

print_usage() {
    echo "Usage: $0 -f <installer_bin_path> [options]"
    echo ""
    echo "Options:"
    echo "  -f, --file PATH        Path on your host to the AMD/Xilinx installer .bin file (Required)"
    echo "  -k, --keep            Do NOT recreate/delete the container; use the existing one"
    echo "  -s, --scale FACTOR    Installer scale factor for high DPI displays (e.g., 2)"
    echo "  -c, --name NAME      Custom distrobox name (Default: vivado)"
    echo "  -h, --help            Show this help message"
}

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--file)
            INSTALLER_FILE="$2"
            shift 2
            ;;
        -k|--keep)
            KEEP_EXISTING=true
            shift 1
            ;;
        -s|--scale)
            SCALE_FACTOR="$2"
            shift 2
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

# Validate required installer path
if [[ -z "$INSTALLER_FILE" ]]; then
    echo "Error: Missing required argument -f/--file" >&2
    print_usage
    exit 1
fi

# Convert installer path to absolute path
INSTALLER_FILE=$(realpath "$INSTALLER_FILE")
if [[ ! -f "$INSTALLER_FILE" ]]; then
    echo "Error: Installer file not found at: $INSTALLER_FILE" >&2
    exit 1
fi

# Flags required for GUI display rendering and raw USB passthrough to program boards
DISTROBOX_FLAGS="-e _JAVA_AWT_WM_NONREPARENTING=1 -e SWT_GTK3=0 -e XLIB_SKIP_ARGB_VISUALS=1 -e GDK_BACKEND=x11 --privileged -v /dev/bus/usb:/dev/bus/usb"

# Recreate or reuse the container
if [ "$KEEP_EXISTING" = true ]; then
    echo "=== [1/5] Keeping Existing Container ($CONTAINER_NAME) ==="
    if ! distrobox list | grep -q "^$CONTAINER_NAME "; then
        echo "Container '$CONTAINER_NAME' does not exist. Creating it anyway..."
        distrobox create --name "$CONTAINER_NAME" --image ubuntu:22.04 --additional-flags "$DISTROBOX_FLAGS"
    fi
else
    echo "=== [1/5] Removing Old Distrobox Container ($CONTAINER_NAME) ==="
    if distrobox list | grep -q "^$CONTAINER_NAME "; then
        distrobox stop "$CONTAINER_NAME" --yes || true
        distrobox rm "$CONTAINER_NAME" --yes || true
    fi
    echo "=== [2/5] Creating New Distrobox Container ($CONTAINER_NAME) ==="
    distrobox create --name "$CONTAINER_NAME" --image ubuntu:22.04 --additional-flags "$DISTROBOX_FLAGS"
fi

echo "=== [3/5] Installing/Verifying Dependencies inside Container ==="
distrobox enter "$CONTAINER_NAME" -- bash -c "
  sudo apt-get update && sudo apt-get upgrade -y
  sudo apt-get install -y \
    build-essential \
    libtinfo5 \
    libncurses5 \
    libx11-6 \
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    libftdi1 \
    libftdi1-2 \
    libusb-1.0-0-dev \
    libusb-0.1-4 \
    fxload \
    usbutils \
    python3 \
    libglu1-mesa \
    libglib2.0-0 \
    libsm6 \
    libice6 \
    libuuid1 \
    libxt6 \
    libxxf86vm1 \
    libxcb-xinerama0 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-randr0 \
    libxcb-render-util0 \
    libxcb-shape0 \
    libxcb-xfixes0 \
    libasound2 \
    zlib1g \
    zlib1g-dev \
    coreutils \
    locales
  sudo locale-gen en_US.UTF-8
"

echo "=== [4/5] Executing the Vivado Installer ==="
ENV_VARS="export LANG=en_US.UTF-8 && export LC_ALL=en_US.UTF-8"
if [[ -n "$SCALE_FACTOR" ]]; then
    ENV_VARS="$ENV_VARS && export XINSTALLER_SCALE=$SCALE_FACTOR"
fi

distrobox enter "$CONTAINER_NAME" -- bash -c "
  $ENV_VARS
  chmod +x '$INSTALLER_FILE'
  '$INSTALLER_FILE'
"

echo "=== [5/5] Setup Complete! Entering Distrobox Container ==="
distrobox enter "$CONTAINER_NAME"
