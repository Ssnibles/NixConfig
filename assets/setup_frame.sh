#!/usr/bin/env bash
# =============================================================================
# Frame App Remote Desktop Container Setup
# =============================================================================
# Creates (or recreates) a Distrobox / Podman Ubuntu 24.04 container and
# installs the Nutanix Frame App desktop client together with the runtime
# libraries it needs: GTK/Chromium, audio (PulseAudio/PipeWire), VA-API/Mesa
# hardware video decode, smart-card support and USB device redirection.
#
# The upstream .deb ships a post-install script that expects a booted systemd
# host with a live udev daemon. Neither exists inside a rootless Distrobox
# container, so that script aborts dpkg mid-configure. This setup repacks the
# .deb with a container-safe postinst (stage the vendor USB rules, then exit 0)
# before installing it, so the package ends up fully configured.
#
# The client version is not pinned: Frame publishes a per-architecture
# manifest pointing at the current .deb, which is resolved at run time.
#
# Usage: ./setup_frame.sh [options]
# =============================================================================
set -euo pipefail

CONTAINER_NAME="frame"
KEEP_EXISTING=false
IMAGE="docker.io/library/ubuntu:24.04"

FRAME_MANIFEST_URL="https://downloads.console.nutanix.com/terminal/manifest-linux64.json"

# Extra packages that the .deb either leaves to Recommends or does not declare
# but that a containerised desktop client needs:
#   libglib2.0-bin   satisfies the "kde-cli-tools | ... | libglib2.0-bin"
#                    alternative so apt does not drag in the whole of KDE
#   libpulse0        PulseAudio client (host PipeWire socket is shared)
#   libasound2t64    ALSA client fallback
#   mesa/VA-API      hardware video decode for Intel/AMD GPUs
#   fontconfig/fonts text rendering for the Electron UI
#   curl             fetches the .deb from inside the container
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/frame-setup"

print_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -k, --keep          Do NOT recreate/delete the container; use the existing one"
    echo "  -c, --name NAME     Custom distrobox name (Default: frame)"
    echo "  -h, --help          Show this help message"
}

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -k | --keep)
            KEEP_EXISTING=true
            shift 1
            ;;
        -c | --name)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        -h | --help)
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

# Pull a container image without any interactive prompt. distrobox create asks
# "Do you want to pull the image now? [Y/n]" when the image is missing;
# pre-pulling here avoids that.
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

# Assemble the extra flags handed to the container manager.
#   --privileged            required for USB device redirection
#   /dev/bus/usb rslave     forward USB devices (and hotplug) into the session
#   /dev/dri                DRM render nodes for VA-API hardware decode
# NVIDIA's --nvidia integration is deliberately not used: it scans
# /run/host/usr/lib for driver files, which does not exist on NixOS, and the
# host GL libraries under /run/opengl-driver are not ABI-compatible with the
# Ubuntu container. Frame falls back to software rendering (SwiftShader).
build_additional_flags() {
    local flags="--privileged"
    if [[ -d /dev/bus/usb ]]; then
        flags+=" -v /dev/bus/usb:/dev/bus/usb:rslave"
    fi
    if [[ -d /dev/dri ]]; then
        flags+=" --device /dev/dri"
    fi
    printf '%s' "$flags"
}

ADDITIONAL_FLAGS="$(build_additional_flags)"

# Recreate or reuse the container
if [[ "$KEEP_EXISTING" == true ]]; then
    echo "=== [1/3] Keeping Existing Container ($CONTAINER_NAME) ==="
    if ! distrobox list | grep -q "^[^|]*| $CONTAINER_NAME "; then
        echo "Container '$CONTAINER_NAME' does not exist. Creating it anyway..."
        pull_image "$IMAGE"
        distrobox create --name "$CONTAINER_NAME" --image "$IMAGE" \
            --additional-flags "$ADDITIONAL_FLAGS"
    fi
