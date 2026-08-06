# Quickshell Bar — Module Reference

This module contains the [quickshell](https://quickshell.outfoxxed.me/) config
for the status bars (niri + mangowc), the notification overlay and the shared
tooltip/popup system. All QML lives in `config/` and is symlinked into
`~/.config/quickshell/` at activation time, so **QML edits apply on the next
quickshell restart** — no Nix rebuild needed. Only `Colors.qml` is generated
(see below) and requires a rebuild to change.

Global layout knobs (bar size/position, popup geometry, notification
placement, fonts) live in one place: **`Config.qml`**. Everything
widget-specific stays as a property on that widget's file, so you never touch
the bars to tweak a single widget.

---

## 1. How the module is wired up (`default.nix`)

| Step | What happens |
| --- | --- |
| System packages | `quickshell` (unstable) is installed |
| `Colors.qml` | Generated from the active theme into `~/.config/quickshell/Colors.qml` (real file, not a symlink) |
| Config dir | Activation script symlinks every file in `config/` into `~/.config/quickshell/` |
| Ownership | Both the dir and files are `chown`ed to your user |

To run: `quickshell` (usually started by your session). Which bar loads is
decided at startup by the `QS_BAR` environment variable — see `shell.qml`
below. There is no NixOS option on this module; everything is customised by
editing `Config.qml` and the QML files.

## 2. Configuration reference — `Config.qml`

A `pragma Singleton` exactly like `Colors.qml`, holding **all global/layout
settings**. Edit this file to restyle or reposition things.

| Section | Key | Default | Meaning |
| --- | --- | --- | --- |
| Fonts | `monoFont` | `JetBrainsMono Nerd Font` | Icons/numbers, most widgets |
| | `sansFont` | `Inter` | Notifications & mangowc text |
| Clock | `timeFormat` | `"hh:mm"` | Qt time format |
| Niri bar | `barWidth` | `38` | Width of the vertical bar |
| | `barSide` | `"left"` | `"left"` \| `"right"` — which screen edge the bar hugs |
| | `barMarginTop/Bottom/Left/Right` | `8 / 8 / 4 / 4` | Inner padding of the bar |
| | `barSpacing` | `12` | Vertical gap between widget groups |
| MangoWC bar | `barHeight` | `32` | Height of the top bar |
| Popup | `popupGap` | `46` | Distance from bar edge to a popup |
| | `popupMaxWidth` | `280` | Default card width |
| | `popupRadius` | `8` | Card corner radius |
| | `popupContentMargins` | `12` | Padding inside the card |
| | `popupContentSpacing` | `6` | Vertical gap between card lines |
| | `popupShowDelay` | `150` | ms of hover before a popup appears |
| | `popupFadeMs` | `120` | Popup fade in/out duration |
| | `popupGraceMs` | `500` | Instant-swap window between popups |
| Notifications | `notifPosition` | `"top-right"` | `top-`/`bottom-` + `left`/`right` |
| | `notifTimeoutMs` | `5000` | Display time per notification |
| | `notifMaxVisible` | `3` | Queue size (oldest dropped first) |
| | `notifWidth` | `300` | Notification card width |
| | `notifRadius` | `8` | Card corner radius |
| | `notifCardMargins` | `8` | Padding + outer margins |
| | `notifSpacing` | `4` | Gap between stacked notifications |

## 3. Entry point — `shell.qml`

```qml
Loader {
  source: Quickshell.env("QS_BAR") === "niri" ? "niri-bar.qml" : "mangowc-bar.qml"
}
NotificationOverlay { }
```

* Set `QS_BAR=niri` for the vertical niri bar, anything else (or unset) loads
  `mangowc-bar.qml`.
* The `NotificationOverlay` sits here on every screen, using defaults from
  `Config.notif*` (you can still override them per instance).

## 4. Theme colours — `Colors` singleton

`default.nix` reads `config.theme.colors` (defined in `modules/themes/`,
schemes in `modules/themes/palette.nix`, selectable via `theme.active`) and
emits a `pragma Singleton` `Colors.qml`. Available tokens:

| Token | Typical use |
| --- | --- |
| `Colors.bg` | Bar backgrounds |
| `Colors.bgRaised` | Cards, pills, tooltip/notification backgrounds |
| `Colors.bgSubtle` | Track/trough backgrounds |
| `Colors.border` | Borders and dividers |
| `Colors.fg` / `Colors.fgMid` / `Colors.fgDim` | Text tiers |
| `Colors.accent` + `teal/purple/green/yellow/red/orange` | Status / active colours |

## 5. The bars

### 5.1 `niri-bar.qml` (vertical, edge bar)

`ShellRoot` per screen, containing:

```
NiriService            ← niri IPC event stream (workspaces + window title)
PanelWindow (Config.barWidth, full height, exclusionMode Auto)
├── topCol        ClockWidget (has a date popup) + WindowTitleWidget
├── WorkspacesWidget   (centered)
├── bottomCol    MediaWidget · VolumeWidget · NetworkWidget · BatteryWidget
└── SharedTooltipWindow  ← one shared popup layer for all tooltips
```

`Config.barSide` drives the anchors and which edge gets the 1px border, and it
is forwarded to the popup layer so the popups open on the correct side.
Each bottom widget receives `sharedWindow: sharedTipWindow`. To add a widget,
insert it in `topCol`/`bottomCol` and give it a `sharedWindow` property.

### 5.2 `mangowc-bar.qml` (horizontal, top edge)

Standalone bar for mangoshell (uses the `mmsg watch all-tags` stream). Now
themed via `Colors` and sized via `Config.barHeight`.

| Cfg | Default | Meaning |
| --- | --- | --- |
| `minWorkspaces` | `5` | Minimum number of tag slots shown |
| `currentTime` | — | Clock text (internal, updated every s) |

Tag colour mappings: active = `Colors.accent`, occupied = `Colors.fgDim`,
empty = `Colors.bgSubtle`, text = `Colors.fg`.

## 6. Widget reference

Every widget accepts a `uiFont` override (defaulting to `Config.monoFont`).
Bottom-row widgets also take `sharedWindow` (the `SharedTooltipWindow` for
their screen).

### 6.1 ClockWidget

* **Data**: local time via `Qt.formatTime(..., Config.timeFormat)`, re-syncs
  per minute.
* **Display**: hours (accent) + minutes (fg) two-line stack.
* **Popup**: shows the current date + seconds (behind the `sharedWindow` it
  now receives).
* **Opts**: `uiFont`, `timeFormat`, `sharedWindow`.

### 6.2 WindowTitleWidget

| Opt | Default |
| --- | --- |
| `titleText` | `""` (bound to `niriService.currentTitle`) |
| `textColor` | `Colors.fgMid` |
| `fontSize` / `italic` | `11` / `true` |
| `rotation` | `270` |
| `maxText` | `120` (clip length) |
| `uiFont` | `Config.monoFont` |

### 6.3 WorkspacesWidget

| Opt | Default |
| --- | --- |
| `workspaces` | `[]` (from `niriService.workspacesForOutput(...)`) |
| `dotSize` / `dotSizeFocused` | `10` / `26` |
| `dotSpacing` | `6` |
| `dotColorFocused/Active/Urgent/Empty` | accent / fgMid / red / fgDim |

Signal `focusRequested(workspaceId)` is wired to
`niriService.focusWorkspace()` in the bar. Each entry: `id, idx, name,
output, is_active, is_focused, is_urgent`.

### 6.4 MediaWidget

* **Data**: MPRIS via `Quickshell.Services.Mpris` (first playing player, else
  first paused).
* **Progress**: delegates to the reusable **`MediaProgress`** helper
  (`mediaTracker.estimatedPosition` / `.progress`), see §9.
* **Interaction**: left = play/pause, right = focus app (`niri msg`),
  scroll = next/prev.
* **Opts**: `sharedWindow`, `uiFont`.

### 6.5 VolumeWidget

* **Data**: `Pipewire.defaultAudioSink` (audio node, `PwObjectTracker`).
* **Interaction**: left = mute, right = `pavucontrol`, scroll = ±5% (0–150%).
* **Popup**: state + action hints.
* **Opts**: `sharedWindow`, `uiFont`.

### 6.6 NetworkWidget

* **Data**: `Quickshell.Networking` (first wifi device + connected network).
* **Interaction**: right click = `kitty -e nmtui`.
* **Opts**: `sharedWindow`, `uiFont`.

### 6.7 BatteryWidget

* **Data**: UPower (first ready laptop battery, falls back to display
  device). Hidden when no battery.
* **Popup**: percent + state, time-to-full/empty.
* **Opts**: `sharedWindow`, `uiFont`. Colours yellow ≤30%, red ≤15%.

### 6.8 Pill (shared container)

| Opt | Default |
| --- | --- |
| `padding` | `8` |
| `pillHeight` | `22` |
| `pillColor` | `Colors.bgRaised` |

`radius` is `height/2`. Children go in the default `data` property.

## 7. Tooltip system

Two cooperating files — see also the custom-popup escape hatch in `Tooltip`.

### 7.1 `Tooltip.qml` (declarative hover controller)

Nest an instance inside a widget. It owns hover detection + show delay and
registers with the shared window when visible.

| Opt | Default | Description |
| --- | --- | --- |
| `target` | `parent` | Widget the popup points at |
| `sharedWindow` | `null` | `SharedTooltipWindow` to display in |
| `icon` / `iconColor` | `""` / `Colors.fg` | Header glyph + colour |
| `title` | `""` | Bold header |
| `details` | `[]` | Muted detail lines under a divider |
| `showDelay` | `Config.popupShowDelay` | Hover delay |
| `maxWidth` | `Config.popupMaxWidth` | Popup width (default card) |
| `contentWidth` | `0` | Width override for custom content (>0 wins) |
| `contentComponent` | `null` | Fully custom popup, see §7.3 |
| `hovered` / `tipVisible` (readonly) | — | Hover state helpers |

### 7.2 `SharedTooltipWindow.qml` (the popup layer)

One per screen, sitting on the edge opposite the bar (`barSide` mirrors
`Config.barSide`). It owns fade, the 60ms reposition tick, the
`recentlyActive` instant-swap grace, and vertical clamping. It renders the
default card unless the active `Tooltip` provides `contentComponent`.

### 7.3 Fully custom popups (`contentComponent`)

Give your `Tooltip` a `Component`; it replaces the card entirely. Geometry
(`width` = window width, `y`/opacity = handled) is managed by the loader,
which also exposes helpers via `parent`:

| Helper (on `parent`) | Description |
| --- | --- |
| `parent.src` | The active `Tooltip` instance (carry custom props) |
| `parent.targetCenterY` | Vertical centre of the widget, window coords |
| `parent.width` | Window width (`contentWidth`/`maxWidth`) |

Example towards the clock: see the calendar popup in the previous version of
this doc — it now also applies to `sharedWindow` on the Clock.

## 8. `NiriService.qml`

`QtObject` bridging niri via `niri msg --json event-stream`.

| Member | Type | Description |
| --- | --- | --- |
| `allWorkspaces` | `var` | Sorted list of all workspace objects |
| `currentTitle` | `string` | Focused window title (formatted) |
| `workspacesForOutput(output)` | fn | Workspaces for one monitor |
| `focusWorkspace(id)` | fn | `niri msg action focus-workspace <id>` |
| `formatActiveTitle(title, appId)` | fn | Delegates to `Utils.formatActiveTitle` |

## 9. `Utils.js` & helpers

`.pragma library` pure helpers, all customisable in one file:
`findFirst`, `clamp`, `pad2`, `formatTime`, `escapeRegex`, `stripMarkup`,
`prettifyAppName`, `formatActiveTitle` (suffix-stripping map
`_titleSuffixMap`), and icon mappers `volumeIcon`, `batteryIcon`,
`wifiIcon`.

## 10. `MediaProgress.qml`

Reusable MPRIS progress estimator (`QtObject`): watch `player` and read
`estimatedPosition` (s) + `progress` (0..1), with wall-clock drift while
playing, rewind/reset detection, and a `tickInterval` polling timer.
Built into `MediaWidget` as `mediaTracker`; reuse anywhere.

## 11. `NotificationOverlay.qml` + `NotificationCard.qml`

Per-screen pane stacking `NotificationCard` delegates. Options: `position`,
`timeoutMs`, `maxVisible`, `width/radius/margins/spacing` (all defaults from
`Config.notif*`). Click any card to dismiss it (`dismissAt(index)`).
Notifications come from the Quickshell notification server.

## 12. Common customisation tasks

* **Bar size/position**: `Config.qml` (`barWidth`, `barSide`, margins, spacing)
  — popup side follows automatically.
* **Colours/fonts**: `Colours.qml` is generated; restyle via the theme
  palette (`modules/themes/palette.nix`) or `Config.monoFont`/`sansFont`.
* **Notifications**: `Config.notif*` for placement/dimensions, or restyle
  `NotificationCard.qml`.
* **Re-add a widget / reorder**: edit the `Col`s in `niri-bar.qml`.
* **Popup**: `Tooltip` fields, or `contentComponent` for arbitrary QML.
* **Reload**: restart quickshell (pure QML); rebuild only to change theme.

## 13. Updating the live config

Because `Config.qml`, `Utils.js` and every QML file are symlinked from the
repo, a restart of quickshell picks them up. When you create a *new* QML
file it also needs the symlink: rerun the activation script (or
`sudo nixos-rebuild switch`).