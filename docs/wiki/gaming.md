# Gaming, Steam & DualSense Controllers Guide

This document details the gaming environment, performance overlay tools, and PlayStation 5 controller support in `NixConfig`.

---

## 🎮 Features & Toolchain

### 1. Steam & Millennium
- Installed via `modules/features/apps/gaming.nix`.
- Includes **Millennium** skinning framework overlay for styling Steam UI (`github:SteamClientHomebrew/Millennium`).

### 2. Gamescope & MangoHud
- **Gamescope**: Micro-compositor for running games in isolated display containers with custom resolution scaling, FSR upscaling, and refresh rate limiting.
- **MangoHud**: On-screen system performance monitoring overlay tracking FPS, GPU/CPU usage, frame times, and temperatures.

### 3. PS5 DualSense & DualSense Edge Controller Support
- Kernel module support for `hid-playstation` enabled.
- Udev rules configured for USB and Bluetooth controller pairing without root permissions.
- Custom package helper `dualsense-pair` (`modules/packages/dualsense-pair/`) included in system environment for pairing DualSense controllers via CLI.
