# Gaming, Steam & DualSense Controllers Guide

This document details the Linux gaming stack, Steam customisation with Millennium, display compositing with Gamescope, performance monitoring with MangoHud, and PlayStation 5 controller support in NixConfig.

---

## Overview

The gaming stack configured in `modules/features/apps/gaming.nix` provides a high-performance environment across both desktop (NVIDIA) and laptop (AMD) hardware:

| Component | Role | Highlights |
| :--- | :--- | :--- |
| **Steam** | Primary Game Launcher | Bundled with Millennium skinning framework and proton compatibility tools |
| **Millennium** | Steam UI Theming Engine | Declarative overlay enabling custom modern skins and community plugins |
| **Gamescope** | Micro-Compositor | Sandboxed gaming session, integer and FSR upscaling, refresh rate locking |
| **GameMode** | System Performance Daemon | Dynamically sets CPU governor to performance and elevates process scheduling |
| **MangoHud** | Telemetry Overlay | Real-time on-screen display for FPS, frame times, CPU/GPU temperatures |
| **DualSense Stack** | PS5 Controller Support | Native `hid-playstation` kernel drivers, udev rules, `dualsense-pair` CLI |

---

## Steam & Millennium UI Skinning

Steam is installed through NixOS options with the **Millennium** framework overlay (`github:SteamClientHomebrew/Millennium`):

```nix
nixpkgs.overlays = [
  inputs.millennium.overlays.default
];
```

### What Millennium Enables
Millennium injects CSS and JavaScript customisation directly into Steam's Chromium-based interface without breaking across client updates. This allows installing custom dark themes, minimal navigation bars, and custom library views.

### Managing Compatibility Tools (Proton-GE)
For titles requiring non-standard Proton builds, you can invoke `protonup` on-demand (also available via Pet snippets):

```bash
nix-shell -p protonup-ng --run "protonup"
```

---

## Gamescope Micro-Compositor

Gamescope isolates the game window inside its own lightweight Wayland compositor before passing frames to your desktop compositor (MangoWC or Hyprland):

### Benefits
- **Resolution Upscaling**: Run games at 1080p and upscale to 1440p using AMD FidelityFX Super Resolution (FSR).
- **Aspect Ratio Emulation**: Lock ultrawide or non-standard resolutions with clean black letterboxing.
- **Input Isolation**: Prevents cursor escape or multi-monitor focus loss in fullscreen games.
- **Colour Adjustments**: Apply custom colour saturation and gamma curves.

### Steam Launch Options Example

In Steam game properties, set the launch options:

```bash
# Run game at 1080p upscaled with FSR to 1440p at 144Hz:
gamescope -w 1920 -h 1080 -W 2560 -H 1440 -r 144 -F fsr -- %command%

# Enable GameMode and MangoHud alongside Gamescope:
gamemoderun mangohud gamescope -W 1920 -H 1080 -r 144 -- %command%
```

---

## MangoHud Performance Overlay

MangoHud provides a clean, customisable heads-up display tracking system metrics:
- Real-time FPS and frame time graph
- GPU clock speeds, temperature, VRAM usage
- CPU utilisation per core and temperature
- Battery discharge rate (on laptop)

Launch any game or Vulkan application with MangoHud:

```bash
mangohud %command%
# Or in standalone terminal commands:
mangohud vkcube
```

---

## PlayStation 5 DualSense Controller Support

Full kernel driver and Bluetooth pairing support for Sony PlayStation 5 DualSense and DualSense Edge controllers is configured out of the box.

### Kernel Driver & Udev Rules
- The mainline Linux kernel module **`hid-playstation`** is active, providing accurate battery reporting, adaptive trigger support, haptic feedback, and touchpad input.
- Udev rules grant the `dialout` and `plugdev` user groups direct access to controller devices without requiring root permissions.

### Pairing via `dualsense-pair` Helper

The repository includes a custom helper script (`modules/packages/dualsense-pair/dualsense-pair.sh`) packaged as `dualsense-pair`:

1. **Put Controller into Bluetooth Pairing Mode**:
   - Hold the **`Create`** button (top left of touchpad) and the **`PS`** button simultaneously.
   - Wait until the lightbar begins blinking rapidly in double-pulses.
2. **Execute Pairing Command**:
   ```bash
   dualsense-pair
   ```
3. The script automatically powers on the Bluetooth adapter, scans for the DualSense MAC address, pairs the device, marks it as trusted, and connects.
