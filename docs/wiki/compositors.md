# Wayland Compositors Guide: MangoWC, Niri, Hyprland & Display Daemons

This guide documents the Wayland compositors configured in NixConfig, their layout paradigms, keybindings, display profile management (Shikane), and application launching (Vicinae).

---

## Compositor Overview

NixConfig supports three modern Wayland compositors tailored to different productivity styles and hardware targets:

| Compositor | Paradigm | Primary Host Target | Key Characteristics | Nix Module Path |
| :--- | :--- | :--- | :--- | :--- |
| **MangoWC** | DWM / Master-Stack & Dwindle | `laptop` / `desktop` | Ultra-lightweight, tag-based workspaces, trackpad gestures, OCR screenshots | `modules/features/desktop-env/mangowc/` |
| **Niri** | Infinite Horizontal Strip | `laptop` | Scrollable tiling, column grouping, Quickshell vertical sidebar | `modules/features/desktop-env/niri/` |
| **Hyprland** | Dynamic Tiling & Floating | `desktop` | Smooth animations, Lua configuration, multi-monitor gaming | `modules/features/desktop-env/hyprland/` |

---

## 1. MangoWC (Default Lightweight Compositor)

MangoWC is a lightweight, DWM-inspired Wayland compositor built on wlroots. It is the default daily driver on the `laptop` host and supported on `desktop`.

### Configuration Architecture

- **`config.conf`**: Core options (border width, inner/outer gaps, mouse focus, master window ratio). Symlinked to `~/.config/mango/config.conf`.
- **`binds.conf`**: Complete keybinding definitions, trackpad gestures, and scratchpad management.
- **`colours.conf`**: Generated declaratively by Hjem from `config.theme.colors` (`focuscolor`, `bordercolor`).
- **`mango-dev` Wrapper**: When `features.mangowc.local = true` is set, the system wraps `mango` and `mmsg` to check `/home/josh/mango/result/bin/` first. This enables instant iteration on local compositor source code via `nix build` without requiring a full `nixos-rebuild`.

### Keybindings & Workflows

#### Application Launching & Shell Controls
- **`SUPER + Return`**: Launch Kitty terminal in shared single-instance mode (`kitty --single-instance`)
- **`SUPER + Space`**: Toggle Vicinae application launcher (`vicinae toggle`)
- **`SUPER + d`**: Toggle Quickshell Command Centre dashboard
- **`SUPER + Alt + L`**: Lock screen via Quickshell lockscreen
- **`SUPER + e`**: Open Yazi file manager in Kitty
- **`SUPER + g`**: Toggle Quickshell top status bar

#### Window Management & Layouts
- **`SUPER + q`**: Close active window (`killclient`)
- **`SUPER + f`**: Toggle fullscreen
- **`SUPER + v`** / **`SUPER + c`**: Toggle floating mode
- **`SUPER + r`**: Switch layout to **Dwindle**
- **`SUPER + t`**: Switch layout to **Tile** (master/stack)
- **`SUPER + m`**: Switch layout to **Monocle** (single focused window)
- **`SUPER + p`**: Switch layout to **Scroller**
- **`SUPER + Tab`**: Cycle through available layouts

#### Directional Focus & Window Swapping (Vim & Arrow Keys)
- Focus window: **`SUPER + h/j/k/l`** or **`SUPER + Left/Down/Up/Right`**
- Move/Exchange window: **`SUPER + Shift + h/j/k/l`** or **`SUPER + Shift + Arrows`**
- Resize window: **`SUPER + Ctrl + h/j/k/l`** (expands/shrinks by 50px)
- Monitor focus: **`SUPER + Alt + h/j/k/l`**
- Send window to monitor: **`SUPER + Shift + Ctrl + h/j/k/l`**

#### Workspaces (Tags 1 through 10)
- **`SUPER + 1..0`**: View tag 1 through 10
- **`SUPER + Shift + 1..0`**: Move focused window to tag
- **`SUPER + Ctrl + 1..0`**: Move focused window to tag silently without following

#### Scratchpads & Special Workspaces
- **`SUPER + w`**: Toggle special scratchpad tag
- **`SUPER + Shift + w`**: Move window to special scratchpad tag
- **`SUPER + Ctrl + w`**: Move window to special tag silently
- **`SUPER + i`**: Minimise window to scratchpad
- **`SUPER + Shift + i`**: Restore minimised window
- **`Alt + z`**: Toggle floating scratchpad

