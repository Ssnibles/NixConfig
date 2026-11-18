# Quickshell Desktop Shell Bar & UI Framework Guide

This document details the [Quickshell](https://quickshell.outfoxxed.me/) QML desktop shell system used across Wayland compositors in NixConfig.

---

## Architecture Overview

Quickshell powers the unified horizontal/vertical status bar (`bar.qml`), the **Command Centre** quick-settings dashboard, the **Launcher**, the Wayland **Lock Screen**, the desktop **Notification daemon and overlay**, and shared UI primitives.

All QML source files live in `modules/features/desktop-env/quickshell/config/` and are symlinked directly to `~/.config/quickshell/` via `nixos.liveLinks` (`contents = true`), while generated theme files (`Colours.qml`) are managed declaratively by Hjem:

```
modules/features/desktop-env/quickshell/
├── default.nix                   # Nix module installing quickshell & generating Colours.qml
├── README.md                     # Module reference & development guide
├── tests/
│   └── utils.test.js             # Node.js unit test suite for Utils.js
└── config/                       # Live QML source code (symlinked to ~/.config/quickshell/)
    ├── shell.qml                 # Root application entry point (Scope)
    ├── Config.qml                # Singleton of layout dimensions, fonts and options
    ├── Colours.qml               # Nix-generated theme colour tokens
    ├── Utils.js                  # Shared JavaScript helper functions
    ├── qmldir                    # Manifest for cross-directory types
    │
    ├── common/                   # Shared primitives and reusable widgets
    │   ├── Card.qml
    │   ├── Pill.qml
    │   ├── StatusPill.qml
    │   ├── Divider.qml
    │   ├── IconButton.qml
    │   ├── MenuFooterButton.qml
    │   ├── MenuHeader.qml
    │   ├── RoundedImage.qml
    │   ├── CoverArt.qml
    │   ├── SliderControl.qml
    │   ├── ThinScrollBar.qml
    │   ├── Tooltip.qml
    │   ├── TooltipCard.qml
    │   ├── MediaCard.qml
    │   ├── MediaProgressRow.qml
    │   ├── PlaybackControls.qml
    │   ├── PowerButtons.qml
    │   ├── BatteryWidget.qml
    │   ├── NetworkWidget.qml
    │   ├── BluetoothWidget.qml
    │   ├── VolumePill.qml
    │   └── NotificationCard.qml
    ├── services/                 # State singletons and compositor backends
    │   ├── Session.qml           # Compositor, user, host and resolved paths
    │   ├── UiState.qml           # Transient state: what is open, tray toggles
    │   ├── WmService.qml
    │   ├── MangoService.qml
    │   ├── HyprlandService.qml
    │   ├── NiriService.qml
    │   ├── AudioService.qml
    │   ├── BrightnessService.qml
    │   ├── NetworkService.qml
    │   ├── BatteryService.qml
    │   ├── BluetoothService.qml
    │   ├── TrayService.qml
    │   ├── SystemService.qml
    │   ├── NotificationService.qml
    │   ├── NotificationIcons.qml
    │   ├── ClockService.qml
    │   ├── MediaService.qml
    │   ├── MediaColours.qml      # Cover-art palette, cached per artwork URL
    │   ├── WeatherService.qml
    │   └── WindowFocuser.qml
    ├── bar/                      # Status bar and bar-only widgets
    │   ├── bar.qml
    │   ├── BluetoothMenu.qml
    │   ├── CalendarPopup.qml
    │   ├── ClockWidget.qml
    │   ├── CommandCentreButton.qml
    │   ├── LayoutPopup.qml
    │   ├── LayoutWidget.qml
    │   ├── MediaWidget.qml
    │   ├── NetworkMenu.qml
    │   ├── SharedTooltipWindow.qml
    │   ├── StatusMenu.qml
    │   ├── SystemTrayWidget.qml
    │   ├── TrayMenu.qml
    │   ├── WindowTitleWidget.qml
    │   └── WorkspacesWidget.qml
    ├── launcher/                 # Application launcher and calculator
    │   ├── Launcher.qml
    │   ├── Calc.js
    │   ├── expr-eval.js
    │   ├── expr-eval.LICENSE
    │   └── desktop-entries.sh
    ├── command-centre/           # Command Centre and its cards
    │   ├── CommandCentre.qml
    │   ├── CommandCentreCard.qml
    │   ├── CommandCentreBento.qml
    │   ├── CommandCentreSliders.qml
    │   ├── AudioSinkPicker.qml
    │   ├── ControlSliderRow.qml
    │   ├── NotificationHistoryCard.qml
    │   ├── StatusPills.qml
    │   ├── SystemStatsCard.qml
    │   └── WeatherCard.qml
    ├── notifications/
    │   └── NotificationOverlay.qml
    ├── lock/                     # Lock screen components
    │   ├── LockScreen.qml
    │   ├── LockAuthCard.qml
    │   ├── LockClock.qml
    │   ├── LockSecondaryScreen.qml
    │   ├── LockStatusCluster.qml
    │   ├── LockStateRow.qml
    │   ├── HostnamePill.qml
    │   └── LockMediaRow.qml
    └── osd/
        └── OsdOverlay.qml
```

Each subdirectory imports `..`, and `config/qmldir` lists shared types by path so a component in one directory can use a type from another. Add new cross-directory types to the manifest.

---

## Theme & Configuration Singletons

Settings are split three ways so `Config.qml` stays a flat list of literals:

### `Config.qml` (Settings)
Everything you might want to change: layout dimensions, fonts, timings and options.
- **Fonts**: `monoFont`, `sansFont`, `serifFont` (from `Colours`, with fallbacks).
- **Bar**: `barWidth` (42px), `barHeight` (35px), margins, spacing and the `barShow*` widget flags. The network and Bluetooth menus use `statusMenuWidth` (460px) and `statusMenuHeight` (520px).
- **Command Centre**: `commandCentreLayout` (`"sidebar"` or `"bento"`), `commandCentreWidth` (500px), `commandCentreRadius` (26px), the `commandCentreBento*` size options, and `ccShow*` flags. The bento layout is a three-column board: the left card with the clock, status pills, sliders, media player and power; the middle column with the notification history; and the right column with the weather, calendar and system load card. The board takes `commandCentreBentoWidthRatio` (0.7) and `commandCentreBentoHeightRatio` (0.75) of the screen, clamped inwards by the screen margins, and the columns share that height so the cards stay roomy. The notification and weather/calendar columns take `commandCentreBentoNotificationRatio` (0.325) and `commandCentreBentoSideRatio` (0.27) of the board width; the left card takes the rest. Every card uses `commandCentreCardPadding` (26px) for its interior and `commandCentreCardSpacing` (26px) between its blocks, so the board keeps one rhythm. `commandCentreBentoSurface` draws one raised surface behind the cards.
- **Weather**: `weatherCacheMinutes` (10) and `weatherShowForecast` (true). The weather card fetches from `wttr.in` when it opens or when refreshed manually, then caches for that many minutes; there is no background poll.
- **Audio and OSD**: step sizes, `osdPosition`, sizes and timeouts.
- **External commands**: `cmdMixer`, `cmdTerminal`, `cmdClipboard`, power actions.

### `Session.qml` (Environment)
Facts about the running session and everything derived from them, so no expressions live in `Config`:
- `wm` (`$QS_BAR`, then `XDG_CURRENT_DESKTOP`), `user`, `home`, `hostname`.
- `barType`, `hasTopBar`, `hasLeftBar`, `hasRightBar`, and `barGeometry` for overlay margins.
- Resolved `barSide`, `commandCentreSide` and `lockStatusPosition` (each with a `QS_*` override).
- Resolved `lockAvatarPath` and `lockWallpaperPath`, where an empty `Config` value means the default.

### `UiState.qml` (Transient State)
Resets when the shell restarts: `barVisible`, `commandCentreVisible`, `launcherVisible`, `statusMenu` (`""`, `"network"` or `"bluetooth"`), `targetScreen`, `lastActiveScreen`, and the tray on/off, expand and session-hide lists. `openStatusMenu(menu)` closes the Command Centre first, and `closeStatusMenu()` dismisses the menu.

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

`WmService`, `NiriService`, and the hardware services process CLI output using `StdioCollector` hooked to `onStreamFinished` rather than `onDataChanged`, ensuring complete JSON streams and hardware states are collected before parsing.

This enables swapping between Wayland compositors while keeping the exact same status bar, notification centre, lock screen, and styling.

---

## Command Centre & Lock Screen

### Command Centre Dashboard
- Toggled via **`SUPER + d`** or clicking the Command Centre button in the bar.
- Sliders control output volume, microphone and brightness; network, Bluetooth and battery sit in the header pills, and Do Not Disturb lives in the notification card, so no control is duplicated.
- Shows the clock, weather, calendar, media controls, notification history, and the power actions. A header button runs the screenshot tool.
- **Keyboard**: Escape closes the panel. Power actions stay click-only to avoid accidental activation.

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

## Launcher

The Quickshell launcher (`config/launcher/Launcher.qml`) is a lightweight alternative to Vicinae. It is a starting point rather than a full replacement:
- **Open**: `SUPER + Shift + Space` in MangoWC, Hyprland, and Niri, or `quickshell ipc call launcher toggle`.
- **Window**: A fixed 760 x 500 card centred on the active screen, reusing `WmService.resolveTargetScreen(...)` and the `Card` primitive. The result list scrolls and keeps the selected row visible.
- **Applications**: `launcher/desktop-entries.sh` parses `.desktop` files from `XDG_DATA_DIRS` and the Flatpak exports, skips `NoDisplay`/`Hidden` entries, strips field codes, and emits JSON lines with the application Actions, file path, and desktop ID. It collects the files in bash and parses them in one `awk` pass, so a scan costs a single process; it reruns on every open. The QML side filters by name and comment and launches with `sh -c` (or `kitty -e` for terminal entries).
- **Ordering**: match quality first, then recent use. The most recently launched apps are stored in `Quickshell.statePath("launcher-recents.json")` and capped by `Config.launcherRecentCount` (20).
- **Keyboard**: Up/Down or Ctrl+K/Ctrl+J move the selection. Ctrl+Enter opens the actions menu for the selected application or calculator result. Escape closes the menu first, then the launcher.
- **Actions**: Per-app `[Desktop Action]` entries come first, then the presets Launch, Run in terminal, Copy command, Copy desktop file path, and Copy desktop ID. Calculator results offer Copy result and Copy expression.
- **Calculator**: `launcher/Calc.js` wraps the vendored expr-eval library (`launcher/expr-eval.js`, MIT). It supports arithmetic, `^`, functions such as `sqrt`, `sin`, and `log`, and the constants `pi`, `e`, and `tau`. A valid expression appears as the first result; Enter copies it with `wl-copy`.
- **Theme**: All colours come from `Colours.qml` and fonts from `Config.qml`, so it matches the rest of the shell.

Vicinae remains installed and keeps its own keybinds while the built-in launcher is evaluated.

---

## Notification Daemon & Overlay

Quickshell includes a built-in Freedesktop notification daemon replacement:
- **`NotificationService.qml`**: Listens for DBus notifications (`org.freedesktop.Notifications`) and MPRIS track transitions, retains live `Notification` objects, and manages active toast and history models. History is mirrored to `notification-history.json` in the Quickshell state directory, so it survives restarts and reloads; media toasts and actions are not saved. Icon, avatar, and glyph resolution lives in `NotificationIcons.qml`. MPRIS track changes are toasted but only kept in history when `Config.notifMediaHistory` is true.
- **`NotificationOverlay.qml`**: Renders smooth toast cards on the configured corner of the active monitor.
- Integrates with system daemons like `journal-error-notify` (notifying on boot failures) and `shikane` (display profile changes).

---

## Unit Testing

Quickshell includes zero-dependency Node.js unit tests in `modules/features/desktop-env/quickshell/tests/`:

```bash
node --test modules/features/desktop-env/quickshell/tests/*.test.js
```

`utils.test.js` validates the core `Utils.js` helpers, and `calc.test.js` covers the launcher calculator.

The test runner validates core JavaScript helpers in `Utils.js` inside an isolated Node `vm` context:
- Two-digit padding (`pad2`) and audio track duration formatting (`formatTime`).
- Media metadata sanitation (stripping site suffixes and track counters).
- Application ID normalisation (`prettifyAppName`) and window title formatting (`formatActiveTitle`).
- Battery icon state mapping (0% through 100%, plugged, charging, discharging).
- `goToSource` window activation rules and multi-output target screen resolution (`resolveActiveScreen`).

These cover the JavaScript only. QML components are checked in a throwaway shell instance instead, because changing one means restarting the real shell. See [QML Component Testing](qml-testing.md) for that loop.

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
```

`qs ipc show` lists the targets the running build actually exposes: `bar`, `media`, `system`, `launcher`, `command-centre`, `lockscreen` and `tray`. There is no `quickshell` target, so no in-place reload over IPC.

Editing QML here does not apply by itself either. The live config is a tree of symlinks into this repository, and Quickshell does not notice a change made to the target of a symlink: a real `shell.qml` reloads the configuration when edited, but the target of a symlinked one does not. Apply changes by restarting:

```bash
qs-restart
```

That helper runs `pkill -f quickshell` and then `setsid quickshell >/dev/null 2>&1 &`, so the new instance outlives the shell that launched it. To iterate on a single component without restarting, use the throwaway-shell loop in [QML Component Testing](qml-testing.md).
