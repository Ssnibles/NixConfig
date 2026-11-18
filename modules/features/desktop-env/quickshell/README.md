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
├── screenshot/          # Frozen-screen capture overlay
├── lock/                # Lock screen components
└── osd/                 # On-screen display overlay
```

Every subdirectory adds `import ".."` so it can use the root manifest. The manifest lists shared types by path, so a component in `bar/` can use `Card` from `common/` without a second import. Add a new cross-directory type to `config/qmldir` when you create it.

---

## 2. Entry Point & Architecture (`shell.qml`)

`shell.qml` serves as the top-level application root (`Scope`), instantiating the active status bar, notification manager, command centre, screenshot overlay, and lock screen:

```qml
Scope {
  Loader {
    source: "bar/bar.qml"
  }
  NotificationOverlay { }
  OsdOverlay { }
  CommandCentre { }
  ScreenshotOverlay { }
  LockScreen { }
}
```

- **Unified Status Bar (`bar.qml`)**: Automatically adapts between a horizontal top bar (MangoWC, Hyprland) and a vertical left/right side bar (Niri, or when `QS_BAR=niri`), powered by the `WmService` singleton.
- **Notification Overlay**: Global notification stack present on the active display (or all displays).
- **OSD Overlay (`OsdOverlay.qml`)**: Floating bottom-centre On-Screen Display pill for volume, microphone mute, and screen brightness changes.
- **Screenshot Overlay (`ScreenshotOverlay.qml`)**: Frozen-screen capture. `SUPER + S` grabs the whole screen at once, `SUPER + Shift + S` opens the drag selection, and `SUPER + Ctrl + S` does the same but copies text; see the overlay section below.
- **Command Centre**: Edge panel or centred bento dashboard, controllable via IPC.
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
| `itemRadiusXs` | `6` | Day cells, sliders, tray buttons |
| `itemRadiusSm` | `10` | Small pills and menu rows |
| `itemRadiusMd` | `16` | Cards, popups, inputs and cover art |
| `scrollBarWidth` | `10` | Overlay scrollbar width; the thumb is a full pill |

The display type steps follow the golden ratio from the body base: `13`, `21`,
`34`, `55`, `89`. Small labels and timestamps stay compact at `11` and `12`.

| Token | Value | Typical use |
| --- | --- | --- |
| `fontSizeXs` | `11` | Timestamps and micro labels |
| `fontSizeSm` | `12` | Secondary text |
| `fontSizeMd` | `13` | Body and notification titles |
| `fontSizeLg` | `15` | Prominent body and controls |
| `fontSizeXl` | `21` | Section headings |
| `fontSize2xl` | `34` | Sidebar clock |
| `fontSize3xl` | `55` | Bento clock and hero values |
| `fontSize4xl` | `89` | Lock screen clock |
| `displayLetterSpacing` | `2` | Letter spacing on the serif display clocks |

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
| `barHeight` | `35` | MangoWC top bar height (px) |
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

The network and Bluetooth pills open a centred status menu, sized by `statusMenuWidth` (460px) and `statusMenuHeight` (520px). The menu takes keyboard focus for the Wi-Fi password field; Escape or a click outside closes it.

### 3.3 Command Centre (`CommandCentre.qml`)

Visibility lives in `UiState.commandCentreVisible` and is driven by IPC or the bar button.

| Property | Default | Purpose |
| --- | --- | --- |
| `commandCentreLayout` | `"bento"` | Layout: `"bento"` centred widget board or `"sidebar"` edge panel |
| `commandCentreWidth` | `500` | Width of slide-out panel (px) |
| `commandCentreRadius` | `26` | Panel corner rounding radius |
| `commandCentreBentoWidthRatio` | `0.7` | Bento panel width as a fraction of the screen width |
| `commandCentreBentoHeightRatio` | `0.75` | Bento panel height as a fraction of the screen height; the board fills it |
| `commandCentreBentoNotificationRatio` | `0.325` | Notification column width as a fraction of the board width |
| `commandCentreBentoSideRatio` | `0.27` | Weather and calendar column width as a fraction of the board width |
| `commandCentreBentoScrim` | `0.55` | Backdrop opacity behind the bento panel |
| `commandCentreBentoSurface` | `false` | Draw one raised surface behind the bento board so the cards sit on a single panel |
| `commandCentreCardPadding` | `26` | Interior padding shared by every command centre card |
| `commandCentreCardSpacing` | `26` | Gap between the blocks inside each command centre card |
| `systemStatsInterval` | `2000` | CPU and memory sample interval for the bento system card (ms) |
| `weatherCacheMinutes` | `10` | Weather cache lifetime after an on-demand fetch |
| `weatherLocation` | `""` | Place name or coordinates for the weather card; empty uses the request address |
| `weatherShowForecast` | `true` | Show the three-day forecast strip in the weather card |
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
| `mediaBarTextMaxWidth` | `200` | Longest track label the bar media pill shows before eliding (px) |

### 3.4 Lock Screen (`LockScreen.qml`)
| Property | Default | Purpose |
| --- | --- | --- |
| `lockAvatarPath` | `""` | Avatar image; empty uses the bundled `assets/avatar.png` |
| `lockFallbackIcon` | `"󰀉"` | Fallback glyph when avatar image is absent |
| `lockWallpaperPath` | `""` | Wallpaper image; empty uses `$HOME/Pictures/wallpaper` |
| `lockClockFormat` | `"HH:mm"` | Time display format |
| `lockDateFormat` | `"dddd, MMMM d"` | Date display format |
| `commandCentreRadius` | `26` | Authentication card corner radius (shared with the Command Centre) |
| `lockInputRadius` | `16` | Password input box radius |
| `lockBackgroundDimming` | `0.8` | Dark background overlay opacity (0.0–1.0) |
| `lockBlurPercentage` | `0.5` | Wallpaper GPU blur amount (0.0–1.0) |
| `lockContentFadeMs` | `200` | Fade-in for the wallpaper and lock content (ms) |
| `lockStatusPosition` | `"top-right"` | Badge corner, or `"split"` / `"corners"`; `QS_LOCK_STATUS_POS` overrides it in `Session` |
| `lockStatusMargin` | `26` | Badge distance from the screen edge |
| `lockStatusSpacing` | `10` | Gap between clustered badges |

### 3.5 Popups & Tooltips (`SharedTooltipWindow.qml`)
| Property | Default | Purpose |
| --- | --- | --- |
| `popupGap` | `42` | Distance from bar to popup card |
| `popupMaxWidth` | `280` | Default card width |
| `popupRadius` | `16` | Popup card corner radius |
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
| `notifRadius` | `16` | Notification card corner radius |
| `notifCardMargins` | `16` | Internal card padding (px) |
| `notifSpacing` | `10` | Spacing between stacked cards (px) |
| `notifAnimMs` | `250` | Toast entry and reorder animation (ms) |
| `notifHoverScale` | `1.01` | Scale applied to a notification card on hover |
| `notifIconSize` | `40` | Icon/avatar dimension for standard notifications (px) |
| `notifMediaIconSize` | `48` | Icon/avatar dimension for media notifications (px) |
| `notifIconRadius` | `16` | Corner radius for notification icon/avatar preview |
| `notifMaxLines` | `5` | Maximum lines of notification body text before eliding |
| `notifShowActions` | `true` | Display interactive action buttons on cards |
| `notifDismissOnAction` | `true` | Automatically dismiss card when an action is invoked |
| `notifShowMediaToasts` | `true` | Show popups for MPRIS media track transitions |
| `notifMediaHistory` | `false` | Keep MPRIS track changes in the notification history |
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
| `traySidePillWidth` | `34` | Side bar tray pill width (px) |
| `trayMenuWidth` | `240` | Width of the tray context menu |
| `trayShowAppIdInMenu` | `true` | Show the SNI app ID in the menu header |
| `trayAllowSessionHide` | `true` | Allow hide/unhide actions in the tray menu |
| `UiState.trayEnabled` | `true` | Runtime on/off (IPC `tray toggle`) |
| `UiState.trayShowExpandButton` | `true` | Show the expand arrow when items are hidden |
| `UiState.trayExpanded` | `false` | Whether the hidden section is open |

### 3.8 Audio, Brightness & OSD
| Property | Default | Purpose |
| --- | --- | --- |
| `volStep` | `0.05` | Output volume step per scroll or IPC call |
| `volMax` | `1.5` | Volume ceiling (150%) |
| `micStep` | `0.05` | Microphone volume step |
| `brightnessStep` | `0.05` | Brightness step |
| `osdEnabled` | `true` | Master switch for the OSD |
| `osdPosition` | `"bottom-centre"` | OSD placement |
| `osdAllScreens` | `false` | Show the OSD on every display |
| `osdTimeoutMs` | `1800` | Display duration (ms) |
| `osdWidth` / `osdHeight` | `260` / `48` | Pill size (px) |
| `osdRadius` | `-1` | Corner radius; `-1` uses a full capsule |
| `osdSlideOffset` | `10` | Entry slide distance (px) |
| `osdMarginX` / `osdMarginY` | `26` / `68` | Gap from the screen edge (px) |

### 3.9 Screenshots
| Property | Default | Purpose |
| --- | --- | --- |
| `screenshotDimOpacity` | `0.55` | Dimming over the frozen frame outside the selection |

### 3.10 External Commands
| Property | Default | Purpose |
| --- | --- | --- |
| `cmdMixer` | `["pavucontrol"]` | Audio mixer |
| `cmdNetworkManager` | `["kitty", "--single-instance", "-e", "nmtui"]` | Network tool |
| `cmdBluetoothManager` | `["blueman-manager"]` | Bluetooth manager |
| `cmdScreenshot` | `["quickshell", "ipc", "call", "screenshot", "region"]` | Screenshot tool used by the Command Centre header button |
| `cmdLock` | `["quickshell", "ipc", "call", "lockscreen", "lock"]` | Lock action |
| `cmdSleep` / `cmdReboot` / `cmdPoweroff` | `["systemctl", ...]` | Power actions |
| `cmdTerminal` | `["kitty", "-e"]` | Prefix used by the launcher's "run in terminal" and by `.desktop` terminal entries |
| `cmdClipboard` | `["wl-copy"]` | Clipboard writer used by the calculator and copy actions |

### 3.11 Runtime State (`UiState.qml`)
Nothing here is configuration; it all resets when the shell restarts.

| Property | Default | Purpose |
| --- | --- | --- |
| `barVisible` | `true` | Bar shown (IPC `bar toggle`) |
| `commandCentreVisible` | `false` | Command Centre open |
| `launcherVisible` | `false` | Launcher open |
| `statusMenu` | `""` | Open status menu: `"network"` or `"bluetooth"` |
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
- **Selection**: `selectAudioSink(node)` sets the `default.auto-eq` latch before changing the default output, because `auto-eq.lua` would otherwise override the choice with the matched equaliser sink.
- **Exposes**: `audioSink`, `audioSinks`, `selectAudioSink(node)`, `sinkDisplayName(node)`, `sinkLabel(node)`, `volume`, `muted`, `volumePercent`, `volumeIcon`, `toggleMute()`, `setVolume(val)`, `setVolumeDebounced(val)`, `stepVolume(dir)`, `openMixer()`, `hasMic`, `micVolume`, `micMuted`, `micVolumePercent`, `micIcon`, `micInUse`, `toggleMicMute()`, `setMicVolume(val)`, `setMicVolumeDebounced(val)`, `stepMicVolume(dir)`.

#### `BrightnessService.qml`
- **Role**: `brightnessctl` and sysfs backlight control. Emits `osdRequested()` when the level changes.
- **Exposes**: `brightness`, `brightnessAvailable`, `brightnessPercent`, `refreshBrightness(notifyOsd)`, `setBrightness(val)`, `stepBrightness(dir)`.

#### `MediaColours.qml`
- **Role**: `pragma Singleton` pulling a palette from the current cover art with Quickshell's `ColorQuantizer`, so the bento media card can tint its text, play button and seek bar from the artwork.
- **How**: the quantiser runs on a 32px rescale of `MediaService.artFile` on Quickshell's thread pool, at depth 4 (16 colours). The dominant coloured entry becomes an accent at a fixed lightness, with tinted text and a dark on-accent colour. Text and detail colours carry a light tint of the cover hue, since the scrim always leaves a mid-to-dark background under them. Grey results are ignored so the theme accent stays.
- **Shared art**: it reads the local file `MediaService` already cached for the cards (`artFile`), so the artwork is fetched once per track for the whole shell rather than once for display and again for the palette.
- **Caching**: palettes are cached in memory per artwork URL (up to 24), so revisiting a track reuses the result. A track change keeps the previous palette on screen until the new one resolves, so the card never flashes back to the theme colours; when playback stops and there is no artwork left, the palette clears to the theme.
- **Exposes**: `artUrl`, `artFile`, `palette` (`accent`, `onAccent`, `text`, `detail`, `track`, `trackStrong`, `pill`, `pillStrong`), `fallback`, `request()`, `store(url, colours)`. `track` and `trackStrong` are opaque tints of the cover hue for inactive tracks, pale over a light cover and dark over a dark one; `pill` and `pillStrong` stay dark for chip surfaces. Text and detail stay light with a low tint, since the scrim always darkens the artwork under them.

#### Media artwork cache (`MediaService.artSource`)
- **Role**: One local copy of the current cover per track, shared by every surface that displays it (bar popover, bento cover card, lock screen) and by `MediaColours`.
- **How**: `http(s)` artwork is downloaded with `curl` into `Quickshell.cacheDir/media-art` as soon as the track changes, so opening a surface does not wait on the network. Local `file://` artwork is used in place, and provider URLs such as `image://qsimage/` are passed through. Downloads are queued one at a time so a mid-track change cannot mix up files, and a failed fetch falls back to the raw URL so the cards still show the cover.
- **Caching**: up to 24 files are kept, keyed by URL hash, with the oldest dropped when the limit is passed.

