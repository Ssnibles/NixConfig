# AMD Vivado FPGA Container Environment Guide

This document explains how AMD Vivado Design Suite 2024.1 is integrated into `NixConfig` using Distrobox and Ubuntu 22.04 container virtualization.

---

## 🛠️ Motivation & Architecture

Vivado relies on legacy Linux dependencies and dynamic libraries incompatible with pure NixOS store paths. In `NixConfig`, Vivado runs inside an isolated Ubuntu 22.04 container managed by **Distrobox** and **Podman**:

- Container name: `vivado-2024.1`
- Display forwarding: Shared X11 socket + Wayland XWayland bridge (`$DISPLAY`).
- Audio & USB: Passthrough for hardware FPGA programmers (Xilinx Platform Cable USB / Digilent JTAG).
- Integration: Desktop shortcut launcher wrapper (`modules/features/apps/vivado.nix`) and setup helper script (`assets/setup_vivado.sh`).

---

## 🚀 Setup & Launch Instructions

### 1. Run Setup Script (One-Time Setup)
```bash
~/NixConfig/assets/setup_vivado.sh
```
*This creates the `vivado-2024.1` Distrobox Ubuntu 22.04 container and installs required dependencies (`libtinfo5`, `libncurses5`, `libx11-dev`, `gdm3`, `x11-utils`).*

### 2. Launch Vivado
Launch Vivado directly from your desktop launcher (Vicinae / Application Menu) or via terminal command:
```bash
vivado
```

---

## 🔌 Hardware Programming & USB Passthrough

For JTAG cable detection inside the container, place udev rules on your NixOS system:
```nix
services.udev.packages = [ pkgs.openocd ];
```
Users must belong to `dialout` and `plugdev` groups.
