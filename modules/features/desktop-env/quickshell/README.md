# Quickshell — Module Reference & Development Guide

This directory contains the [Quickshell](https://quickshell.outfoxxed.me/) configuration for status bars (`niri-bar.qml` and `mangowc-bar.qml`), the **Command Center** dashboard, the Wayland **Lock Screen**, the **Notification system**, and shared UI primitives (pills, tooltips, sliders).

All QML code lives in `config/` and is symlinked to `~/.config/quickshell/` by Nix activation scripts. **QML edits apply immediately on the next quickshell restart** — no Nix rebuild needed for standard QML modifications. Only `Colors.qml` is generated directly by Nix from system theme tokens and requires a rebuild to update.

---

## Table of Contents

1. [How the Module is Wired Up (`default.nix`)](#1-how-the-module-is-wired-up-defaultnix)
2. [Entry Point & Architecture (`shell.qml`)](#2-entry-point--architecture-shellqml)
3. [Configuration Reference (`Config.qml`)](#3-configuration-reference--configqml)
4. [Theme Colors (`Colors.qml`)](#4-theme-colors--colorsqml)
5. [Module Catalog & Component Reference](#5-module-catalog--component-reference)
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
| **`Colors.qml`** | Generated from `config.theme.colors` into `~/.config/quickshell/Colors.qml` via Hjem. |
| **Config Symlinks** | Activation script (`quickshell-config`) creates `~/.config/quickshell` and symlinks every file in `config/*`. |
| **Permissions** | Symlinks and target directories are owned by the active user. |

---

## 2. Entry Point & Architecture (`shell.qml`)

`shell.qml` serves as the top-level application root (`Scope`), instantiating the active status bar, notification manager, command center, and lock screen:

```qml
Scope {
  Loader {
    source: (bar === "niri") ? "niri-bar.qml" : "bar.qml"
  }
  NotificationOverlay { }
  CommandCenter { }
  LockScreen { }
}
```

- **Status Bar Loading**: Set `QS_BAR=niri` for the vertical Niri bar; defaults to the unified `bar.qml` top bar (which connects to `WmService` for DWL, MangoWC, River, Hyprland, etc.).
- **Notification Overlay**: Global notification stack present on every display.
- **Command Center**: Slide-out dashboard overlay controllable via IPC.
- **Lock Screen**: Wayland session lock (`WlSessionLock`) with PAM authentication.

---

## 3. Configuration Reference (`Config.qml`)

`Config.qml` is a `pragma Singleton` holding all global layout dimensions, fonts, timings, and component options.

### 3.1 Fonts
| Property | Default | Purpose |
| --- | --- | --- |
| `monoFont` | `Colors.monoFont` \| `"JetBrainsMono Nerd Font"` | Icons, numbers, monospaced text |
| `sansFont` | `"SF Pro Text"` | UI text, notifications, titles |
| `serifFont` | `Colors.serifFont` \| `"Instrument Serif"` | Clocks, headers |

### 3.2 Status Bars
| Property | Default | Purpose |
| --- | --- | --- |
| `barWidth` | `42` | Niri bar width (px) |
| `barSide` | `"left"` | Niri bar screen edge (`"left"` \| `"right"`) |
| `barMarginTop/Bottom/Left/Right` | `8 / 8 / 4 / 4` | Outer padding around Niri bar |
| `barSpacing` | `8` | Vertical gap between widget groups |
| `volBarHeight` | `64` | Volume bar widget height |
| `wifiMaxTextLength` | `90` | Maximum network SSID display width |
| `barHeight` | `34` | MangoWC top bar height (px) |
| `mangowcMinWorkspaces` | `5` | Minimum workspace tag slots in MangoWC |

### 3.3 Command Center (`CommandCenter.qml`)
| Property | Default | Purpose |
| --- | --- | --- |
| `commandCenterVisible` | `false` | Controls overlay visibility (toggleable via IPC) |
| `commandCenterWidth` | `500` | Width of slide-out panel (px) |
| `commandCenterRadius` | `16` | Panel corner rounding radius |
| `commandCenterCardRadius` | `12` | Inner section card corner radius |
| `commandCenterClockFormat` | `"HH:mm"` | Header clock format |
| `commandCenterDateFormat` | `"dddd, MMMM d"` | Header date format |
| `alwaysShowMediaCard` | `true` | Show media player card even when idle |
| `mediaRotationDuration` | `4000` | Album art rotation duration (ms) |
| `mediaSeekDebounceMs` | `200` | Seeking debounce delay (ms) |

### 3.4 Lock Screen (`LockScreen.qml`)
| Property | Default | Purpose |
| --- | --- | --- |
| `lockAvatarPath` | `Quickshell.shellDir + "/assets/avatar.png"` | Path to user avatar image |
| `lockFallbackIcon` | `"󰀉"` | Fallback glyph when avatar image is absent |
| `lockWallpaperPath` | `"file://" + $HOME + "/Pictures/wallpaper"` | Lock screen wallpaper image |
| `lockClockFormat` | `"hh:mm"` | Time display format |
| `lockDateFormat` | `"dddd, MMMM d"` | Date display format |
| `lockCardRadius` | `12` | Authentication card corner radius |
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

### 3.6 Notifications (`NotificationOverlay.qml` & `NotificationStore.qml`)
| Property | Default | Purpose |
| --- | --- | --- |
| `notifPosition` | `"top-left"` | Placement on screen |
| `notifTimeoutMs` | `5000` | Display duration per popup (ms) |
| `notifMaxVisible` | `5` | Maximum active popup count on screen |
| `notifMaxHistory` | `24` | Maximum history items retained in `NotificationStore` |
| `notifWidth` | `300` | Notification card width (px) |
| `notifRadius` | `12` | Notification card corner radius |

---

## 4. Theme Colors (`Colors.qml`)

`Colors.qml` is automatically generated by Nix based on the current theme (`config.theme.colors`). Available color tokens:

| Token | Semantic Purpose |
| --- | --- |
| `Colors.bg` | Primary background surface |
| `Colors.bgRaised` | Elevated card & modal container backgrounds |
| `Colors.bgSubtle` | Subtle highlight / track backgrounds |
| `Colors.border` | Border lines and dividers |
| `Colors.fg` / `Colors.fgMid` / `Colors.fgDim` | Primary, secondary, and muted text |
| `Colors.accent` | Active state accent color |
| `Colors.teal` / `purple` / `green` / `yellow` / `red` / `orange` | Status and semantic accent colors |

---

## 5. Module Catalog & Component Reference

### 5.1 Bars

#### `niri-bar.qml`
- **Role**: Vertical side bar for Niri window manager.
- **Features**: `PanelWindow` hugging `Config.barSide`, displaying clock, active window title, workspace list, system control pills, and hosting `SharedTooltipWindow`.

#### `bar.qml`
- **Role**: Consolidated horizontal top bar for Wayland compositors (DWL, MangoWC, River, Hyprland, etc.).
- **Features**: Powered by `WmService.qml` to render workspace dots, active window titles, system status indicators, clock, and tooltips.

---

### 5.2 Services & Infrastructure

#### `WmService.qml`
- **Role**: Unified router bridging active compositor backends (`DwlService`, `MangoService`, `RiverService`, `HyprlandService`, `NiriService`) based on `QS_BAR`.
- **Exposes**: `currentTitle`, `getWorkspaces(outputName)`, `focusWorkspace(id)`.

#### `NiriService.qml`
- **Role**: IPC service bridging Niri window manager via `niri msg --json event-stream`.
- **Exposes**: `allWorkspaces`, `currentTitle`, `workspacesForOutput(output)`, `focusWorkspace(id)`, `formatActiveTitle(title, appId)`.

#### `NotificationStore.qml`
- **Role**: Central notification daemon state & disk cache manager.
- **Features**: Subscribes to `Quickshell.Services.Notifications`, manages active stack and history log up to `Config.notifMaxHistory`, auto-dismiss timers, and cover art disk caching (`~/.cache/quickshell/cover_art/`).

#### `MediaProgress.qml`
- **Role**: High-precision MPRIS position & playback progress estimator.
- **Features**: Pure `QtObject` tracking wall-clock drift, handling pause/resume position synchronization, and outputting `estimatedPosition` (seconds) and `progress` (0.0 to 1.0).

#### `Utils.js`
- **Role**: Shared JavaScript utility library (`.pragma library`).
- **Features**: `findFirst`, `findBatteryDevice`, `findActivePlayer`, `clamp`, `pad2`, `formatTime`, `escapeRegex`, `stripMarkup`, `cleanTrackTitle`, `prettifyAppName`, `formatActiveTitle`, and icon helpers (`volumeIcon`, `batteryIcon`, `wifiIcon`).

---

### 5.3 Overlays & Standalone Screens

#### `CommandCenter.qml`
- **Role**: Slide-out quick settings dashboard and system metrics panel.
- **IPC Target**: `"command-center"` (functions: `toggle()`).
- **Features**: Header clock & date, status pills (Wi-Fi, Ethernet, Battery, Bluetooth), system sliders (`SliderControl` for Pipewire volume & `brightnessctl` screen brightness), full MPRIS media player card with position seekbar, album art preview, and player selection, plus notification history list.

#### `LockScreen.qml`
- **Role**: Wayland session screen locker built on `WlSessionLock` and `WlSessionLockSurface`.
- **IPC Target**: `"lockscreen"` (functions: `lock()`, `unlock()`, `toggle()`).
- **Features**: Lazy loading architecture, PAM authentication (`PamContext`), primary monitor interactive password prompt with Caps Lock warning & error shake animation, secondary screen display lock graphics, background wallpaper with customizable GPU blur (`MultiEffect`) and dimming, and system power actions (Suspend, Reboot, Power Off).

#### `NotificationOverlay.qml` & `NotificationCard.qml`
- **Role**: Screen overlay rendering active notification toasts.
- **Features**: Stack layout driven by `NotificationStore`, animated entry/exit, action buttons, image/icon previews, and manual dismiss.

---

### 5.4 Widgets & UI Components

#### `Pill.qml`
- **Role**: Standardized container for bar widgets.
- **Properties**: `padding`, `pillHeight`, `pillColor`, `orientation` (`"horizontal"` \| `"vertical"`). Includes hover/active state transitions and auto-sizing.

#### `SliderControl.qml`
- **Role**: Reusable interactive horizontal range slider.
- **Properties**: `value` (0.0–1.0), `fillColor`, `snapPercent`, signal `moved(real value)`. Supports mouse drag and direct click positioning.

#### `CommandCenterButton.qml`
- **Role**: Quick toggle button component for dashboard cards.
- **Properties**: `icon`, `title`, `subtitle`, `active`, `accentColor`, signal `clicked()`.

#### Standard Bar Widgets
- **`ClockWidget.qml`**: Time/date stack with click-to-popup details.
- **`WindowTitleWidget.qml`**: Active window title displaying Niri state.
- **`WorkspacesWidget.qml`**: Interactive workspace indicators connected to `NiriService`.
- **`MediaWidget.qml`**: MPRIS playback bar button with progress indicator and play/pause controls.
- **`VolumeWidget.qml`**: PipeWire volume control widget with mute toggle, scroll adjustments, and popup control.
- **`NetworkWidget.qml`**: Network connection monitor displaying Wi-Fi SSID and signal strength. Right-click launches `nmtui`.
- **`BluetoothWidget.qml`**: Bluetooth adapter status and device indicator. Right-click launches `blueman-manager`.
- **`BatteryWidget.qml`**: Laptop battery charge state and status indicator powered by UPower. Auto-hides on desktop systems without batteries.

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
Create a new QML file in `modules/features/quickshell/config/`, e.g., `CpuWidget.qml`:

```qml
import Quickshell
import QtQuick
import "Utils.js" as Utils

Pill {
  id: root
  property var sharedWindow: null

  pillColor: mouseArea.containsMouse ? Colors.bgRaised : Colors.bgSubtle
  border.color: Colors.border
  border.width: 1

  Row {
    spacing: 6
    anchors.centerIn: parent

    Text {
      text: "󰍛"
      color: Colors.accent
      font.family: Config.monoFont
      font.pixelSize: 14
    }

    Text {
      text: "42%"
      color: Colors.fg
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
// --- CPU Widget Settings ---
readonly property int cpuPollIntervalMs: 2000
```

### Step 3: Insert into the Status Bar
Open `niri-bar.qml` (or `mangowc-bar.qml`) and instantiate your component inside `bottomCol` or `topCol`:

```qml
CpuWidget {
  sharedWindow: sharedTipWindow
}
```

### Step 4: Symlink & Test
Because activation scripts symlink `config/*` into `~/.config/quickshell/`, newly created QML files must be symlinked before Quickshell can see them:

- Run `sudo nixos-rebuild switch` (or manually symlink the file: `ln -s ~/NixConfig/modules/features/quickshell/config/CpuWidget.qml ~/.config/quickshell/`).
- Restart Quickshell to load the new widget!

---

## 8. IPC Commands & Reloading

Quickshell includes built-in IPC mechanisms. You can trigger overlays or inspect state from the command line or desktop keybindings:

```bash
# Toggle Command Center overlay
quickshell ipc call command-center toggle

# Lock screen
quickshell ipc call lockscreen lock

# Unlock screen (if active)
quickshell ipc call lockscreen unlock
```

To reload Quickshell after editing existing QML files:
```bash
pkill quickshell; quickshell &
```