#### `WeatherService.qml`
- **Role**: On-demand weather data from `wttr.in`. No background timer: the command centre asks for a refresh when the weather card opens, and the refresh button forces a fetch.
- **Caching**: results stay fresh for `Config.weatherCacheMinutes`; reopening the command centre inside that window does not hit the network.
- **Location**: `Config.weatherLocation` is sent to `wttr.in` as the place to look up, for example `"Christchurch, New Zealand"`. Left empty, wttr.in picks the location from the request address. The card shows the area name wttr.in resolves.
- **Exposes**: `loading`, `error`, `location`, `temperature`, `feelsLike`, `high`, `low`, `humidity`, `wind`, `code`, `description`, `lastUpdated`, `hasData`, `weatherIcon`, `temperatureText`, `highText`, `lowText`, `feelsLikeText`, `locationText`, `forecast`, `refresh(force)`, `iconFor(code)`.

#### `NetworkService.qml`
- **Role**: Wired and Wi-Fi state from `Quickshell.Networking`.
- **Exposes**: `netIcon`, `netText`, `netColour`, `netTitle`, `netDetails`, `wifiAvailable`, `wifiNetworks`, `isSecured()`, `connectNetwork()`, `disconnectNetwork()`, `scanWifi()`, `openNetworkManager()`.

