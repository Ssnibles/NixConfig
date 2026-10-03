# Frame Remote Desktop Client Container Environment

This document explains how the [Nutanix Frame](https://frame.nutanix.com/)
remote desktop (Desktop-as-a-Service) client is integrated into NixConfig using
Distrobox and an Ubuntu 24.04 container.

---

## Motivation & Architecture

The [Frame App](https://docs.dizzion.com/) is a large Electron/Chromium client
distributed only as a Debian package built for Ubuntu. Its package metadata and
post-install script assume a conventional, booted systemd host with a running
`udev` daemon, and it pulls in a broad set of desktop libraries that are
awkward to keep in the Nix store.

To keep the host clean, the client runs inside an isolated Ubuntu 24.04
container managed by **Distrobox** and **Podman**:

- Container name: `frame`
- Image: `docker.io/library/ubuntu:24.04`
- Display forwarding: shared X11 / Wayland sockets (Electron uses XWayland by
  default; the environment is passed through by Distrobox).
- Audio: the host PulseAudio/PipeWire socket in `$XDG_RUNTIME_DIR` is mounted
  into the container, with `libpulse0` / `libasound2t64` installed inside.
- USB: `--privileged` with `/dev/bus/usb` forwarded (`rslave`) so local USB
  devices can be redirected into a remote session.
- Integration: a host launcher (`frame`) and desktop entry
  (`modules/features/apps/frame.nix`) plus the setup script
  (`assets/setup_frame.sh`).

---

## Installed Packages

The `.deb` is installed with its declared dependencies, plus a small set of
packages the package only weakly depends on (or omits) that a containerised
desktop client needs:

| Package | Purpose |
| :--- | :--- |
| `frame` | Frame App client (resolved from Frame's release manifest) |
| `libglib2.0-bin` | Satisfies the trash/URL-handler dependency alternative, avoiding KDE |
| `libpulse0`, `libasound2t64` | PulseAudio and ALSA client libraries |
| `libgl1-mesa-dri`, `libglx-mesa0` | Mesa OpenGL software/GPU renderers |
| `mesa-va-drivers`, `libva2`, `libva-drm2` | VA-API hardware video decode (Intel/AMD) |
| `libvulkan1` | Vulkan loader |
| `fontconfig`, `fonts-dejavu-core` | Text rendering for the Electron UI |
| `curl`, `ca-certificates` | Fetching the `.deb` and TLS trust store |

The vendor `.deb` is **not installed verbatim**. Its post-install script runs
`systemctl enable/start pcscd`, copies a `udev` rule and finishes with
`udevadm control --reload-rules`. Inside a rootless container there is no
systemd bus and no `udev` daemon, so that final command returns non-zero and
`dpkg --configure` aborts. `setup_frame.sh` unpacks the `.deb`, replaces the
post-install script with a container-safe version (stage the vendor USB rules,
then `exit 0`) and installs the repacked package.

---

## Setup

### 1. Run the setup script (one-time setup)

```bash
~/NixConfig/assets/setup_frame.sh
```

This creates the `frame` Distrobox container and installs the current Frame
App release. The client version is resolved at run time from Frame's
per-architecture manifest
(`https://downloads.console.nutanix.com/terminal/manifest-linux64.json`), so it
is never pinned.

Options:

```text
-k, --keep          Reuse the existing container instead of recreating it
-c, --name NAME     Use a custom container name (default: frame)
-h, --help          Show usage
```

The script is automation-friendly: it only drops into an interactive shell
when attached to a terminal.

### 2. Enable the host launcher

With `features.frame.enable = true`, NixOS installs:

- a `frame` wrapper that transparently enters the container,
- a "Frame" desktop entry, including the `frame://` and `frameapp://` SSO URL
  schemes,
- the application icon in the hicolor theme,
- the vendor USB `udev` rules for the host (`plugdev` group).

Launch the client from the application menu or with:

```bash
frame
```

Opening a `frame://` single sign-on link now routes to the client as well.

---

## Typical Workflow

1. Launch `frame` and sign in to your Frame account.
2. Pick a published desktop or application from the launcher.
3. The session opens in the client window; audio is routed through the host
   PipeWire/PulseAudio server.

Working directly inside the container is also supported:

```bash
distrobox enter frame
```

---

## GPU, Audio & USB Notes

### Graphics

On Intel/AMD hosts `/dev/dri` is passed through and Mesa + VA-API drivers are
installed, so hardware video decode is available. The NVIDIA `--nvidia`
Distrobox integration is deliberately **not** used: it discovers driver files
under `/run/host/usr/lib`, which does not exist on NixOS, and the host GL
libraries under `/run/opengl-driver` are not ABI-compatible with the Ubuntu
container. On NVIDIA hosts the client falls back to software rendering
(SwiftShader); the UI remains responsive and video decode uses the bundled
`libffmpeg`.

### Audio

Distrobox mounts the host user runtime directory, so the PulseAudio/PipeWire
socket at `$XDG_RUNTIME_DIR/pulse/native` is available inside the container.
No extra flags are required.

### USB device redirection

The container is created with `--privileged` and `/dev/bus/usb` mounted
`rslave`, and the host carries the vendor `udev` rules:

```udev
SUBSYSTEMS=="usb", ATTRS{idVendor}=="1008", MODE="0664", GROUP="plugdev"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="1050", MODE="0664", GROUP="plugdev"
```

Users must belong to the `plugdev` group. If a device is not visible, confirm
the group membership with `id` and replug the device after rebuilding so the
rules are active.

### Smart cards

The package depends on `pcscd` for smart-card authentication, but the daemon
does not run inside the container and the client logs
`SmartCardService is not available`. Password and SSO authentication are
unaffected.

---

## Troubleshooting

- **`frame: Distrobox container 'frame' was not found`** — run
  `~/NixConfig/assets/setup_frame.sh` first.
- **`dpkg: error processing package frame`** — the vendor post-install script
  ran unmodified. Re-run the setup script, which repacks the package with a
  container-safe post-install script.
- **No audio** — verify the host audio server is running and that
  `$XDG_RUNTIME_DIR/pulse/native` exists on the host.
- **GPU process exits / software rendering** — expected on NVIDIA; see
  *Graphics* above.