else
    echo "=== [1/3] Removing Old Distrobox Container ($CONTAINER_NAME) ==="
    if distrobox list | grep -q "^[^|]*| $CONTAINER_NAME "; then
        distrobox stop "$CONTAINER_NAME" --yes || true
        distrobox rm "$CONTAINER_NAME" --yes || true
    fi
    echo "=== [2/3] Creating New Distrobox Container ($CONTAINER_NAME) ==="
    pull_image "$IMAGE"
    distrobox create --name "$CONTAINER_NAME" --image "$IMAGE" \
        --additional-flags "$ADDITIONAL_FLAGS"
fi

# The in-container installer is written to the shared home directory and run
# there, which avoids fragile quoting of URLs and heredocs across `distrobox
# enter`. The host home is mounted at the same path inside the container.
mkdir -p "$CACHE_DIR"
INNER_SCRIPT="$CACHE_DIR/install-in-container.sh"

cat >"$INNER_SCRIPT" <<'INNER'
#!/usr/bin/env bash
# Runs inside the Distrobox container. FRAME_MANIFEST_URL is exported by host.
set -euo pipefail

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    curl ca-certificates libglib2.0-bin libpulse0 libasound2t64 \
    libgl1-mesa-dri libglx-mesa0 mesa-va-drivers libva2 libva-drm2 \
    libvulkan1 fontconfig fonts-dejavu-core

# Resolve the current .deb from Frame's per-architecture manifest.
echo "--- Resolving current Frame App release ---"
FRAME_DEB_URL="$(curl -fsSL "$FRAME_MANIFEST_URL" |
    sed -n 's/.*"downloadUrl":"\([^"]*\)".*/\1/p')"
if [ -z "$FRAME_DEB_URL" ]; then
    echo "Error: could not resolve a Frame App download URL" >&2
    exit 1
fi
echo "Frame App package: $FRAME_DEB_URL"

curl -fsSL "$FRAME_DEB_URL" -o "$WORKDIR/frame.deb"

# Repack the .deb with a container-safe postinst. The upstream script runs
# `systemctl enable/start pcscd`, copies the udev rules and finishes with
# `udevadm control --reload-rules`; inside a rootless container the bus is
# absent and the final command returns non-zero, which fails dpkg configure.
echo "--- Patching post-install script ---"
dpkg-deb -R "$WORKDIR/frame.deb" "$WORKDIR/repack"
cat >"$WORKDIR/repack/DEBIAN/postinst" <<'POSTINST'
#!/bin/sh
# Container-safe post-install.
# systemd, pcscd and the udev daemon do not run inside the container; device
# access is governed by the host. Stage the vendor USB rules and succeed.
mkdir -p /etc/udev/rules.d
if [ -f /usr/lib/frame/resources/60-frame-usb.rules ]; then
    cp -f /usr/lib/frame/resources/60-frame-usb.rules \
        /etc/udev/rules.d/60-frame-usb.rules
fi
exit 0
POSTINST
chmod 0755 "$WORKDIR/repack/DEBIAN/postinst"
dpkg-deb -b "$WORKDIR/repack" "$WORKDIR/frame-fixed.deb"

echo "--- Installing Frame App ---"
# --no-install-recommends keeps apt from pulling the full PulseAudio server and
# the KDE utility stack (both only weak dependencies of the package).
sudo apt-get install -y --no-install-recommends "$WORKDIR/frame-fixed.deb"

echo "--- Done ---"
dpkg-query -W -f='Installed: ${Package} ${Version}\n' frame
command -v frame
INNER
chmod 0755 "$INNER_SCRIPT"

echo "=== [3/3] Installing Frame App in Container ($CONTAINER_NAME) ==="

distrobox enter "$CONTAINER_NAME" -- env FRAME_MANIFEST_URL="$FRAME_MANIFEST_URL" \
    bash "$INNER_SCRIPT"

echo ""
echo "=== Setup Complete ==="
echo "Launch the client on the host with: frame"
echo "Or drop into the container with:    distrobox enter $CONTAINER_NAME"

# Only open an interactive shell when attached to a terminal (so the script is
# safe to run from automation or CI).
if [[ -t 0 && -t 1 ]]; then
    exec distrobox enter "$CONTAINER_NAME"
fi
