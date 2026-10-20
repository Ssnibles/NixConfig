# Quickshell — Module Reference & Development Guide

This directory contains the [Quickshell](https://quickshell.outfoxxed.me/) configuration for the unified status bar (`bar.qml`), the **Command Centre** dashboard, the Wayland **Lock Screen**, the **Notification system**, and shared UI primitives (pills, tooltips, sliders).

All QML code lives in `config/` and is symlinked to `~/.config/quickshell/` by Nix activation scripts. **QML edits apply immediately on the next quickshell restart** — no Nix rebuild needed for standard QML modifications. Only `Colours.qml` is generated directly by Nix from system theme tokens and requires a rebuild to update.

---

## Table of Contents

1. [How the Module is Wired Up (`default.nix`)](#1-how-the-module-is-wired-up-defaultnix)
2. [Entry Point & Architecture (`shell.qml`)](#2-entry-point--architecture-shellqml)
3. [Configuration Reference (`Config.qml`)](#3-configuration-reference--configqml)
4. [Theme Colours (`Colours.qml`)](#4-theme-colours-coloursqml)
5. [Module Catalogue & Component Reference](#5-module-catalogue--component-reference)
   - [Bars](#51-bars)
   - [Services & Infrastructure](#52-services--infrastructure)
   - [Overlays & Standalone Screens](#53-overlays--standalone-screens)
   - [Widgets & UI Components](#54-widgets--ui-components)
6. [Tooltip & Popup System](#6-tooltip--popup-system)
7. [How to Add New Modules / Widgets](#7-how-to-add-new-modules--widgets)
8. [IPC Commands & Reloading](#8-ipc-commands--reloading)

---

## 1. How the Module is Wired Up (`default.nix`)

| Step | Description |
| --- | --- |
| **System Packages** | `quickshell` (unstable) is installed into the environment. |
| **`Colours.qml`** | Generated from `config.theme.colours` into `~/.config/quickshell/Colours.qml` via Hjem. |
| **Config Symlinks** | Activation script (`quickshell-config`) creates `~/.config/quickshell` and symlinks every file in `config/*`. |
| **Permissions** | Symlinks and target directories are owned by the active user. |

---

## 2. Entry Point & Architecture (`shell.qml`)

`shell.qml` serves as the top-level application root (`Scope`), instantiating the active status bar, notification manager, command centre, and lock screen:

```qml
Scope {
  Loader {
    source: "bar.qml"
  }
  NotificationOverlay { }
  OsdOverlay { }
  CommandCentre { }
  LockScreen { }
}
```

- **Unified Status Bar (`bar.qml`)**: Automatically adapts between a horizontal top bar (MangoWC, Hyprland) and a vertical left/right side bar (Niri, or when `QS_BAR=niri`), powered by the `WmService` singleton.
- **Notification Overlay**: Global notification stack present on the active display (or all displays).
- **OSD Overlay (`OsdOverlay.qml`)**: Floating bottom-centre On-Screen Display pill for volume, microphone mute, and screen brightness changes.
- **Command Centre**: Slide-out dashboard overlay controllable via IPC.
- **Lock Screen**: Wayland session lock (`WlSessionLock`) with PAM authentication.

---

## 3. Configuration Reference (`Config.qml`)

`Config.qml` is a `pragma Singleton` holding all global layout dimensions, fonts, timings, and component options.

### 3.1 Fonts
| Property | Default | Purpose |
| --- | --- | --- |
| `monoFont` | `Colours.monoFont` \| `"JetBrainsMono Nerd Font"` | Icons, numbers, monospaced text |
| `sansFont` | `"SF Pro Text"` | UI text, notifications, titles |
| `serifFont` | `Colours.serifFont` \| `"Instrument Serif"` | Clocks, headers |

### 3.2 Status Bars
| Property | Default | Purpose |
| --- | --- | --- |
| `barWidth` | `42` | Niri bar width (px) |
| `barSide` | `"left"` | Niri bar screen edge (`"left"` \| `"right"`). Overridable with the `QS_BAR_SIDE` env var. |
| `barMarginTop/Bottom/Left/Right` | `8 / 8 / 4 / 4` | Outer padding around Niri bar |
| `barSpacing` | `8` | Vertical gap between widget groups |
| `volBarHeight` | `64` | Volume bar widget height |
| `wifiMaxTextLength` | `90` | Maximum network SSID display width |
| `barHeight` | `34` | MangoWC top bar height (px) |
| `mangowcMinWorkspaces` | `5` | Minimum workspace tag slots in MangoWC |

### 3.3 Command Centre (`CommandCentre.qml`)
| Property | Default | Purpose |
| --- | --- | --- |
| `commandCentreVisible` | `false` | Controls overlay visibility (toggleable via IPC) |
| `commandCentreWidth` | `500` | Width of slide-out panel (px) |
| `commandCentreRadius` | `16` | Panel corner rounding radius |
| `commandCentreCardRadius` | `12` | Inner section card corner radius |
| `commandCentreClockFormat` | `"HH:mm"` | Header clock format |
| `commandCentreDateFormat` | `"dddd, MMMM d"` | Header date format |
| `alwaysShowMediaCard` | `true` | Show media player card even when idle |
| `mediaRotationDuration` | `4000` | Album art rotation duration (ms) |
| `mediaSeekDebounceMs` | `200` | Seeking debounce delay (ms) |

### 3.4 Lock Screen (`LockScreen.qml`)
| Property | Default | Purpose |
| --- | --- | --- |
| `lockAvatarPath` | `Quickshell.shellDir + "/assets/avatar.png"` | Path to user avatar image |
| `lockFallbackIcon` | `"󰀉"` | Fallback glyph when avatar image is absent |
| `lockWallpaperPath` | `"file://" + $HOME + "/Pictures/wallpaper"` | Lock screen wallpaper image |
| `lockClockFormat` | `"HH:mm"` | Time display format |
| `lockDateFormat` | `"dddd, MMMM d"` | Date display format |
| `commandCentreCardRadius` | `12` | Authentication card corner radius (also used by the lock screen) |
| `lockInputRadius` | `10` | Password input box radius |
| `lockBackgroundDimming` | `0.8` | Dark background overlay opacity (0.0–1.0) |
| `lockBlurPercentage` | `0.5` | Wallpaper GPU blur amount (0.0–1.0) |

### 3.5 Popups & Tooltips (`SharedTooltipWindow.qml`)
| Property | Default | Purpose |
| --- | --- | --- |
| `popupGap` | `46` | Distance from bar to popup card |
| `popupMaxWidth` | `280` | Default card width |
| `popupRadius` | `12` | Popup card corner radius |
| `popupContentMargins` | `12` | Padding inside popups |
| `popupShowDelay` | `150` | Hover delay before showing popup (ms) |
| `popupFadeMs` | `120` | Fade transition duration (ms) |
| `popupGraceMs` | `700` | Grace window for instant-swapping between adjacent popups |

### 3.6 Notifications (`NotificationOverlay.qml` & `NotificationService.qml`)
| Property | Default | Purpose |
| --- | --- | --- |
| `notifPosition` | `"top-right"` | Placement on screen (`"top-left"`, `"top-right"`, `"bottom-left"`, etc.) |
| `notifMarginX` | `12` | Horizontal offset margin from screen edge (px) |
| `notifMarginY` | `12` | Vertical offset margin from screen edge (px) |
| `notifTimeoutMs` | `5000` | Default display duration per popup (ms) |
| `notifTimeoutLowMs` | `3000` | Duration for low-urgency notifications (ms) |
| `notifTimeoutCriticalMs` | `0` | Duration for critical notifications (`0` = persistent) |
| `notifMaxVisible` | `5` | Maximum active popup count on screen |
| `notifMaxHistory` | `30` | Maximum history items retained in `NotificationService` |
| `notifWidth` | `320` | Notification card width (px) |
| `notifRadius` | `12` | Notification card corner radius |
| `notifCardMargins` | `12` | Internal card padding (px) |
| `notifSpacing` | `8` | Spacing between stacked cards (px) |
| `notifIconSize` | `40` | Icon/avatar dimension for standard notifications (px) |
| `notifMediaIconSize` | `48` | Icon/avatar dimension for media notifications (px) |
| `notifIconRadius` | `8` | Corner radius for notification icon/avatar preview |
| `notifMaxLines` | `5` | Maximum lines of notification body text before eliding |
| `notifShowActions` | `true` | Display interactive action buttons on cards |
| `notifDismissOnAction` | `true` | Automatically dismiss card when an action is invoked |
| `notifShowMediaToasts` | `true` | Show popups for MPRIS media track transitions |
| `notifAllScreens` | `false` | Display notification overlay across all displays |
| `notifLeftClickAction` | `"dismiss"` | Action on left-click (`"dismiss"` or `"focus"`) |
| `notifDefaultFallbackLogo` | `"preferences-desktop-notification"` | System theme fallback icon if app has no icon |
| `notifDefaultFallbackGlyph` | `"󰂚"` | Fallback Nerd Font glyph |
| `notifAppIcons` | `({ ... })` | App name/desktop entry to preferred icon override mapping |
| `notifAppGlyphs` | `({ ... })` | App/category to Nerd Font glyph mapping |
| `notifMediaApps` | `[ ... ]` | List of media player app identifiers |


---

## 4. Theme Colours (`Colours.qml`)

`Colours.qml` is automatically generated by Nix based on the current theme (`config.theme.colours`). Available colour tokens:

| Token | Semantic Purpose |
| --- | --- |
| `Colours.bg` | Primary background surface |
| `Colours.bgRaised` | Elevated card & modal container backgrounds |
| `Colours.bgSubtle` | Subtle highlight / track backgrounds |
| `Colours.border` | Border lines and dividers |
| `Colours.fg` / `Colours.fgMid` / `Colours.fgDim` | Primary, secondary, and muted text |
| `Colours.accent` | Active state accent colour |
| `Colours.teal` / `purple` / `green` / `yellow` / `red` / `orange` | Status and semantic accent colours |

---

## 5. Module Catalogue & Component Reference

### 5.1 Bars

#### `bar.qml`
- **Role**: Unified horizontal top bar (MangoWC, Hyprland) and vertical side bar (Niri).
- **Features**: Powered by singletons (`WmService`, `ClockService`, `SystemService`, `MediaService`) to render workspace dots, layout switcher, active window titles, system status indicators, clock, and `SharedTooltipWindow`.

---

### 5.2 Services & Infrastructure

#### `WmService.qml`
- **Role**: Unified `pragma Singleton` bridging active compositor backends (`MangoService`, `HyprlandService`, `NiriService`) based on `Config.wm`.
- **Exposes**: `currentTitle`, `workspacesDependency`, `getWorkspaces(outputName)`, `focusWorkspace(id)`, `getLayoutSymbol(outputName)`, `getLayoutInfo(symbol)`, `setLayout(symbol)`, `nextLayout()`, and active/cursor monitor detection (`resolveTargetScreen(callback)`, `cancelScreenQuery()`, `queryingScreen`).

#### `SystemService.qml`
- **Role**: Central `pragma Singleton` for PipeWire output sinks, microphone input source, `brightnessctl` + sysfs screen backlight control, OSD state, and `"system"` IPC actions.
- **Exposes**: `audioSink`, `audioSinks`, `selectAudioSink(node)`, `sinkDisplayName(node)`, `volume`, `muted`, `volumePercent`, `volumeIcon`, `toggleMute()`, `setVolume(val)`, `setVolumeDebounced(val)`, `stepVolume(dir)`, `openMixer()`, `hasMic`, `micVolume`, `micMuted`, `micVolumePercent`, `micIcon`, `toggleMicMute()`, `setMicVolume(val)`, `setMicVolumeDebounced(val)`, `brightness`, `brightnessAvailable`, `brightnessPercent`, `refreshBrightness()`, `setBrightness(val)`, `stepBrightness(dir)`, and OSD state (`osdVisible`, `osdKind`, `osdIcon`, `osdLabel`, `osdValue`, `osdMuted`, `showOsd(...)`).

#### `ClockService.qml`
- **Role**: Central minute-aligned clock `pragma Singleton` ingested by `ClockWidget`, `CommandCentre`, and `LockScreen`.
- **Exposes**: `now`, `timeStr`, `hourStr`, `minuteStr`, `ordinalDateStr`, `ccTimeStr`, `ccTime12Str`, `ccDateStr`, `lockTimeStr`, `lockDateStr`.

#### `MangoService.qml`, `HyprlandService.qml`, `NiriService.qml`
- **Role**: Compositor-specific IPC backends loaded dynamically by `WmService.qml`.

#### `WindowFocuser.qml`
- **Role**: Singleton that activates a window from a notification / MPRIS player / app descriptor.
- **Strategy**: Uses Quickshell's native `ToplevelManager` when available; otherwise queries and scores the compositor's IPC (`mmsg` / `niri` / `hyprctl`) directly in QML (replaces the old inline Node fallback). Exposes `focus(patterns)` and `focusSource(source)`.

#### `NotificationService.qml`
- **Role**: Central notification daemon, MPRIS track-toast emitter, icon/avatar resolver, and state manager.
- **Features**: Subscribes to `Quickshell.Services.Notifications`, retains live `Notification` objects while in active or history models, copies ephemeral `/tmp/` avatars to `~/.cache/quickshell/notif-images/`, resolves app icons and glyphs once per item, manages auto-dismiss timers and hover pausing, and handles action invocation and sender window focusing.

#### `Utils.js`
- **Role**: Shared JavaScript utility library (`.pragma library`).
- **Features**: `findFirst`, `findBatteryDevice`, `findActivePlayer`, `resolveMprisPlayer`, `cyclePlayer`, `pad2`, `formatTime`, `cleanTrackTitle`, `prettifyAppName`, `formatActiveTitle`, and icon helpers (`volumeIcon`, `micIcon`, `batteryIcon`).

---

### 5.3 Overlays & Standalone Screens

#### `CommandCentre.qml`
- **Role**: Slide-out quick settings dashboard and system metrics panel.
- **IPC Target**: `"command-centre"` (functions: `toggle()`, `open()`, `close()`).
- **Multi-Monitor Cursor Tracking**: Delegates active-screen detection to `WmService.resolveTargetScreen(...)` and slides out on that specific monitor while rendering a transparent dismiss overlay across all other screens.
- **Features**: Header clock & date (via `ClockService`), status pills (Wi-Fi, Ethernet, Battery, Bluetooth), system sliders (`SliderControl` bound to `SystemService` for PipeWire output volume, expandable audio sink switcher, microphone volume/mute, and `brightnessctl` screen brightness), full MPRIS media player card (`MediaCard`), plus notification history list (`NotificationService`).

#### `OsdOverlay.qml`
- **Role**: Floating bottom-centre On-Screen Display pill driven by `SystemService`.
- **Features**: Automatically pops up on the active monitor when output volume, mute, microphone mute/volume, or screen brightness changes (suppressed while `CommandCentre` is open).

#### `LockScreen.qml`
- **Role**: Wayland session screen locker built on `WlSessionLock` and `WlSessionLockSurface`.
- **IPC Target**: `"lockscreen"` (functions: `lock()`, `unlock()`, `toggle()`).
- **Features**: Lazy loading architecture, PAM authentication (`PamContext`), primary monitor interactive password prompt with user avatar, real-time accent highlight on keystrokes, rotating authentication spinner, password peek/reveal eye toggle, Caps Lock warning & error shake animation, secondary screen display lock graphics with live typing indicator & MPRIS `MediaCard`, customisable status pill cluster docked to any corner (default `"top-right"`, `"top-left"`, `"bottom-right"`, `"bottom-left"`, or `"split"` / `"corners"` via `Config.lockStatusPosition` or `QS_LOCK_STATUS_POS`), background wallpaper with customisable GPU blur (`MultiEffect`) and dimming, and system power actions (Sleep/Suspend, Reboot, Power Off).

#### `NotificationOverlay.qml` & `NotificationCard.qml`
- **Role**: Screen overlay and card delegate rendering active notification toasts and history items.
- **Features**: Stack layout driven by `NotificationService`, animated entry/exit, action buttons, avatar/icon previews with fallback glyphs, and click-to-dismiss or focus.

---

### 5.4 Widgets & UI Components

#### `Pill.qml`
- **Role**: Standardised rounded pill container for bar widgets and inline action pills.
- **Properties**: `horizontal`, `padding`, `pillHeight`, `baseColour`, `hoverColour`, `hoverHighlight`, `pillColour`, `orientation`, `clickable`, `acceptedButtons`, `hovered`, `radius`; signals `clicked(var mouse)`, `wheel(var wheel)`. Includes built-in hover/border colour transitions, auto-sizing, and optional pointer click/scroll handling.

#### `Card.qml`
- **Role**: Shared elevated/surface card container used across Command Centre sections, popovers, `MediaCard`, `NotificationCard`, `OsdOverlay`, and `LockScreen`.
- **Properties**: `cardColour` (defaults to `Colours.bgRaised`), `borderColour` (defaults to `Colours.border`), `cardRadius` (defaults to `Config.commandCentreCardRadius`), with smooth colour and border transitions.

#### `IconButton.qml`
- **Role**: Shared interactive icon button with hover colour, border, and scale feedback.
- **Properties**: `icon`, `iconSize`, `buttonSize`, `baseColour`, `hoverColour`, `borderColour`, `hoverBorderColour`, `iconColour`, `hoverIconColour`, `disabledIconColour`, `hoverScale`, `hovered`; signal `clicked(var mouse)`.

#### `SliderControl.qml`
- **Role**: Reusable interactive horizontal range slider.
- **Properties**: `value` (0.0–1.0), `fillColour`, `snapPercent`, signal `moved(real value)`. Supports mouse drag and direct click positioning.

#### `CommandCentreButton.qml`
- **Role**: Quick dashboard trigger button component for status bars.
- **Properties**: `horizontal`, `screen`. Toggles `Config.commandCentreVisible`, automatically setting the target screen to the parent bar's monitor.

#### `MediaCard.qml`
- **Role**: Shared MPRIS media card used by the Command Centre, the bar media popover and the lock screen.
- **Properties**: `showWhenIdle`, `seekable`, `interactive`, `cardColour`, `cardRadius`. Renders album art (with fallback), track/artist text, interactive multi-player switcher pill (`MediaService.cyclePlayer`), `PlaybackControls` and `MediaProgressRow`.

#### `PlaybackControls.qml`
- **Role**: Reusable previous / play-pause / next button cluster.
- **Properties**: `canPrevious`, `canNext`, `isPlaying`, `uiFont`; signals `previousClicked`, `playPauseClicked`, `nextClicked`.

#### `MediaProgressRow.qml`
- **Role**: Reusable elapsed-time + seek bar + total-time row. Renders a `● LIVE` label instead of the seek bar when `live` is set (streams with no finite length).
- **Properties**: `position`, `length`, `progress`, `seekable`, `live`; signal `seekRequested(real progress)`.

#### `PowerButtons.qml`
- **Role**: Shared system power-action row (Lock / Sleep / Reboot / Power).
- **Properties**: `showLock`, `buttonRadius`; signal `activated()`.

#### `RoundedImage.qml`
- **Role**: Async image with rounded-corner masking.
- **Properties**: `source`, `sourceSize`, `fillMode`, `radius`; exposes `ready`, `status`, and a `sourceError()` signal for fallback chains.

#### Standard Bar Widgets
- **`ClockWidget.qml`**: Time/date stack ingested from `ClockService` with click-to-popup calendar details.
- **`WindowTitleWidget.qml`**: Active window title ingested from `WmService`.
- **`WorkspacesWidget.qml`**: Interactive workspace indicators connected to `WmService`.
- **`LayoutWidget.qml`**: Tiling layout selector connected to `WmService` (auto-shown on MangoWC).
- **`SystemTrayWidget.qml`**: StatusNotifierItem (SNI) system tray pill supporting left-click activate, right-click menu, scroll, and hover tooltips. Automatically hides when no tray items are registered.
- **`MediaWidget.qml`**: MPRIS playback bar button ingested from `MediaService`.
- **`VolumeWidget.qml`**: PipeWire volume control widget ingested from `SystemService`.
- **`NetworkWidget.qml`**: Network connection monitor displaying Wi-Fi SSID and signal strength. Right-click launches `nmtui`. Set `interactive: false` to render it as a read-only pill (used on the lock screen).
- **`BluetoothWidget.qml`**: Bluetooth adapter status and device indicator. Right-click launches `blueman-manager`.
- **`BatteryWidget.qml`**: Laptop battery charge state and status indicator powered by UPower. Auto-hides on desktop systems without batteries. Set `interactive: false` to render it as a read-only pill (used on the lock screen).

---

## 6. Tooltip System

The popup system uses two cooperating components:

### `Tooltip.qml`
Nest an instance inside any widget to attach hover-triggered popups:
```qml
Tooltip {
  sharedWindow: parent.sharedWindow
  icon: "󰕾"
  title: "Volume"
  details: ["Sink: Default", "Muted: No"]
}
```
- **Custom Popups**: Pass a custom `Component` to `contentComponent` to render arbitrary QML inside the popup layer instead of the default card.

### `SharedTooltipWindow.qml`
A single layer window per display hugging `Config.barSide`. Handles popup positioning, clamping to screen boundaries, smooth fade transitions, and instant-swapping between adjacent widgets.

---

## 7. How to Add New Modules / Widgets

Follow these steps to create and register a new status bar widget or overlay component:

### Step 1: Create the Component File
Create a new QML file in `modules/features/desktop-env/quickshell/config/`, e.g., `CpuWidget.qml`:

```qml
import Quickshell
import QtQuick
import "Utils.js" as Utils

Pill {
  id: root
  property var sharedWindow: null

  pillColour: mouseArea.containsMouse ? Colours.bgRaised : Colours.bgSubtle
  border.color: Colours.border
  border.width: 1

  Row {
    spacing: 6
    anchors.centerIn: parent

    Text {
      text: "󰍛"
      color: Colours.accent
      font.family: Config.monoFont
      font.pixelSize: 14
    }

    Text {
      text: "42%"
      color: Colours.fg
      font.family: Config.monoFont
      font.pixelSize: 12
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
  }

  Tooltip {
    sharedWindow: root.sharedWindow
    icon: "󰍛"
    title: "CPU Usage"
    details: ["Load: 42%", "Temp: 45°C"]
  }
}
```

### Step 2: Add Config Settings (Optional)
If your module requires configurable settings, add them to `Config.qml`:

```qml
// CPU Widget Settings
readonly property int cpuPollIntervalMs: 2000
```

### Step 3: Insert into the Status Bar
Open `bar.qml` and instantiate your component inside `startSection` or `endSection`:

```qml
CpuWidget {
  horizontal: root.isHorizontal
  sharedWindow: sharedTipWindow
  Layout.alignment: Qt.AlignCenter
}
```

### Step 4: Test
Because activation scripts symlink the whole `config/` directory into `~/.config/quickshell/`, newly created QML files are picked up automatically after a `sudo nixos-rebuild switch` — no manual `ln -s` step is needed. (The symlinks are re-created on activation, so files deleted from the repo are also pruned.)

- Run `sudo nixos-rebuild switch` to refresh the live links.
- Restart Quickshell to load the new widget!

---

## 8. IPC Commands & Reloading

Quickshell includes built-in IPC mechanisms. You can trigger overlays or inspect state from the command line or desktop keybindings:

```bash
# Toggle Command Centre overlay
quickshell ipc call command-centre toggle

# Lock screen
quickshell ipc call lockscreen lock

# Unlock screen (if active)
quickshell ipc call lockscreen unlock
```

To reload Quickshell after editing existing QML files:
```bash
pkill quickshell; quickshell &
```

---

## 9. Tooling & Tests

- **Unit tests** (`tests/utils.test.js`): pure-JS tests for the helpers in `Utils.js` (title cleaning, app-name prettifying, time/volume/battery formatting, screen lookup). Run locally with:
  ```bash
  node --test modules/features/desktop-env/quickshell/tests/utils.test.js
  ```
  These also run in the `Validate Nix Flake` GitHub Actions workflow and need no Nix or Qt.

- **Editor / LSP support**: `config/qmldir.lsp` is a *staged* module manifest so `qmllint`/`qmlls` can resolve the local singletons. It is deliberately not named `qmldir`, because Quickshell discovers `pragma Singleton` types on its own. To enable it:
  ```bash
  cp modules/features/desktop-env/quickshell/config/qmldir.lsp ~/.config/quickshell/qmldir
  ```
  Delete that copy to revert if your editor or shell misbehaves.

- **Static analysis**: every QML file declares `pragma ComponentBehavior: Bound`, and delegates declare their model context as `required property ...`. With the `qmldir` above, `qmllint` is clean apart from a handful of Quickshell/`Qt` type-resolution false positives (`PanelWindow`, `margins {}`, `Qt.CapsLockModifier`).