#### Trackpad Gestures
- **3-Finger Swipe Left / Right**: Switch to adjacent workspace tag (`viewtoleft` / `viewtoright`)
- **3-Finger Swipe Up**: Toggle jump
- **3-Finger Swipe Down**: Toggle special scratchpad workspace

### Intelligent Screenshots & OCR Script (`screenshot.sh`)

Triggered via keybindings:
- **`SUPER + s`**: Interactive area screenshot
- **`SUPER + Shift + s`**: Interactive area screenshot with instant OCR text recognition

The custom script (`modules/features/desktop-env/mangowc/screenshot.sh`) includes several advanced behaviours:
1. **Zero-Border Capture**: Queries MangoWC options via `mmsg`, temporarily sets `borderpx` and `border_radius` to 0, and restores them immediately upon completion.
2. **Window Snapping**: Queries visible client geometry via `mmsg get all-clients` and passes coordinates to `slurp` for one-click window boundary selection.
3. **Cursor Warping**: Uses `wlrctl pointer move` to temporarily warp the mouse pointer off-screen, preventing software cursor artifacts from appearing in screenshots.
4. **OCR Extraction**: For `SUPER + Shift + s`, pipes cropped image data directly into `tesseract` and copies the resulting text to `wl-copy`.

---

## 2. Niri (Scrollable Tiling Compositor)

Niri (`modules/features/desktop-env/niri/`) is an infinite-strip scrollable-tiling Wayland compositor.

### Window Layout Model

- Windows open as vertical columns along an infinite horizontal strip.
- Windows never overlap, and navigating horizontally smoothly scrolls the desktop across columns.
- Multiple windows can be grouped vertically inside a single column.

### Shell & Bar Integration

- Paired with **`niri-bar.qml`**, a dedicated vertical left sidebar powered by Quickshell.
- Communicates with **`NiriService.qml`** via `niri msg --json event-stream`, providing live workspace, layout, and window title telemetry.

---

## 3. Hyprland (Dynamic Workstation Compositor)

Hyprland (`modules/features/desktop-env/hyprland/`) is configured primarily on the `desktop` host for NVIDIA gaming and multi-monitor productivity.

### Architecture

- **`hyprland.lua`**: The compositor configuration is defined in Lua, leveraging modular tables for input, general layout, decorations, animations, and window rules.
- **Dynamic Theming**: Colour variables from `config.theme.colors` are passed directly into Hyprland's border and gradient options.
- **Display Server**: Runs with full DRM kernel modesetting and Wayland flags configured for NVIDIA GPUs (`nvidia.nix`).

---

## 4. Multi-Monitor Display Profiles (Shikane)

Multi-monitor display geometry is managed dynamically by **Shikane** (`modules/features/desktop-env/shikane/default.nix`), running as a systemd user service (`shikane.service`).

Whenever displays are connected or disconnected, Shikane detects the hardware identifiers and automatically applies the matching profile from `~/.config/shikane/config.toml`:

1. **`dual_laptop_external`**:
   - Matches external HDMI or DisplayPort monitors (`HDMI.*`, `DP.*`).
   - Positions external monitor at `0,0` (top/primary) at preferred resolution.
   - Positions internal laptop panel (`eDP-1`, 1920x1200) below at `0,1440`.
   - Sends desktop notification via `notify-send`.
2. **`laptop`**:
   - Matches standalone laptop panel (`eDP-1`).
   - Activates native 1920x1200@60Hz at `0,0`.
3. **`fallback`**:
   - Auto-enables any connected display at scale 1.0.

---

## 5. Vicinae Application Launcher Daemon

Application launching is handled by **Vicinae** (`modules/features/desktop-env/vicinae/default.nix`).

- **Daemon Architecture**: Runs as a background systemd user service (`vicinae-server.service`) on `wayland-session.target`.
- **Instant Launch**: Pressing **`SUPER + Space`** executes `vicinae toggle`, instantly raising the layer-shell overlay without process startup latency.
- **Theme Matching**: The launcher theme (`~/.local/share/vicinae/themes/nixconfig.toml`) is generated declaratively with background, border, and accent colours from the active theme.
- **Clipboard History Extension**: A custom script (`vicinae-clipboard-history`) wraps `cliphist` to allow fuzzy searching through clipboard history directly from the launcher.