#### `BatteryService.qml`
- **Role**: Battery telemetry from UPower.
- **Exposes**: `batPresent`, `batPct`, `batCharging`, `batPlugged`, `batIcon`, `batColour`, `batTitle`, `batDetails`.

#### `BluetoothService.qml`
- **Role**: Adapter and connected-device state from `Quickshell.Bluetooth`.
- **Exposes**: `btIcon`, `btColour`, `btStatusText`, `btTitle`, `btDetails`, `btDevices`, `setBtPowered()`, `toggleBtDevice()`, `deviceBattery()`, `openBluetoothManager()`.

#### `TrayService.qml`
- **Role**: System tray items plus the per-session hidden/unhidden lists shared across monitors.
- **Exposes**: `trayAllItems`, `trayVisibleItems`, `trayHiddenCount`, `trayHasContent`, `trayItemKey(item)`, `isTrayItemHidden(item)`, `toggleTrayItemHidden(item)`.

#### `SystemService.qml`
- **Role**: OSD state and the `"system"` / `"tray"` IPC targets. It observes the hardware services rather than owning their state.
- **Exposes**: `osdVisible`, `osdKind`, `osdIcon`, `osdLabel`, `osdValue`, `osdMuted`, `showOsd(kind)`, plus the `volumeUp`, `volumeDown`, `toggleMute`, `micUp`, `micDown`, `toggleMicMute`, `brightnessUp`, `brightnessDown` IPC actions, and `takeScreenshot()` for the Command Centre screenshot button.

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
- **Persistence**: history is mirrored to `notification-history.json` under the Quickshell state directory, so it survives restarts and config reloads. Media toasts and notification actions are not saved, because both belong to a live session. `Clear` empties the file too.

