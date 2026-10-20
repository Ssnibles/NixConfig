# Quickshell Desktop Shell Bar & UI Framework Guide

This document details the [Quickshell](https://quickshell.outfoxxed.me/) QML desktop shell system used across Wayland compositors in NixConfig.

---

## Architecture Overview

Quickshell powers the unified horizontal/vertical status bar (`bar.qml`), the **Command Centre** quick-settings dashboard, the Wayland **Lock Screen**, the desktop **Notification daemon and overlay**, and shared UI primitives.

All QML source files live in `modules/features/desktop-env/quickshell/config/` and are symlinked directly to `~/.config/quickshell/` via `nixos.liveLinks` (`contents = true`), while generated theme files (`Colours.qml`) are managed declaratively by Hjem:

```
modules/features/desktop-env/quickshell/
├── default.nix                   # Nix module installing quickshell & generating Colours.qml
├── README.md                     # Module reference & development guide
├── tests/
│   └── utils.test.js             # Node.js unit test suite for Utils.js
└── config/                       # Live QML source code (symlinked to ~/.config/quickshell/)
    ├── shell.qml                 # Root application entry point (Scope)
    ├── Config.qml                # Singleton storing UI layout dimensions & fonts
    ├── Colours.qml                # Nix-generated theme colour tokens
    ├── Utils.js                  # Shared JavaScript helper functions
    ├── qmldir.lsp                # Optional staged manifest for editor/LSP tooling
    │
    ├── bar.qml                   # Unified horizontal top bar (MangoWC, Hyprland) & vertical side bar (Niri)
    ├── CommandCentre.qml         # Slide-out quick settings dashboard
    ├── CommandCentreButton.qml   # Toggle button in status bar
    ├── LockScreen.qml            # Wayland session locker (WlSessionLock + PAM)
    │
    ├── NotificationOverlay.qml   # Toast notification popup overlay
    ├── NotificationService.qml   # Central notification daemon, icon resolver & state singleton
    ├── NotificationCard.qml      # Visual notification card component
    ├── OsdOverlay.qml            # Floating volume, mic, and brightness OSD pill
    │
    ├── WmService.qml             # Unified compositor & active-screen singleton
    ├── MangoService.qml          # MangoWC IPC backend (mmsg)
    ├── HyprlandService.qml       # Hyprland IPC backend (hyprctl)
    ├── NiriService.qml           # Niri event-stream backend
    ├── SystemService.qml         # Central PipeWire audio (sinks + mic), backlight & OSD singleton
    ├── ClockService.qml          # Shared minute-aligned clock & date singleton
    ├── MediaService.qml          # MPRIS media player backend & multi-player switcher
    ├── WindowFocuser.qml         # Native-first window activation (no Node fallback)
    │
    ├── MediaCard.qml             # Shared media card (Command Centre / popover / lock)
    ├── MediaWidget.qml           # Player controls & current song title (bar button)
    ├── PlaybackControls.qml      # Shared prev / play-pause / next cluster
    ├── MediaProgressRow.qml      # Elapsed + seek bar + total time row
    ├── PowerButtons.qml          # Shared system power action row
    │
    ├── BatteryWidget.qml         # Battery telemetry & charging indicator
    ├── BluetoothWidget.qml       # Connected devices status
    ├── ClockWidget.qml           # Time and date widget (with calendar popover)
    ├── LayoutWidget.qml          # Active window manager layout widget
    ├── NetworkWidget.qml         # Wi-Fi SSID and signal strength
    ├── SystemTrayWidget.qml      # StatusNotifierItem system tray icons
    ├── VolumeWidget.qml          # PipeWire volume level & mute status
    ├── WindowTitleWidget.qml     # Focused application window title
    ├── WorkspacesWidget.qml      # Visual workspace and tag indicators
    │
    ├── Card.qml                  # Shared surface/card container primitive
    ├── IconButton.qml            # Shared interactive icon button primitive
    ├── Pill.qml                  # Rounded pill container primitive
    ├── SliderControl.qml         # Reusable horizontal slider
    ├── RoundedImage.qml          # Async rounded/masked image
    ├── Tooltip.qml               # Hover popup trigger
    └── SharedTooltipWindow.qml   # Per-display popup layer window
```

---

## Theme & Configuration Singletons

### `Config.qml` (Layout Dimensions & Fonts)
Holds global layout dimensions, fonts, timings, and component parameters:
- **Fonts**: `monoFont` ("JetBrainsMono Nerd Font"), `sansFont` ("SF Pro Text"), `serifFont` ("Instrument Serif").
- **Bar Dimensions**: `barWidth` (42px vertical bar), `barHeight` (34px top bar).
- **Command Centre**: `commandCentreWidth` (500px), `commandCentreRadius` (16px).

### `Colours.qml` (Nix-Generated Colour Tokens)
Generated automatically by Nix based on `config.theme.colours`:
- **Surface Colours**: `Colours.bg`, `Colours.bgRaised`, `Colours.bgSubtle`, `Colours.border`
- **Text Colours**: `Colours.fg`, `Colours.fgMid`, `Colours.fgDim`
- **Accents**: `Colours.accent`, `Colours.teal`, `Colours.purple`, `Colours.green`, `Colours.yellow`, `Colours.red`, `Colours.orange`

---

## Multi-Compositor Routing (`WmService.qml`)

Quickshell does not hardcode compositor dependencies into individual UI widgets. Instead, **`WmService.qml`** (`pragma Singleton`) abstracts workspace, window focus, layout, and active-screen queries across compositors:
- In MangoWC, it communicates via `MangoService.qml` (`mmsg`).
- In Hyprland, it communicates via `HyprlandService.qml` (`hyprctl`).
- In Niri, it parses the JSON stream from `NiriService.qml` (`niri msg --json event-stream`).

`WmService`, `NiriService`, and `SystemService` process CLI output using `StdioCollector` hooked to `onStreamFinished` rather than `onDataChanged`, ensuring complete JSON streams and hardware states are collected before parsing.

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
- **Unified Multi-Monitor Focus**: Password input state (`enteredPassword`) is stored on the root singleton `Scope` rather than inside per-monitor surface text inputs. When multi-monitor setups lock, keystrokes captured on secondary surfaces route directly to the active password buffer on the primary screen, eliminating secondary-monitor focus traps.
- **Visual Feedback & UI Polish**: Features a user avatar, input field with smooth accent border transitions on typing, an interactive password reveal/peek eye toggle, an animated rotating spinner during PAM authentication, an accent-glowing submit arrow, and an error shake animation.
- **Secondary Display Integration**: Non-primary monitors display live typing feedback (indicating character count and auth state) and an embedded `MediaCard` for active audio playback.
- **Configurable Status Pill Cluster**: Groups system status indicators (Hostname, Network Wi-Fi/Ethernet, Battery, and PipeWire Volume/Mute) into a clean, docked corner cluster (defaults to `top-right`). Configurable to any corner (`"top-right"`, `"top-left"`, `"bottom-right"`, `"bottom-left"`) or 4-corner mode (`"split"` / `"corners"`) via `Config.lockStatusPosition` or the `QS_LOCK_STATUS_POS` environment variable.
- **Modifier Filtering**: Keypress handlers explicitly guard against `Ctrl` and `Alt` modifiers (`!(event.modifiers & (Qt.ControlModifier | Qt.AltModifier))`), preventing control characters from corrupting typed passwords.

---

## Notification Daemon & Overlay

Quickshell includes a built-in Freedesktop notification daemon replacement:
- **`NotificationService.qml`**: Listens for DBus notifications (`org.freedesktop.Notifications`) and MPRIS track transitions, resolves app icons/avatars/glyphs once per notification, retains live `Notification` objects, and manages active toast and history models.
- **`NotificationOverlay.qml`**: Renders smooth toast cards on the configured corner of the active monitor.
- Integrates with system daemons like `journal-error-notify` (notifying on boot failures) and `shikane` (display profile changes).

---

## Unit Testing Framework (`tests/utils.test.js`)

Quickshell includes a zero-dependency Node.js unit test suite in `modules/features/desktop-env/quickshell/tests/utils.test.js`:

```bash
node --test modules/features/desktop-env/quickshell/tests/utils.test.js
```

The test runner validates core JavaScript helpers in `Utils.js` inside an isolated Node `vm` context:
- Two-digit padding (`pad2`) and audio track duration formatting (`formatTime`).
- Media metadata sanitation (stripping site suffixes and track counters).
- Application ID normalization (`prettifyAppName`) and window title formatting (`formatActiveTitle`).
- Battery icon state mapping (0% through 100%, plugged, charging, discharging).
- `goToSource` window activation rules and multi-output target screen resolution (`resolveActiveScreen`).

---

## IPC Commands & Controls

You can trigger Quickshell overlays programmatically or via keybindings using `quickshell ipc`:

```bash
# Toggle Command Centre overlay
quickshell ipc call command-centre toggle

# Lock screen immediately
quickshell ipc call lockscreen lock

# Toggle top bar visibility
quickshell ipc call bar toggle

# Reload Quickshell UI in-place (also available in navi cheats)
qs -c default ipc call quickshell reload all
# Or restart process:
pkill quickshell; quickshell &
```
