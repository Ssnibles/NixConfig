# WRAMP Toolchain & Simulator Container Environment

This document explains how the [WRAMP](https://wramp.wand.nz/) (Waikato RISC
Architecture MicroProcessor) toolchain and simulator are integrated into
NixConfig using Distrobox and an Ubuntu 22.04 container.

---

## Motivation & Architecture

The WRAMP toolchain published by [`wandwramp`](https://github.com/wandwramp)
predates modern Linux distributions: the native assembler, linker, compiler and
serial tools are built for Ubuntu 16.04, and the `wsim` simulator is a Mono/C#
WinForms application. Both run cleanly on Ubuntu 22.04 but not on pure NixOS.

To keep the host clean, everything runs inside an isolated Ubuntu 22.04
container managed by **Distrobox** and **Podman**:

- Container name: `wramp`
- Display forwarding: shared X11 socket + Wayland XWayland bridge (`$DISPLAY`)
  for the `wsim` GUI.
- USB: privileged passthrough of `/dev/bus/usb` for a physical Basys3 board.
- Integration: host wrapper scripts and a desktop entry
  (`modules/features/apps/wramp.nix`) plus the setup script
  (`assets/setup_wramp.sh`).

---

## Installed Tooling

| Tool | Purpose | Version |
| :--- | :--- | :--- |
| `wasm` | WRAMP assembler | toolchain `V3.0.1` |
| `wlink` | WRAMP linker (produces `.srec`) | toolchain `V3.0.1` |
| `wobj` | Object viewer / disassembler | toolchain `V3.0.1` |
| `wcc`, `wcpp`, `rcc` | WRAMP C compiler | `1.1.1.1` |
| `wsim` | Mono/C# WinForms CPU simulator | `v3.3.4` |
| `remote`, `down` | Serial terminal for physical boards | `3.0.0` |
| `trim` | `.srec` → Vivado `.mem` converter | `3.0.0` |
| WRAMPmon | Monitor firmware (built from source) | `master` |

Everything is staged under `/opt/wramp` and symlinked into `/usr/local/bin`,
so the tools are on `PATH` for any shell inside the container. WRAMPmon is
built during setup and installed as `monitor.srec` / `monitor.mem` under
`/opt/wramp/WRAMPmon/`.

---

## Setup

### 1. Run the setup script (one-time setup)

```bash
~/NixConfig/assets/setup_wramp.sh
```

This creates the `wramp` Distrobox Ubuntu 22.04 container and installs the
full toolchain, `wsim` (via `mono-complete` + `libgdiplus`), and the WRAMPmon
firmware. Use `-k/--keep` to install into an existing container instead of
recreating it, or `-c/--name` to use a different container name.

### 2. Enable the host launchers (optional)

With `features.wramp.enable = true`, NixOS installs thin wrappers (`wasm`,
`wlink`, `wobj`, `wcc`, `remote`, `trim`, `wsim`) that transparently execute
the tool inside the container, plus a "WRAMP Simulator" desktop entry. Launch
the simulator from your application menu or with:

```bash
wsim
```

---

## Typical Workflow

```bash
# Assemble and link a program
wasm -o program.o program.s
wlink -o program.srec program.o

# Run it in the simulator
wsim
```

Inside the simulator, WRAMPmon provides the serial console: type `load` to
upload a `.srec` (or drag it into the serial window / press `Ctrl-A`), then
`go` to run it.

Working directly inside the container is also supported:

```bash
distrobox enter wramp
```

---

## Physical Basys3 Boards

`remote` talks to a board over its on-board USB-serial adapter
(`/dev/ttyUSBx`). A default configuration is staged at `~/.remoterc.dfl`; set
`pu port` to the correct device and run:

```bash
remote
```

`remote` uploads programs through `down` (`Ctrl-A S` to send a `.srec`).
Users must belong to the `dialout` group on the host to access the serial
device. The container is created with `--privileged` and passes `/dev/bus/usb`
through; if your serial adapter is not visible, add its device node explicitly,
for example:

```bash
distrobox create --name wramp --image ubuntu:22.04 \
  --additional-flags "--privileged --device /dev/ttyUSB0"
```