#### `Utils.js`
- **Role**: Shared JavaScript utility library (`.pragma library`).
- **Features**: `findFirst`, `findBatteryDevice`, `findActivePlayer`, `resolveMprisPlayer`, `cyclePlayer`, `pad2`, `formatTime`, `cleanTrackTitle`, `prettifyAppName`, `formatActiveTitle`, `envChoice`, `overlayMargins`, and icon helpers (`volumeIcon`, `micIcon`, `batteryIcon`).

---

### 5.3 Overlays & Standalone Screens

#### `CommandCentre.qml`
- **Role**: Quick settings dashboard and system metrics panel.
- **IPC Target**: `"command-centre"` (functions: `toggle()`, `open()`, `close()`).
- **Multi-Monitor Cursor Tracking**: Delegates active-screen detection to `WmService.resolveTargetScreen(...)` and opens on that specific monitor while rendering a transparent dismiss overlay across all other screens.
- **Structure**: `CommandCentre.qml` owns the per-screen overlay windows, the slide and fade animation, and the IPC surface. The panel contents live in `CommandCentreCard.qml` (sidebar) or `CommandCentreBento.qml` (centred widget board): the sidebar clock and date (`ClockService`), `StatusPills` (Wi-Fi, Ethernet, Battery, Bluetooth), the shared `CommandCentreSliders` (`ControlSliderRow` bound to `AudioService` and `BrightnessService` plus the `AudioSinkPicker` output chips), the full MPRIS `MediaCard`, the `NotificationHistoryCard` list (`NotificationService`), and `PowerButtons`.
- **Layouts**: set `Config.commandCentreLayout` to `"sidebar"` for the edge panel or `"bento"` for a centred widget board. In the bento the left card holds the clock, status pills, system sliders, the now-playing panel and power controls. The middle column is the notification history. The right column stacks the weather card above the calendar. The bento board dims the desktop behind it and is sized as a fraction of the screen.
- **Now playing**: `MediaCard` draws a horizontal row by default for the bar popover and the sidebar panel. The bento sets `vertical: true` and `coverCard: true`, so the cover fills the whole card with a dimmed scrim behind the centred title, controls and seek bar.
- **Keyboard**: Escape closes the panel. Power actions stay click-only to avoid accidental activation.
- **Screenshot**: the header screenshot button closes the panel, waits for the fade-out, then runs `Config.cmdScreenshot`, which asks the screenshot overlay to open.
- **Board surface**: `Config.commandCentreBentoSurface` (off by default) puts one raised surface behind the whole board with the cards inset on top. Set it to true to sit the cards on a single panel.
- **Bento sizing**: the board takes `commandCentreBentoWidthRatio` and `commandCentreBentoHeightRatio` of the screen, so it keeps the same proportions on a laptop and an external monitor. The screen margins clamp it inwards. The three columns share the height, and the notification and weather/calendar columns take their `commandCentreBento*Ratio` share of the board width; the left card gets the rest. The now-playing panel grows in the left card. The calendar cells take their size from the side column width, with side padding to match the weather card above, and are capped by the column height so the calendar and the system card below it fit on a short screen. The system card fills whatever height is left, so the column ends on the board's bottom edge. Every card uses `commandCentreCardPadding` and `commandCentreCardSpacing` for its interior, so the weather, notification, calendar, media and system cards share one rhythm. On a short screen the board falls back to the height its content needs.
- **Duplication**: the board deliberately avoids second copies of the bar and notification controls. Network, Bluetooth and battery live in `StatusPills`; mute, microphone and Do Not Disturb sit in the sliders and the notification card; the audio mixer leads the sink picker.
- **Shared sections**: `CommandCentreSliders.qml` and `StatusPills.qml` keep the two layouts identical, so a change to the volume, microphone or brightness controls only happens once.

#### `ScreenshotOverlay.qml`
- **Role**: Frozen-screen capture. `grim` grabs the target output once, so a playing video or a moving cursor does not change what you selected. The overlay draws that still frame; a whole-screen capture skips the drawing entirely.
- **IPC Target**: `"screenshot"` (functions: `output()`, `region()`, `text()`, `close()`). `output()` captures immediately with no overlay; `region()` opens the drag selection and saves a PNG; `text()` opens it and copies the recognised text instead.
- **Tools**: Region drags a box (a click without dragging takes the whole window under the pointer), Window takes the clicked window, and Output takes the full screen. `R`, `W` and `O` switch tools; Escape cancels; Enter confirms.
- **Window snapping**: `mmsg get all-clients` supplies the visible clients on the target monitor, converted to screen-local coordinates. Only MangoWC exposes that geometry, so on Hyprland and Niri only freeform dragging and Output are available.
- **Capture path**: the overlay passes the frozen frame and a device-pixel crop to the `qs-screenshot` package, which crops with ImageMagick, saves under `~/Pictures/Screenshots`, copies to the clipboard and deletes the frame. Keeping that in a script means no shell quoting in QML.
- **Surface**: `ScreenshotSurface.qml` is the layer surface for one screen. It draws the frozen frame, dims around the selection with four rectangles, and draws the window highlight, the size readout and the hint bar. All capture decisions stay in `ScreenshotOverlay.qml`.
- **Multi-monitor**: the overlay covers the display under the pointer only. Selections do not span outputs.

