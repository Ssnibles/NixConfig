# Wayland Compositors Guide

This document describes the three Wayland compositors configured in `NixConfig`: **Hyprland**, **Niri**, and **MangoWC**.

---

## 🖥️ Compositor Overview

| Compositor | Layout Paradigm | Primary Host Target | Desktop Shell |
|---|---|---|---|
| **Hyprland** | Dynamic Tiling & Floating | `desktop` | Noctalia Shell + Quickshell |
| **Niri** | Scrollable Infinite Tiling | `laptop` | Quickshell (`niri-bar.qml`) |
| **MangoWC** | DWM-style Tiling & Master/Stack | `laptop` / `desktop` | Quickshell (`bar.qml`) |

---

## 🪟 1. Hyprland (`modules/features/desktop-env/hyprland/`)
- **Engine**: wlroots-based dynamic tiling compositor with fluid animations, rounded corners, and drop shadows.
- **Shell Integration**: Paired with [noctalia-shell](https://github.com/Ssnibles/noctalia) and custom Quickshell bars.
- **Keybindings**: Standard Super-based bindings for window movement, workspace switching, floating toggles, and screenshotting.

---

## 📜 2. Niri (`modules/features/desktop-env/niri/`)
- **Engine**: Scrollable infinite-strip tiling window manager. Windows open in horizontal columns that scroll infinitely across workspaces.
- **Bar Integration**: Uses `niri-bar.qml` (vertical left sidebar) communicating with `NiriService.qml` via `niri msg --json event-stream`.

---

## 🥭 3. MangoWC (`modules/features/desktop-env/mangowc/`)
- **Engine**: Ultra-lightweight DWM-inspired Wayland compositor.
- **Features**: Master & stack layout algorithm, tag-based workspace management, and minimal resource footprint.
- **Bar Integration**: Paired with Quickshell's unified top bar (`bar.qml`).
