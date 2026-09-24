# Quickshell Desktop Shell Bar & UI Framework Guide

This document details the [Quickshell](https://quickshell.outfoxxed.me/) QML desktop shell system used across Wayland compositors in NixConfig.

---

## Architecture Overview

Quickshell powers the horizontal top status bar (`bar.qml`), the vertical Niri status bar (`niri-bar.qml`), the **Command Centre** quick-settings dashboard, the Wayland **Lock Screen**, the desktop **Notification daemon and overlay**, and shared UI primitives.

All QML source files live in `modules/features/desktop-env/quickshell/config/` and are symlinked directly to `~/.config/quickshell/` by NixOS activation scripts:

```
modules/features/desktop-env/quickshell/
├── default.nix                   # Nix module installing quickshell & generating Colors.qml
└── config/                       # Live QML source code (symlinked to ~/.config/quickshell/)
    ├── shell.qml                 # Root application entry point (Scope)
    ├── Config.qml                # Singleton storing UI layout dimensions & fonts
    ├── Colors.qml                # Nix-generated theme colour tokens
    ├── Utils.js                  # Shared JavaScript helper functions
    │
    ├── bar.qml                   # Top horizontal bar (MangoWC, Hyprland)
    ├── niri-bar.qml              # Vertical side bar (Niri)
    ├── CommandCenter.qml         # Slide-out quick settings dashboard
    ├── CommandCenterButton.qml   # Toggle button in status bar
    ├── LockScreen.qml            # Wayland session locker (WlSessionLock + PAM)
    │
    ├── NotificationOverlay.qml   # Toast notification popup overlay
    ├── NotificationStore.qml     # Notification daemon state manager
    ├── NotificationCard.qml      # Visual notification card component
    │
    ├── WmService.qml             # Unified compositor abstraction layer
    ├── MangoService.qml          # MangoWC IPC backend
    ├── HyprlandService.qml       # Hyprland IPC backend
    ├── NiriService.qml           # Niri event-stream backend
    ├── RiverService.qml          # River IPC backend
    ├── MediaService.qml          # MPRIS media player backend
    │
    ├── BatteryWidget.qml         # Battery telemetry & charging indicator
    ├── BluetoothWidget.qml       # Connected devices status
    ├── ClockWidget.qml           # Time and date widget
    ├── LayoutWidget.qml          # Active window manager layout widget
    ├── MediaWidget.qml           # Player controls & current song title
    ├── MediaProgress.qml         # Song seek and progress bar
    ├── NetworkWidget.qml         # Wi-Fi SSID and signal strength
    ├── VolumeWidget.qml          # PipeWire volume level & mute status
    ├── WindowTitleWidget.qml     # Focused application window title
    └── WorkspacesWidget.qml      # Visual workspace and tag indicators
```

---

## Theme & Configuration Singletons

### `Config.qml` (Layout Dimensions & Fonts)
Holds global layout dimensions, fonts, timings, and component parameters:
- **Fonts**: `monoFont` ("JetBrainsMono Nerd Font"), `sansFont` ("SF Pro Text"), `serifFont` ("Instrument Serif").
- **Bar Dimensions**: `barWidth` (42px vertical bar), `barHeight` (34px top bar).
- **Command Centre**: `commandCenterWidth` (500px), `commandCenterRadius` (16px).

### `Colors.qml` (Nix-Generated Colour Tokens)
Generated automatically by Nix based on `config.theme.colors`:
- **Surface Colours**: `Colors.bg`, `Colors.bgRaised`, `Colors.bgSubtle`, `Colors.border`
- **Text Colours**: `Colors.fg`, `Colors.fgMid`, `Colors.fgDim`
- **Accents**: `Colors.accent`, `Colors.teal`, `Colors.purple`, `Colors.green`, `Colors.yellow`, `Colors.red`, `Colors.orange`

---

## Multi-Compositor Routing (`WmService.qml`)

Quickshell does not hardcode compositor dependencies into individual UI widgets. Instead, **`WmService.qml`** abstracts workspace, window focus, and layout queries across compositors:
- In MangoWC, it communicates via `MangoService.qml` (`mmsg`).
- In Hyprland, it communicates via `HyprlandService.qml` (`hyprctl`).
- In Niri, it parses the JSON stream from `NiriService.qml` (`niri msg --json event-stream`).
- In River, it hooks into `RiverService.qml`.

This enables swapping between Wayland compositors while keeping the exact same status bar, notification centre, lock screen, and styling.

---

## Command Centre & Lock Screen

### Command Centre Dashboard
- Toggled via **`SUPER + d`** or clicking the Command Centre button in the bar.
- Provides quick toggles for Wi-Fi, Bluetooth, Audio sinks, Display brightness, and media playback.
- Displays volume sliders, battery health telemetry, and system resource monitors.

### Session Lock Screen (`LockScreen.qml`)
- Toggled via **`SUPER + Alt + L`** or `quickshell ipc call lockscreen lock`.
- Utilises the Wayland `ext-session-lock-v1` protocol, guaranteeing that no windows or notifications leak while locked.
- Authenticates directly against system PAM for password validation.

---

## Notification Daemon & Overlay

Quickshell includes a built-in Freedesktop notification daemon replacement:
- **`NotificationStore.qml`**: Listens for DBus notifications (`org.freedesktop.Notifications`), filters incoming messages, and manages historical stores.
- **`NotificationOverlay.qml`**: Renders smooth toast cards on the top-right corner of the active monitor.
- Integrates with system daemons like `journal-error-notify` (notifying on boot failures) and `shikane` (display profile changes).

---

## IPC Commands & Controls

You can trigger Quickshell overlays programmatically or via keybindings using `quickshell ipc`:

```bash
# Toggle Command Centre overlay
quickshell ipc call command-center toggle

# Lock screen immediately
quickshell ipc call lockscreen lock

# Toggle top bar visibility
quickshell ipc call bar toggle

# Reload Quickshell UI in-place (also available in Pet snippets)
qs -c default ipc call quickshell reload all
# Or restart process:
pkill quickshell; quickshell &
```