#### `OsdOverlay.qml`
- **Role**: Floating bottom-centre On-Screen Display pill driven by `SystemService`.
- **Features**: Automatically pops up on the active monitor when output volume, mute, microphone mute/volume, or screen brightness changes (suppressed while `CommandCentre` is open). The value bar is bound first and animated after, so it appears at its level instead of growing from zero on every popup.

#### `LockScreen.qml`
- **Role**: Wayland session screen locker built on `WlSessionLock` and `WlSessionLockSurface`.
- **IPC Target**: `"lockscreen"` (functions: `lock()`, `unlock()`, `toggle()`).
- **Features**: Lazy loading architecture, PAM authentication (`PamContext`), primary monitor interactive password prompt (`LockAuthCard`) with user avatar, real-time accent highlight on keystrokes, rotating authentication spinner, password peek/reveal eye toggle, Caps Lock warning & error shake animation, a compact now-playing row (`LockMediaRow`) with previous, play/pause and next controls, placed below the password input, secondary screen display lock graphics (`LockSecondaryScreen`) with live typing indicator & the same compact now-playing row, customisable status pill cluster (`LockStatusCluster`) docked to any corner (default `"top-right"`, `"top-left"`, `"bottom-right"`, `"bottom-left"`, or `"split"` / `"corners"` via `Config.lockStatusPosition` or `QS_LOCK_STATUS_POS`), background wallpaper with customisable GPU blur (`MultiEffect`, rendered into a half-size texture so the same on-screen radius costs a quarter of the pixels and half the taps) and dimming, and system power actions (Sleep/Suspend, Reboot, Power Off).

