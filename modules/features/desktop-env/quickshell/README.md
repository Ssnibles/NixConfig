# Quickshell — Module Reference & Development Guide

This directory contains the [Quickshell](https://quickshell.outfoxxed.me/) configuration for the unified status bar (`bar.qml`), the **Command Centre** dashboard, the Wayland **Lock Screen**, the **Notification system**, and shared UI primitives (pills, tooltips, sliders).

All QML code lives in `config/` and is symlinked to `~/.config/quickshell/` by `nixos.liveLinks`. **QML edits apply immediately on the next quickshell restart** — no Nix rebuild needed for standard QML modifications. Only `Colours.qml` is generated directly by Nix from system theme tokens and requires a rebuild to update.

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
| **Config Symlinks** | `nixos.liveLinks` (`quickshell-config`) links every file in `config/*` into `~/.config/quickshell`. |
| **Permissions** | Symlinks and target directories are owned by the active user. |

Subdirectories are symlinked as directories, so a new file inside `bar/`, `common/`, `services/` and so on is live immediately. A new file at the top level of `config/` only appears in `~/.config/quickshell` after a `nixos-rebuild switch` (activation recreates the per-file links). Add new singletons under `services/` or another existing directory to avoid that rebuild.

### 1.1 Directory layout

The QML source is grouped by component rather than kept flat:

```text
config/
├── shell.qml            # Root Scope: loads the bar, overlays and lock screen
├── Config.qml           # Settings singleton (literals only)
├── Colours.qml          # Nix-generated theme tokens
├── Utils.js             # Shared JavaScript helpers
├── qmldir               # Manifest for cross-directory types
├── common/              # Shared visual primitives and reusable widgets
├── services/            # State singletons, Session environment, compositor backends
├── bar/                 # Status bar and bar-only widgets
├── launcher/            # Application launcher and calculator
├── command-centre/      # Command Centre and its cards
├── notifications/       # Notification overlay
├── lock/                # Lock screen components
└── osd/                 # On-screen display overlay
```

Every subdirectory adds `import ".."` so it can use the root manifest. The manifest lists shared types by path, so a component in `bar/` can use `Card` from `common/` without a second import. Add a new cross-directory type to `config/qmldir` when you create it.

---

## 2. Entry Point & Architecture (`shell.qml`)

`shell.qml` serves as the top-level application root (`Scope`), instantiating the active status bar, notification manager, command centre, and lock screen:

```qml
Scope {
  Loader {
    source: "bar/bar.qml"
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

## 3. Configuration Reference

Three singletons split settings from facts about the machine:

| File | Holds | Edit it? |
| --- | --- | --- |
| `Config.qml` | Every layout dimension, font, timing and option. Literals only, no expressions or state. | Yes, this is the settings file |
| `Session.qml` | Facts about the running session: compositor, `$HOME`, `$USER`, hostname, resolved paths, and the environment overrides (`QS_BAR`, `QS_BAR_SIDE`, `QS_COMMAND_CENTRE_SIDE`, `QS_LOCK_STATUS_POS`) | Rarely |
| `UiState.qml` | Transient state that resets on restart: what is open, which screen owns it, tray toggles | No |

Anything derived (`Session.barType`, `Session.hasTopBar`, `Session.lockWallpaperPath`) lives in `Session`, so `Config` stays a flat list of values you can scan and change.

### 3.1 Spacing, borders and fonts

All padding and gaps use a shared scale. From `spaceXs` up each step multiplies
by the golden ratio (1.618) and rounds to even pixels; `space2xs` is the half
step for micro gaps. Nested spacing therefore keeps the same visual rhythm.

| Token | Value | Typical use |
| --- | --- | --- |
| `space2xs` | `2` | Related text lines and optical nudges |
| `spaceXs` | `4` | Micro insets and compact control padding |
| `spaceSm` | `6` | Icon-to-label gaps, compact chips and button clusters |
| `spaceMd` | `10` | Row gaps, list padding and standard pill padding |
| `spaceLg` | `16` | Card padding, section gaps and overlay margins |
| `spaceXl` | `26` | Hero padding, lock blocks and screen edges |
| `space2xl` | `42` | Wide screen margins and popup offsets |
| `space3xl` | `68` | Large vertical offsets such as the OSD |

| Token | Value | Typical use |
| --- | --- | --- |
| `borderWidth` | `1` | Standard outline on cards, pills and controls |
| `borderWidthFocus` | `2` | Focused input outline |
| `itemRadiusXs` | `4` | Day cells, sliders, tray buttons |
| `itemRadiusSm` | `6` | Small pills and menu rows |
| `itemRadiusMd` | `10` | Cards, popups, inputs and cover art |

| Property | Default | Purpose |
| --- | --- | --- |
| `monoFont` | `"JetBrainsMono Nerd Font"` | Icons, numbers, monospaced text |
| `sansFont` | `"SF Pro Text"` | UI text, notifications, titles |
| `serifFont` | `"Instrument Serif"` | Clocks, headers |

These three are fallbacks: Nix writes the real families into `Colours.qml`, and `Session.monoFont` / `sansFont` / `serifFont` prefer the generated value. Change the font in the Nix theme, not here.

### 3.2 Status Bars
| Property | Default | Purpose |
| --- | --- | --- |
| `barWidth` | `42` | Niri bar width (px) |
| `barSide` | `"left"` | Default Niri bar screen edge (`"left"` \| `"right"`); `QS_BAR_SIDE` overrides it in `Session` |
| `barMarginTop/Bottom/Left/Right` | `10 / 10 / 4 / 4` | Outer padding around Niri bar |
| `barSpacing` | `10` | Vertical gap between widget groups |
| `volBarHeight` | `64` | Volume bar widget height |
| `wifiMaxTextLength` | `90` | Maximum network SSID display width |
| `barHeight` | `34` | MangoWC top bar height (px) |
| `minWorkspaces` | `5` | Minimum workspace slots (MangoWC and Hyprland) |
| `barShowClock` | `true` | Show the clock |
| `barShowCommandCentre` | `true` | Show the Command Centre button |
| `barShowLayout` | `true` | Show the tiling layout pill (MangoWC only anyway) |
| `barShowWindowTitle` | `true` | Show the active window title |
| `barShowWorkspaces` | `true` | Show the workspace dots |
| `barShowTray` | `true` | Show the system tray |
| `barShowMedia` | `true` | Show the media button |
| `barShowVolume` | `true` | Show the volume pill |
| `barShowNetwork` | `true` | Show the network pill |
| `barShowBattery` | `true` | Show the battery pill |

The compositor (`Session.wm`) and everything derived from it (`barType`, `hasTopBar`, `hasLeftBar`, `hasRightBar`) live in `Session`. The `barShow*` flags reach the widgets through their `shown` property, so hiding a widget in the bar leaves the same widget working in the Command Centre and lock screen.

### 3.3 Command Centre (`CommandCentre.qml`)

Visibility lives in `UiState.commandCentreVisible` and is driven by IPC or the bar button.

| Property | Default | Purpose |
| --- | --- | --- |
| `commandCentreWidth` | `500` | Width of slide-out panel (px) |
| `commandCentreRadius` | `16` | Panel corner rounding radius |
| `commandCentreCardRadius` | `10` | Inner section card corner radius |
| `commandCentreClockFormat` | `"HH:mm"` | Header clock format |
| `commandCentreDateFormat` | `"dddd, MMMM d"` | Header date format |
| `alwaysShowMediaCard` | `true` | Show media player card even when idle |
| `ccShowSinkSwitcher` | `true` | Show the PipeWire output chips |
| `ccSinkSwitcherAboveVolume` | `false` | Put the chips above the volume slider instead of below |
| `ccShowAudioMixer` | `true` | Show the mixer shortcut that leads the output row |
| `ccAudioMixerLabel` | `""` | Label beside the mixer gear; empty renders the gear alone |
| `ccMicSliderMode` | `"smart"` | Microphone slider visibility: `"smart"` while a capture stream is active, `"always"`, or `"hidden"` |
| `ccShowBrightnessSlider` | `true` | Show the brightness slider |
| `mediaRotationDuration` | `4000` | Album art rotation duration (ms) |
| `mediaSeekDebounceMs` | `200` | Seeking debounce delay (ms) |

### 3.4 Lock Screen (`LockScreen.qml`)
| Property | Default | Purpose |
| --- | --- | --- |
| `lockAvatarPath` | `""` | Avatar image; empty uses the bundled `assets/avatar.png` |
| `lockFallbackIcon` | `"󰀉"` | Fallback glyph when avatar image is absent |
| `lockWallpaperPath` | `""` | Wallpaper image; empty uses `$HOME/Pictures/wallpaper` |
| `lockClockFormat` | `"HH:mm"` | Time display format |
| `lockDateFormat` | `"dddd, MMMM d"` | Date display format |
| `commandCentreCardRadius` | `10` | Authentication card corner radius (shared with the Command Centre) |
| `lockInputRadius` | `10` | Password input box radius |
| `lockBackgroundDimming` | `0.8` | Dark background overlay opacity (0.0–1.0) |
| `lockBlurPercentage` | `0.5` | Wallpaper GPU blur amount (0.0–1.0) |
| `lockStatusPosition` | `"top-right"` | Badge corner, or `"split"` / `"corners"`; `QS_LOCK_STATUS_POS` overrides it in `Session` |
| `lockStatusMargin` | `26` | Badge distance from the screen edge |
| `lockStatusSpacing` | `10` | Gap between clustered badges |

### 3.5 Popups & Tooltips (`SharedTooltipWindow.qml`)
| Property | Default | Purpose |
| --- | --- | --- |
| `popupGap` | `42` | Distance from bar to popup card |
| `popupMaxWidth` | `280` | Default card width |
| `popupRadius` | `10` | Popup card corner radius |
| `popupContentMargins` | `16` | Padding inside popups |
| `popupContentSpacing` | `6` | Gap between tooltip detail lines |
| `popupShowDelay` | `150` | Hover delay before showing popup (ms) |
| `popupFadeMs` | `120` | Fade transition duration (ms) |
| `popupGraceMs` | `700` | Grace window for instant-swapping between adjacent popups |

### 3.6 Notifications (`NotificationOverlay.qml` & `NotificationService.qml`)
| Property | Default | Purpose |
| --- | --- | --- |
| `notifPosition` | `"top-right"` | Placement on screen (`"top-left"`, `"top-right"`, `"bottom-left"`, etc.) |
| `notifMarginX` | `16` | Horizontal offset margin from screen edge (px) |
| `notifMarginY` | `16` | Vertical offset margin from screen edge (px) |
| `notifTimeoutMs` | `5000` | Default display duration per popup (ms) |
| `notifTimeoutLowMs` | `3000` | Duration for low-urgency notifications (ms) |
| `notifTimeoutCriticalMs` | `0` | Duration for critical notifications (`0` = persistent) |
| `notifMaxVisible` | `5` | Maximum active popup count on screen |
| `notifMaxHistory` | `30` | Maximum history items retained in `NotificationService` |
| `notifWidth` | `320` | Notification card width (px) |
| `notifRadius` | `10` | Notification card corner radius |
| `notifCardMargins` | `16` | Internal card padding (px) |
| `notifSpacing` | `10` | Spacing between stacked cards (px) |
| `notifIconSize` | `40` | Icon/avatar dimension for standard notifications (px) |
| `notifMediaIconSize` | `48` | Icon/avatar dimension for media notifications (px) |
| `notifIconRadius` | `10` | Corner radius for notification icon/avatar preview |
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

### 3.7 System Tray
| Property | Default | Purpose |
| --- | --- | --- |
| `trayHiddenApps` | `["nm-applet", "vicinae"]` | Case-insensitive app IDs, titles or substrings hidden by default |
| `trayLeftClickAction` | `"focus"` | `"focus"` (activate and focus the window), `"activate"` (SNI activate only) or `"menu"` |
| `trayIconSize` | `15` | Tray icon size (px) |
| `trayButtonSize` | `20` | Tray button hit area (px) |
| `traySpacing` | `4` | Gap between tray buttons |
| `trayMenuWidth` | `240` | Width of the tray context menu |
| `trayShowAppIdInMenu` | `true` | Show the SNI app ID in the menu header |
| `trayAllowSessionHide` | `true` | Allow hide/unhide actions in the tray menu |
| `UiState.trayEnabled` | `true` | Runtime on/off (IPC `tray toggle`) |
| `UiState.trayShowExpandButton` | `true` | Show the expand arrow when items are hidden |
| `UiState.trayExpanded` | `false` | Whether the hidden section is open |

### 3.8 External Commands
| Property | Default | Purpose |
| --- | --- | --- |
| `cmdMixer` | `["pavucontrol"]` | Audio mixer |
| `cmdNetworkManager` | `["kitty", "--single-instance", "-e", "nmtui"]` | Network tool |
| `cmdBluetoothManager` | `["blueman-manager"]` | Bluetooth manager |
| `cmdLock` | `["quickshell", "ipc", "call", "lockscreen", "lock"]` | Lock action |
| `cmdSleep` / `cmdReboot` / `cmdPoweroff` | `["systemctl", ...]` | Power actions |
| `cmdTerminal` | `["kitty", "-e"]` | Prefix used by the launcher's "run in terminal" and by `.desktop` terminal entries |
| `cmdClipboard` | `["wl-copy"]` | Clipboard writer used by the calculator and copy actions |

### 3.9 Runtime State (`UiState.qml`)
Nothing here is configuration; it all resets when the shell restarts.

| Property | Default | Purpose |
| --- | --- | --- |
| `barVisible` | `true` | Bar shown (IPC `bar toggle`) |
| `commandCentreVisible` | `false` | Command Centre open |
| `launcherVisible` | `false` | Launcher open |
| `targetScreen` | `null` | Screen the next overlay opens on |
| `lastActiveScreen` | `null` | Last screen the pointer entered |
| `runtimeHiddenTrayApps` / `runtimeUnhiddenTrayApps` | `[]` | Session-only tray hide overrides, shared across monitors |


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
- **Features**: Powered by singletons (`WmService`, `ClockService`, `AudioService`, `NetworkService`, `BatteryService`, `MediaService`) to render workspace dots, layout switcher, active window titles, system status indicators, clock, and `SharedTooltipWindow`.

---

### 5.2 Services & Infrastructure

#### `WmService.qml`
- **Role**: Unified `pragma Singleton` bridging active compositor backends (`MangoService`, `HyprlandService`, `NiriService`) based on `Session.wm`.
- **Exposes**: `currentTitle`, `workspacesDependency`, `getWorkspaces(outputName)`, `focusWorkspace(id)`, `getLayoutSymbol(outputName)`, `getLayoutInfo(symbol)`, `setLayout(symbol)`, `nextLayout()`, and active/cursor monitor detection (`resolveTargetScreen(callback)`, `cancelScreenQuery()`, `queryingScreen`).

#### `AudioService.qml`
- **Role**: `pragma Singleton` for PipeWire output sinks and the default microphone source.
- **Exposes**: `audioSink`, `audioSinks`, `selectAudioSink(node)`, `sinkDisplayName(node)`, `sinkLabel(node)`, `volume`, `muted`, `volumePercent`, `volumeIcon`, `toggleMute()`, `setVolume(val)`, `setVolumeDebounced(val)`, `stepVolume(dir)`, `openMixer()`, `hasMic`, `micVolume`, `micMuted`, `micVolumePercent`, `micIcon`, `micInUse`, `toggleMicMute()`, `setMicVolume(val)`, `setMicVolumeDebounced(val)`, `stepMicVolume(dir)`.

#### `BrightnessService.qml`
- **Role**: `brightnessctl` and sysfs backlight control. Emits `osdRequested()` when the level changes.
- **Exposes**: `brightness`, `brightnessAvailable`, `brightnessPercent`, `refreshBrightness(notifyOsd)`, `setBrightness(val)`, `stepBrightness(dir)`.

#### `NetworkService.qml`
- **Role**: Wired and Wi-Fi state from `Quickshell.Networking`.
- **Exposes**: `netIcon`, `netText`, `netColour`, `netTitle`, `netDetails`, `openNetworkManager()`.

#### `BatteryService.qml`
- **Role**: Battery telemetry from UPower.
- **Exposes**: `batPresent`, `batPct`, `batCharging`, `batPlugged`, `batIcon`, `batColour`, `batTitle`, `batDetails`.

#### `BluetoothService.qml`
- **Role**: Adapter and connected-device state from `Quickshell.Bluetooth`.
- **Exposes**: `btIcon`, `btColour`, `btStatusText`, `btTitle`, `btDetails`, `toggleBluetooth()`, `openBluetoothManager()`.

#### `TrayService.qml`
- **Role**: System tray items plus the per-session hidden/unhidden lists shared across monitors.
- **Exposes**: `trayAllItems`, `trayVisibleItems`, `trayHiddenCount`, `trayHasContent`, `trayItemKey(item)`, `isTrayItemHidden(item)`, `toggleTrayItemHidden(item)`.

#### `SystemService.qml`
- **Role**: OSD state and the `"system"` / `"tray"` IPC targets. It observes the hardware services rather than owning their state.
- **Exposes**: `osdVisible`, `osdKind`, `osdIcon`, `osdLabel`, `osdValue`, `osdMuted`, `showOsd(kind)`, plus the `volumeUp`, `volumeDown`, `toggleMute`, `micUp`, `micDown`, `toggleMicMute`, `brightnessUp`, and `brightnessDown` IPC actions.

#### `NotificationIcons.qml`
- **Role**: Resolves notification icons, avatars, and fallback glyphs, and caches ephemeral `/tmp/` images.
- **Exposes**: `cacheDir`, `extractRawImage(notification)`, `resolvePrimary(uid, rawUrl)`, `resolveFallback(appIcon, desktopEntry, appName)`, `resolveGlyph(...)`, and the `imageCopied(uid, url)` signal.

#### `TrayMenu.qml`
- **Role**: Tray context menu rendered inside the shared tooltip layer. Owns the DBusMenu entry pills and the hide/unhide actions.

#### `ClockService.qml`
- **Role**: Central minute-aligned clock `pragma Singleton` ingested by `ClockWidget`, `CommandCentre`, and `LockScreen`.
- **Exposes**: `now`, `timeStr`, `hourStr`, `minuteStr`, `ordinalDateStr`, `ccTimeStr`, `ccTime12Str`, `ccDateStr`, `lockTimeStr`, `lockDateStr`.

#### `MangoService.qml`, `HyprlandService.qml`, `NiriService.qml`
- **Role**: Compositor-specific IPC backends loaded dynamically by `WmService.qml`.

#### `WindowFocuser.qml`
- **Role**: Singleton that activates a window from a notification / MPRIS player / app descriptor.
- **Strategy**: Uses Quickshell's native `ToplevelManager` when available; otherwise queries and scores the compositor's IPC (`mmsg` / `niri` / `hyprctl`) directly in QML (replaces the old inline Node fallback). Exposes `focus(patterns)` and `focusSource(source)`.

#### `NotificationService.qml`
- **Role**: Central notification daemon, MPRIS track-toast emitter, and state manager.
- **Features**: Subscribes to `Quickshell.Services.Notifications`, retains live `Notification` objects while in active or history models, manages auto-dismiss timers and hover pausing, and handles action invocation and sender window focusing. Icon, avatar, and glyph resolution lives in `NotificationIcons.qml`.

#### `Utils.js`
- **Role**: Shared JavaScript utility library (`.pragma library`).
- **Features**: `findFirst`, `findBatteryDevice`, `findActivePlayer`, `resolveMprisPlayer`, `cyclePlayer`, `pad2`, `formatTime`, `cleanTrackTitle`, `prettifyAppName`, `formatActiveTitle`, `envChoice`, `overlayMargins`, and icon helpers (`volumeIcon`, `micIcon`, `batteryIcon`).

---

### 5.3 Overlays & Standalone Screens

#### `CommandCentre.qml`
- **Role**: Slide-out quick settings dashboard and system metrics panel.
- **IPC Target**: `"command-centre"` (functions: `toggle()`, `open()`, `close()`).
- **Multi-Monitor Cursor Tracking**: Delegates active-screen detection to `WmService.resolveTargetScreen(...)` and slides out on that specific monitor while rendering a transparent dismiss overlay across all other screens.
- **Structure**: `CommandCentre.qml` owns the per-screen overlay windows, the slide and fade animation, and the IPC surface. The panel contents live in `CommandCentreCard.qml`: header clock and date (`ClockService`), status pills (Wi-Fi, Ethernet, Battery, Bluetooth), system sliders (`ControlSliderRow` bound to `AudioService` and `BrightnessService`), the `AudioSinkPicker` output chips, the full MPRIS `MediaCard`, the `NotificationHistoryCard` list (`NotificationService`), and `PowerButtons`.

#### `OsdOverlay.qml`
- **Role**: Floating bottom-centre On-Screen Display pill driven by `SystemService`.
- **Features**: Automatically pops up on the active monitor when output volume, mute, microphone mute/volume, or screen brightness changes (suppressed while `CommandCentre` is open).

#### `LockScreen.qml`
- **Role**: Wayland session screen locker built on `WlSessionLock` and `WlSessionLockSurface`.
- **IPC Target**: `"lockscreen"` (functions: `lock()`, `unlock()`, `toggle()`).
- **Features**: Lazy loading architecture, PAM authentication (`PamContext`), primary monitor interactive password prompt (`LockAuthCard`) with user avatar, real-time accent highlight on keystrokes, rotating authentication spinner, password peek/reveal eye toggle, Caps Lock warning & error shake animation, a compact now-playing row (`LockMediaRow`) with previous, play/pause and next controls, placed below the password input, secondary screen display lock graphics (`LockSecondaryScreen`) with live typing indicator & the same compact now-playing row, customisable status pill cluster (`LockStatusCluster`) docked to any corner (default `"top-right"`, `"top-left"`, `"bottom-right"`, `"bottom-left"`, or `"split"` / `"corners"` via `Config.lockStatusPosition` or `QS_LOCK_STATUS_POS`), background wallpaper with customisable GPU blur (`MultiEffect`) and dimming, and system power actions (Sleep/Suspend, Reboot, Power Off).

#### `Launcher.qml`
- **Role**: Layer-shell launcher and calculator. It opens on the active screen, filters desktop entries from `launcher/desktop-entries.sh`, and shows a calculator result for a valid expression.
- **IPC Target**: `"launcher"` (functions: `toggle()`, `open()`, `close()`).
- **Window**: Fixed 760 x 500 card centred on the active screen. The result list scrolls with the wheel, trackpad, or keyboard, and the selected row stays in view.
- **Keyboard**: Up/Down or Ctrl+K/Ctrl+J move the selection. Ctrl+Enter opens the actions menu for the selected application or calculator result. Escape closes the actions menu first, then the launcher.
- **Default Keybind**: `SUPER + Shift + Space` in MangoWC, Hyprland, and Niri.
- **Actions**: Per-app `[Desktop Action]` entries are read from the `.desktop` file, followed by presets: Launch, Run in terminal, Copy command, Copy desktop file path, and Copy desktop ID. Calculator results offer Copy result and Copy expression.
- **Calculator**: `launcher/Calc.js` wraps the vendored [expr-eval](https://github.com/silentmatt/expr-eval) library (`launcher/expr-eval.js`, MIT). It supports arithmetic, `^`, functions such as `sqrt`, `sin`, and `log`, and the constants `pi`, `e`, and `tau`. Pressing Enter copies the result to the clipboard.

#### `NotificationOverlay.qml` & `NotificationCard.qml`
- **Role**: Screen overlay and card delegate rendering active notification toasts and history items.
- **Features**: Stack layout driven by `NotificationService`, animated entry/exit, action buttons, avatar/icon previews with fallback glyphs, and click-to-dismiss or focus.

---

### 5.4 Widgets & UI Components

#### `Pill.qml`
- **Role**: Standardised rounded pill container for bar widgets and inline action pills.
- **Properties**: `horizontal`, `padding`, `pillHeight`, `baseColour`, `hoverColour`, `hoverHighlight`, `pillColour`, `clickable`, `acceptedButtons`, `shown`, `hovered`, `radius`; signals `clicked(var mouse)`, `wheel(var wheel)`. Includes built-in hover/border colour transitions, auto-sizing, and optional pointer click/scroll handling. `shown` is the visibility gate the bar uses to hide a widget without overriding the widget's own visibility rules.

#### `Divider.qml`
- **Role**: 1px horizontal rule used to separate sections.

#### `StatusPill.qml`
- **Role**: Icon plus optional label inside a `Pill`, with an optional tooltip. Backs the battery, Bluetooth, and network widgets and the lock screen hostname and volume badges, so they share one layout and one tooltip implementation.
- **Properties**: `icon`, `iconColour`, `iconSize`, `iconFont`, `label`, `showLabel` (defaults to `horizontal`), `labelColour`, `labelSize`, `labelFont`, `labelBold`, `labelMaxWidth`, `rowRotation`, `rowSpacing`, `interactive`, `sharedWindow`, `tooltipEnabled`, `tooltipTitle`, `tooltipDetails`. Set `interactive: false` for read-only badges and `rowRotation: 270` for the vertical side bar.

#### `HostnamePill.qml` and `VolumePill.qml`
- **Role**: Read-only lock screen badges built on `StatusPill`, shared by the clustered and split layouts.

#### `ControlSliderRow.qml`
- **Role**: Icon, slider, and percentage row used by the Command Centre controls.
- **Properties**: `icon`, `alert`, `accent`, `iconClickable`, `sliderValue`, `percentText`; signals `iconClicked()`, `sliderMoved(real value)`.

#### `AudioSinkPicker.qml`
- **Role**: PipeWire output switcher: a chip per sink with the current output marked, led by the mixer shortcut. Chips switch on the first click and wrap onto another line when there are many outputs, so expanding the picker never reflows the rest of the panel.
- **Placement**: `CommandCentreCard.qml` loads it above or below the volume slider from `Config.ccSinkSwitcherAboveVolume`, using one shared component definition so both positions stay identical.
- **Mixer**: leads the row so it never reads as another output. Icon-only by default; set `Config.ccAudioMixerLabel` to add a label, or `Config.ccShowAudioMixer` to drop the shortcut. Clicking it closes the panel before opening the mixer, since the panel would cover it.
- **Properties**: `labelMaxWidth` (default `150`); gives up its space to elision rather than pushing the row wider.
- **Labels**: use `AudioService.sinkLabel(node)`, which prefers PipeWire's `node.nick` (`DAWN PRO2`) over the longer `node.description` (`DAWN PRO2 Analog Stereo`).

#### `NotificationHistoryCard.qml`
- **Role**: Notification history list, mute toggle, and clear button used by the Command Centre.

#### `LockAuthCard.qml`
- **Role**: Interactive authentication card used on the primary lock screen display. It contains the compact now-playing row below a divider when media is active.
- **Properties**: `session`, `shakeOffset`, `capsLockOn`, `revealPassword`; functions `submitEnteredPassword()`, `cancelInput()`, `updateCapsLock(modifiers)`; signal `backgroundFocusRequested()`.

#### `LockMediaRow.qml`
- **Role**: Compact now-playing row shared by the auth card and the secondary lock screen. Shows cover art, title, artist and previous, play/pause and next controls.
- **Properties**: `hasMedia`.

#### `LockStatusCluster.qml` and `LockSecondaryScreen.qml`
- **Role**: Lock screen status pills in bar order (hostname, volume, network, battery), and the read-only content shown on non-primary displays.

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
- **Properties**: `horizontal`, `screen`, `shown`. Toggles `UiState.commandCentreVisible`, automatically setting the target screen to the parent bar's monitor.

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
- **Properties**: `source`, `sourceSize`, `radius`; exposes `ready` and a `sourceError()` signal for fallback chains.

#### Standard Bar Widgets
- **`ClockWidget.qml`**: Time/date stack ingested from `ClockService` with click-to-popup calendar (`CalendarPopup.qml`).
- **`WindowTitleWidget.qml`**: Active window title ingested from `WmService`.
- **`WorkspacesWidget.qml`**: Interactive workspace indicators connected to `WmService`.
- **`LayoutWidget.qml`**: Tiling layout selector connected to `WmService` (auto-shown on MangoWC). The option list lives in `LayoutPopup.qml`.
- **`SystemTrayWidget.qml`**: StatusNotifierItem (SNI) system tray pill supporting left-click activate, right-click menu (rendered by `TrayMenu.qml`), scroll, and hover tooltips. Automatically hides when no tray items are registered.
- **`MediaWidget.qml`**: MPRIS playback bar button ingested from `MediaService`.
- **`VolumeWidget.qml`**: PipeWire volume control widget ingested from `AudioService`.
- **`NetworkWidget.qml`**: Network connection monitor displaying Wi-Fi SSID and signal strength. Right-click launches `nmtui`. Set `interactive: false` to render it as a read-only `StatusPill` (used on the lock screen).
- **`BluetoothWidget.qml`**: Bluetooth adapter status and device indicator. Right-click launches `blueman-manager`.
- **`BatteryWidget.qml`**: Laptop battery charge state and status indicator powered by UPower. Auto-hides on desktop systems without batteries. Set `interactive: false` to render it as a read-only `StatusPill` (used on the lock screen).

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
- **Shared window state**: `SharedTooltipWindow` exposes `activeTip` (the tooltip under the cursor), `shownTip` (the card still on screen while it fades out), `recentlyActive`, `isOpen`, and `openNow()` / `closeNow()` for widgets that drive a popup directly, such as the tray menu.

### `SharedTooltipWindow.qml`
A single layer window per display hugging `Config.barSide`. Handles popup positioning, clamping to screen boundaries, smooth fade transitions, and instant-swapping between adjacent widgets.

### `TooltipCard.qml`
The default tooltip card (icon and title header, divider, one line per detail) rendered by `SharedTooltipWindow` when a tooltip has no custom content.

---

## 7. How to Add New Modules / Widgets

Follow these steps to create and register a new status bar widget or overlay component:

### Step 1: Create the Component File
Create a new QML file in the directory that matches its role, e.g. `config/bar/CpuWidget.qml` for a bar widget, `config/common/` for a shared primitive, or `config/services/` for a singleton. Add `import ".."` so shared types from the manifest are available:

```qml
import Quickshell
import QtQuick
import ".."
import "../Utils.js" as Utils

Pill {
  id: root
  property var sharedWindow: null

  pillColour: mouseArea.containsMouse ? Colours.bgRaised : Colours.bgSubtle
  border.color: Colours.border
  border.width: Config.borderWidth

  Row {
    spacing: Config.spaceSm
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
Open `bar/bar.qml` and instantiate your component inside `startSection` or `endSection`:

```qml
CpuWidget {
  horizontal: root.isHorizontal
  sharedWindow: sharedTipWindow
  Layout.alignment: Qt.AlignCenter
}
```

### Step 4: Test
Because `nixos.liveLinks` symlinks the whole `config/` directory into `~/.config/quickshell/`, newly created QML files are picked up automatically after a `sudo nixos-rebuild switch` — no manual `ln -s` step is needed. (The symlinks are re-created on activation, so files deleted from the repo are also pruned.)

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

Quickshell normally reloads by itself when a file it has compiled changes. Two
caveats, both easy to trip over:

- Only a content change triggers the reload. `touch` alone does not.
- Only compiled files are watched. A component that has never been shown, such
  as a popup you have not opened yet, is not watched, so a new or heavily
  edited file can appear to be ignored.

When in doubt, save an unrelated file such as `shell.qml` (even adding and
removing a newline) to force a full reload, or restart the process.

---

## 9. Tooling & Tests

- **Unit tests** (`tests/*.test.js`): pure-JS tests for the helpers in `Utils.js` and the launcher calculator. Run locally with:
  ```bash
  node --test modules/features/desktop-env/quickshell/tests/*.test.js
  ```
  These also run in the `Validate Nix Flake` GitHub Actions workflow and need no Nix or Qt.

- **Editor / LSP support**: `config/qmldir` is the real manifest for the config module. It lists every shared type and its path, so `qmllint` and `qmlls` can resolve components across directories. Quickshell also uses it at runtime; a new cross-directory type must be added there.

- **Vendored expr-eval**: `config/launcher/expr-eval.js` is expr-eval 2.0.2 with two local changes: the UMD wrapper is replaced with top-level exports so QML can import it, and `ParserState.next` separates an assignment from its return expression because Qt V4 evaluates the original form incorrectly. The MIT licence is in `expr-eval.LICENSE`.

- **Static analysis**: every QML file declares `pragma ComponentBehavior: Bound`, and delegates declare their model context as `required property ...`. Nested children inside a delegate reach the delegate's own properties through its `id` (for example `dayCell.modelData`), which keeps `qmllint` free of unqualified-access warnings. With the manifest above, `qmllint` is clean apart from a handful of Quickshell/`Qt` type-resolution false positives (`PanelWindow`, `margins {}`, `Qt.CapsLockModifier`, and the `values` property of `UntypedObjectModel`).