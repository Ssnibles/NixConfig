# Quickshell Desktop Shell Bar & UI Framework Guide

This document details the [Quickshell](https://quickshell.outfoxxed.me/) QML desktop shell system used across Wayland compositors in `NixConfig`.

---

## 🏗 Architecture Overview

Quickshell powers the status bars (`niri-bar.qml` and `bar.qml`), the **Command Center** dashboard, the Wayland **Lock Screen**, the **Notification system**, and shared UI primitives (pills, tooltips, range sliders).

All QML source files live in `modules/features/desktop-env/quickshell/config/` and are symlinked directly to `~/.config/quickshell/` by Nix activation scripts.

```
modules/features/desktop-env/quickshell/
├── default.nix                   # Nix module installing quickshell & generating Colors.qml
└── config/                       # Live QML source code (symlinked to ~/.config/quickshell/)
    ├── shell.qml                 # Root application entry point (Scope)
    ├── Config.qml                # Singleton storing UI layout dimensions & fonts
    ├── Colors.qml                # Nix-generated theme color tokens
    ├── Utils.js                  # Shared JavaScript helper functions
    ├── bar.qml                   # Top horizontal bar (MangoWC, Hyprland, DWL)
    ├── niri-bar.qml              # Vertical side bar (Niri)
    ├── CommandCenter.qml         # Slide-out quick settings dashboard
    ├── LockScreen.qml            # Session locker (WlSessionLock + PAM)
    ├── NotificationOverlay.qml   # Toast notification overlay
    ├── NotificationStore.qml     # Notification daemon state manager
    └── WmService.qml             # Unified compositor IPC router
```

---

## 🎨 Theme & Configuration Singletons

### `Config.qml` (UI Dimensions & Fonts)
Holds global layout dimensions, fonts, timings, and component parameters:
- **Fonts**: `monoFont` ("JetBrainsMono Nerd Font"), `sansFont` ("SF Pro Text"), `serifFont` ("Instrument Serif").
- **Bar Dimensions**: `barWidth` (42px vertical bar), `barHeight` (34px top bar).
- **Command Center**: `commandCenterWidth` (500px), `commandCenterRadius` (16px).

### `Colors.qml` (Generated Color Tokens)
Generated automatically by Nix based on `config.theme.colors`:
- Surface Colors: `Colors.bg`, `Colors.bgRaised`, `Colors.bgSubtle`, `Colors.border`
- Text Colors: `Colors.fg`, `Colors.fgMid`, `Colors.fgDim`
- Accents: `Colors.accent`, `Colors.teal`, `Colors.purple`, `Colors.green`, `Colors.yellow`, `Colors.red`

---

## 💻 IPC Commands & Controls

You can trigger Quickshell overlays programmatically or via keybindings using `quickshell ipc`:

```bash
# Toggle Command Center overlay
quickshell ipc call command-center toggle

# Lock screen immediately
quickshell ipc call lockscreen lock

# Reload Quickshell UI after QML edits
pkill quickshell; quickshell &
```