#### `Launcher.qml`
- **Role**: Layer-shell launcher and calculator. It opens on the active screen, filters desktop entries from `launcher/desktop-entries.sh`, and shows a calculator result for a valid expression.
- **IPC Target**: `"launcher"` (functions: `toggle()`, `open()`, `close()`).
- **Window**: Fixed 760 x 500 card centred on the active screen. The result list scrolls with the wheel, trackpad, or keyboard, and the selected row stays in view.
- **Entry scan**: the script collects the `.desktop` files in bash and parses them in a single `awk` pass, so a scan costs one process and about 35 ms. It reruns every time the launcher opens.
- **Keyboard**: Up/Down or Ctrl+K/Ctrl+J move the selection. Ctrl+Enter opens the actions menu for the selected application or calculator result. Escape closes the actions menu first, then the launcher.
- **Default Keybind**: `SUPER + Shift + Space` in MangoWC, Hyprland, and Niri.
- **Actions**: Per-app `[Desktop Action]` entries are read from the `.desktop` file, followed by presets: Launch, Run in terminal, Copy command, Copy desktop file path, and Copy desktop ID. Calculator results offer Copy result and Copy expression.
- **Ordering**: match quality wins first, then recent use. The most recently launched apps are stored in `Quickshell.statePath("launcher-recents.json")` and capped by `Config.launcherRecentCount` (20), so an empty query starts with what you use most.
- **Calculator**: `launcher/Calc.js` wraps the vendored [expr-eval](https://github.com/silentmatt/expr-eval) library (`launcher/expr-eval.js`, MIT). It supports arithmetic, `^`, functions such as `sqrt`, `sin`, and `log`, and the constants `pi`, `e`, and `tau`. Pressing Enter copies the result to the clipboard.

#### `NotificationOverlay.qml` & `NotificationCard.qml`
- **Role**: Screen overlay and card delegate rendering active notification toasts and history items.
- **Features**: Stack layout driven by `NotificationService`, animated entry/exit, action buttons, avatar/icon previews with fallback glyphs, and click-to-dismiss or focus.

---

### 5.4 Widgets & UI Components

#### `Pill.qml`
- **Role**: Standardised rounded pill container for bar widgets and inline action pills.
- **Properties**: `horizontal`, `padding`, `pillHeight`, `baseColour`, `hoverColour`, `borderColour`, `hoverHighlight`, `pillColour`, `clickable`, `acceptedButtons`, `shown`, `hovered`, `radius`; signals `clicked(var mouse)`, `wheel(var wheel)`. Includes built-in hover/border colour transitions, auto-sizing, and optional pointer click/scroll handling. `shown` is the visibility gate the bar uses to hide a widget without overriding the widget's own visibility rules.

#### `Divider.qml`
- **Role**: 1px horizontal rule used to separate sections.

#### `StatusPill.qml`
- **Role**: Icon plus optional label inside a `Pill`, with an optional tooltip. Backs the battery, Bluetooth, network and volume widgets and the lock screen badges, so they share one layout and one tooltip implementation.
- **Properties**: `icon`, `iconColour`, `iconSize`, `iconFont`, `label`, `showLabel` (defaults to `horizontal`), `labelColour`, `labelSize`, `labelFont`, `labelBold`, `labelMaxWidth`, `rowRotation`, `rowSpacing`, `interactive`, `sharedWindow`, `showContent` (hides the built-in icon and label row for widgets that draw their own), `tooltipEnabled`, `tooltipTitle`, `tooltipDetails`. Set `interactive: false` for read-only badges and `rowRotation: 270` for the vertical side bar.

#### `VolumePill.qml`
- **Role**: Volume badge shared by the bar and the lock screen status cluster. It always shows the percentage; a muted output turns the border, icon and label red and swaps the icon to the mute glyph.
- **Interaction**: left click mutes, right click opens the mixer, and the wheel adjusts the level. Set `interactive: false` for the read-only lock screen badge.
- **Orientation**: in the vertical side bar the badge shows a level track above the icon and percentage; on a horizontal bar it is a single row.

#### `HostnamePill.qml`
- **Role**: Read-only lock screen badge built on `StatusPill`, shared by the clustered and split layouts.

#### `LockStateRow.qml`
- **Role**: Lock state line shared by the primary and secondary lock layouts. An error wins, then the authenticating message, then the typed-character count, and the colour follows the same order.
- **Properties**: `errorMessage`, `authenticating`, `typedLength`, `showIcon`, `textSize`.

#### `MenuHeader.qml` and `MenuFooterButton.qml`
- **Role**: Header (icon, title, optional controls and the close button) and the wide footer button used by the network and Bluetooth status menus. Children declared on `MenuHeader` land between the title and the close button.

#### `ControlSliderRow.qml`
- **Role**: Icon, slider, and percentage row used by the Command Centre controls.
- **Properties**: `icon`, `alert`, `accent`, `iconClickable`, `sliderValue`, `sliderStyle`, `percentText`; signals `iconClicked()`, `sliderMoved(real value)`.

#### `CommandCentreSliders.qml`
- **Role**: Output volume, sink switcher, microphone and brightness block shared by the sidebar and bento layouts. Owns the `"smart"` microphone visibility rule and the brightness availability check.

#### `StatusPills.qml`
- **Role**: Network, battery and Bluetooth badge row shown in the Command Centre status row. The Bluetooth label is only shown in the wider sidebar layout.

#### `AudioSinkPicker.qml`
- **Role**: PipeWire output switcher: a chip per sink with the current output marked, led by the mixer shortcut. Chips switch on the first click and wrap onto another line when there are many outputs, so expanding the picker never reflows the rest of the panel.
- **Placement**: `CommandCentreSliders.qml` loads it above or below the volume slider from `Config.ccSinkSwitcherAboveVolume`, using one shared component definition so both positions stay identical.
- **Mixer**: leads the row so it never reads as another output. Icon-only by default; set `Config.ccAudioMixerLabel` to add a label, or `Config.ccShowAudioMixer` to drop the shortcut. Clicking it closes the panel before opening the mixer, since the panel would cover it.
- **Properties**: `labelMaxWidth` (default `150`); gives up its space to elision rather than pushing the row wider.
- **Labels**: use `AudioService.sinkLabel(node)`, which prefers PipeWire's `node.nick` (`DAWN PRO2`) over the longer `node.description` (`DAWN PRO2 Analog Stereo`).

#### `NotificationHistoryCard.qml`
- **Role**: Notification history list, mute toggle, and clear button used by the Command Centre.

#### `SystemStatsCard.qml`
- **Role**: CPU and memory load card at the foot of the bento side column, below the calendar. Each reading is a label, a percentage and a read-only `SliderControl` in the `"ticks"` style, used as a small gauge.
- **Sampling**: reads `/proc/stat` and `/proc/meminfo` with one `cat` every `Config.systemStatsInterval` ms while the card exists, which is only while the command centre is open. CPU is the busy share of the counters since the previous sample; memory is `MemTotal` minus `MemAvailable`.
- **Sizing**: `Layout.fillHeight` in the side column, so it takes whatever height the weather and calendar leave and the column still ends on the board's bottom edge.

#### `WeatherCard.qml`
- **Role**: Weather card for the bento Command Centre. Uses `WeatherService`, fetches on open, caches for `Config.weatherCacheMinutes`, and offers a manual refresh button. An icon and temperature sit above the description and location, then a divider, then the three-day forecast strip when `Config.weatherShowForecast` is enabled, then a feels-like line. Its height balances the calendar card below it.

#### `LockClock.qml`
- **Role**: Lock screen time and date, shared by the primary and secondary displays so both clocks stay identical.

#### `LockAuthCard.qml`
- **Role**: Interactive authentication card used on the primary lock screen display. It contains the compact now-playing row below a divider when media is active.
- **Properties**: `session`, `shakeOffset`, `capsLockOn`, `revealPassword`; functions `submitEnteredPassword()`, `cancelInput()`, `updateCapsLock(modifiers)`; signal `backgroundFocusRequested()`.

#### `LockMediaRow.qml`
- **Role**: Compact now-playing row shared by the auth card and the secondary lock screen. Shows cover art, title, artist, a slim progress line, and previous, play/pause and next controls.
- **Properties**: `hasMedia`.

#### `LockStatusCluster.qml` and `LockSecondaryScreen.qml`
- **Role**: Lock screen status pills in bar order (hostname, volume, network, battery), and the read-only content shown on non-primary displays.

#### `Card.qml`
- **Role**: Shared elevated/surface card container used across Command Centre sections, popovers, `MediaCard`, `NotificationCard`, `OsdOverlay`, and `LockScreen`.
- **Properties**: `cardColour` (defaults to `Colours.bgRaised`), `borderColour` (defaults to `Colours.border`), `cardRadius` (defaults to `Config.itemRadiusMd`), with smooth colour and border transitions.

#### `IconButton.qml`
- **Role**: Shared interactive icon button with hover colour, border, and scale feedback.
- **Properties**: `icon`, `iconSize`, `buttonSize`, `baseColour`, `hoverColour`, `borderColour`, `hoverBorderColour`, `iconColour`, `hoverIconColour`, `disabledIconColour`, `hoverScale`, `hovered`; signal `clicked(var mouse)`.

#### `SliderControl.qml`
- **Role**: Reusable interactive horizontal range slider.
- **Properties**: `value` (0.0–1.0), `fillColour`, `trackColour`, `snapPercent`, `style`, `trackAreaHeight`, `animated`, signal `moved(real value)`. Supports mouse drag and direct click positioning. `trackColour` colours the quiet part of the track, so a cover card can tint it. `trackAreaHeight` shrinks the band the track is drawn in, for compact gauges. Sliding parts are seeded from the value at creation, so a freshly opened panel shows them in place and only later changes animate. `animated` turns the moving track off: the wavy style lies flat and the shimmer stops.
- **Styles**: `style` picks the track per instance: `"solid"` (default), `"gradient"` (accent lightening to the right), `"segmented"` (dashes), `"ticks"` (a thin upright tick per step, like a level meter), `"hairline"` (a 2px line), `"wavy"` (a Material expressive squiggle painted once on a `Canvas` and travelled by translating it one wavelength per cycle, ending in a rounded handle) and `"shimmer"` (a light band sweeping across the filled part). The wavy and shimmer tracks are the only animated ones, and both stop when the slider is hidden. Set the style at each call site rather than globally, so a seek bar can wave while a volume slider stays solid.

#### `ThinScrollBar.qml`
- **Role**: Rounded overlay scrollbar used by the launcher lists, the status menus and the notification history. It only appears while the content overflows, so a short list shows no bar and keeps its full width. Width comes from `Config.scrollBarWidth`; the thumb is a full pill in a single colour and the only hover feedback is a slight thickening into the gutter. Lists subtract its `gutter` (bar width plus `Config.spaceXs`, or zero while the bar is hidden) from their rows, so selection highlights stop before a visible bar instead of running underneath it.
- **Properties**: `view`, `overflows`, `gutter`. It is drawn here rather than taken from Qt Quick Controls, so the shell does not load the Controls style for four lists. Point `view` at the list to track and keep both in the same parent: the bar follows the view's geometry, so a list resized after creation keeps its bar in place, and the bar hides with its view. Pressing anywhere on the bar jumps the list and dragging the thumb scrolls it.

#### `CommandCentreButton.qml`
- **Role**: Quick dashboard trigger button component for status bars.
- **Properties**: `horizontal`, `screen`, `shown`. Toggles `UiState.commandCentreVisible`, automatically setting the target screen to the parent bar's monitor.

#### `MediaCard.qml`
- **Role**: Shared MPRIS media card used by the Command Centre, the bar media popover and the lock screen.
- **Properties**: `showWhenIdle`, `seekable`, `interactive`, `cardColour`, `cardRadius`, `contentPadding`, `coverCard`. Renders album art (with fallback), track/artist text, interactive multi-player switcher pill (`MediaService.cyclePlayer`), `PlaybackControls` and `MediaProgressRow`.
- **Cover card**: with `coverCard` on, the artwork fills the card behind the content, masked to the card corners, with a vertical scrim so the text and controls stay readable. The content sits at the foot of the card with generous gaps, leaving the artwork the upper part, and the playback buttons scale up by half again. Title, artist, seek bar, time labels, skip-button hover and the player badge take their colours from `MediaColours`, and the badge moves to the top corner of the card; the play button is filled with the artwork accent and the inactive track and badge surface use an opaque tint of the cover hue. The seek bar stays visible whenever the card is, so a track change does not collapse the layout while the new length arrives. The bento uses it, since its media card is roughly square; the popover and sidebar keep the row layout.

#### `PlaybackControls.qml`
- **Role**: Reusable previous / play-pause / next button cluster.
- **Properties**: `canPrevious`, `canNext`, `isPlaying`, `uiFont`, `buttonScale`, `accentColour`, `onAccentColour`, `sideIconColour`, `sideHoverColour`, `sideHoverIconColour`; signals `previousClicked`, `playPauseClicked`, `nextClicked`. `buttonScale` grows the whole cluster, used by the bento cover card. `accentColour` fills the play button and `onAccentColour` is its icon colour; a transparent accent keeps the neutral look. The play button keeps those colours on hover and only scales up. The skip buttons take `sideIconColour` and a tinted hover from the cover card, and their idle background is that tint at zero alpha so the fade in never passes through transparent black.

#### `MediaProgressRow.qml`
- **Role**: Reusable elapsed-time + seek bar + total-time row. Renders a `● LIVE` label instead of the seek bar when `live` is set (streams with no finite length).
- **Properties**: `position`, `length`, `progress`, `seekable`, `live`, `playing`, `sliderStyle`, `fillColour`, `trackColour`, `labelColour`; signal `seekRequested(real progress)`. `sliderStyle` defaults to `"wavy"`, so the seek bar reads as an audio wave; pass `"solid"` anywhere it should stay flat. `playing` drives the wave: paused media lays it flat and stops it. `fillColour`, `trackColour` and `labelColour` default to the theme colours; the cover card tints them from the artwork.

#### `PowerButtons.qml`
- **Role**: Shared system power-action row (Lock / Sleep / Reboot / Power).
- **Properties**: `showLock`, `buttonRadius`; signal `activated()`.

#### `RoundedImage.qml`
- **Role**: Async image with rounded-corner masking, used for cover art.
- **Properties**: `source`, `sourceSize`, `radius`; exposes `ready` and a `sourceError()` signal for fallback chains. Decoded pixmaps are cached and every caller sets `sourceSize`, so a cover is not kept at full resolution and repeats across the bar, popover, bento and lock screen reuse one decode.

#### `CoverArt.qml`
- **Role**: Rounded track artwork with a glyph fallback, shared by `MediaCard` and `LockMediaRow`.
- **Properties**: `source`, `artSize`, `glyphSize`.

#### Standard Bar Widgets
- **`ClockWidget.qml`**: Time/date stack ingested from `ClockService` with click-to-popup calendar (`CalendarPopup.qml`).
- **`CalendarPopup.qml`**: Month calendar with previous/next/current controls. Used by the clock popup and as a full-size card in the bento Command Centre; `cellSize`, `cellSpacing`, `cellFontSize`, `headerFontSize`, `contentSpacing` and `contentPadding` control the size, and the header controls follow `headerFontSize`. `fittedCellSize(availableWidth, availableHeight)` returns the largest square cell that fits a card of that size, which is how the bento shares its column with the weather and system cards. Today is marked with accent colour, bold and italic text rather than a filled cell. It always draws six week rows, filling the leading and trailing cells with the neighbouring month's days, so its height stays the same in every month.
- **`WindowTitleWidget.qml`**: Active window title ingested from `WmService`.
- **`WorkspacesWidget.qml`**: Interactive workspace indicators connected to `WmService`.
- **`LayoutWidget.qml`**: Tiling layout selector connected to `WmService` (auto-shown on MangoWC). The option list lives in `LayoutPopup.qml`.
- **`SystemTrayWidget.qml`**: StatusNotifierItem (SNI) system tray pill supporting left-click activate, right-click menu (rendered by `TrayMenu.qml`), scroll, and hover tooltips. Automatically hides when no tray items are registered.
- **`MediaWidget.qml`**: MPRIS playback bar button ingested from `MediaService`.
- **`NetworkWidget.qml`**: Network connection monitor displaying Wi-Fi SSID and signal strength. Left-click opens the network menu; right-click launches `nmtui`. Set `interactive: false` to render it as a read-only `StatusPill` (used on the lock screen).
- **`BluetoothWidget.qml`**: Bluetooth adapter status and device indicator. Left-click opens the Bluetooth menu; right-click launches `blueman-manager`.
- **`StatusMenu.qml`**: Focusable centred overlay host for `NetworkMenu.qml` and `BluetoothMenu.qml`. Escape or a click outside closes it, and the card takes keyboard focus so the Wi-Fi password field works. Both menus share `MenuHeader.qml` and `MenuFooterButton.qml`.
- **`NetworkMenu.qml`**: Wi-Fi list showing signal strength, security and connected state. Known or open networks connect on click; a new secured network reveals a password field. The footer opens `nmtui` for anything else.
- **`BluetoothMenu.qml`**: Paired device list with connect/disconnect, battery level and an adapter power toggle. The footer opens `blueman-manager` for pairing new devices.
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

# Screenshot overlay: whole screen, area selection, or text
quickshell ipc call screenshot output
quickshell ipc call screenshot region
quickshell ipc call screenshot text

# Lock screen
quickshell ipc call lockscreen lock

# Unlock screen (if active)
quickshell ipc call lockscreen unlock
```

To apply QML changes, restart the shell:
```bash
qs-restart
```

`qs-restart` is installed by this module. It runs `pkill -f quickshell` and then
`setsid quickshell >/dev/null 2>&1 &`, so the replacement outlives the terminal,
keybind or navi entry that launched it. Keep the two commands in the script
rather than inline: a keybind or navi entry runs through `sh -c`, whose own
command line contains `quickshell`, so `pkill` would kill the wrapper before it
reached the restart.

Quickshell reloads the configuration when `shell.qml` itself changes, but that
is the only trigger. Measured on 0.3.2:

- A real-file `shell.qml` reloads the configuration and logs
  `Reloading configuration...`.
- Editing a component the shell imported (`sub/SubComp.qml`) does not reload.
- Editing the target of a *symlinked* `shell.qml` does not reload.

Both limits apply here, because `nixos.liveLinks` makes `~/.config/quickshell`
a tree of symlinks into this repository. A QML edit therefore never applies
until the process restarts, and there is no `quickshell` IPC target to trigger
the reload either (`qs ipc show` lists the rest). Do not rely on saving a file
to see a change; restart, or iterate in a throwaway instance as described in
`docs/wiki/qml-testing.md`.

---

## 9. Tooling & Tests

- **Unit tests** (`tests/*.test.js`): pure-JS tests for the helpers in `Utils.js` and the launcher calculator. Run locally with:
  ```bash
  node --test modules/features/desktop-env/quickshell/tests/*.test.js
  ```
  These also run in the `Validate Nix Flake` GitHub Actions workflow and need no Nix or Qt.

- **Component testing**: QML is checked in a throwaway `qs -p` instance rather than by restarting the live shell. The loop (copy the config, a minimal `shell.qml`, screenshots, pixel measurement, `qmllint` with the shell's own import paths) is documented in `docs/wiki/qml-testing.md`.

- **Editor / LSP support**: `config/qmldir` is the real manifest for the config module. It lists every shared type and its path, so `qmllint` and `qmlls` can resolve components across directories. Quickshell also uses it at runtime; a new cross-directory type must be added there.

- **Vendored expr-eval**: `config/launcher/expr-eval.js` is expr-eval 2.0.2 with two local changes: the UMD wrapper is replaced with top-level exports so QML can import it, and `ParserState.next` separates an assignment from its return expression because Qt V4 evaluates the original form incorrectly. The MIT licence is in `expr-eval.LICENSE`.

- **Static analysis**: every QML file declares `pragma ComponentBehavior: Bound`, and delegates declare their model context as `required property ...`. Nested children inside a delegate reach the delegate's own properties through its `id` (for example `dayCell.modelData`), which keeps `qmllint` free of unqualified-access warnings. With the manifest above, `qmllint` is clean apart from a handful of Quickshell/`Qt` type-resolution false positives (`PanelWindow`, `margins {}`, `Qt.CapsLockModifier`, and the `values` property of `UntypedObjectModel`).