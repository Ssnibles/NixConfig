# QML Component Testing Guide

How to change a single Quickshell component and check it without restarting the live shell. The loop is: copy the config to `/tmp`, run a throwaway shell that shows only the component, screenshot or log the result, delete the copy.

---

## Why isolate at all

Editing QML in the live shell does not apply by itself. The live config at `~/.config/quickshell` is a tree of symlinks into this repository, and Quickshell does not notice a change made to the target of a symlink. The only way to see a change is to restart, which drops the bar, closes any open panel and re-registers the notification daemon.

Even without symlinks the reload is narrower than it looks: on 0.3.2, editing `shell.qml` reloads the whole configuration, and editing a component it imported does not. Measured three ways on this machine:

| Edit | Result |
| :--- | :--- |
| A real `shell.qml` | Reloads, logs `Reloading configuration...` |
| A real `sub/SubComp.qml` that it imports | No reload |
| The target of a symlinked `shell.qml` | No reload |

So a throwaway instance is the fast loop as well as a sandbox: relaunching one that shows a single component takes about a second, and nothing user visible is at risk.

The isolation it buys:

| Concern | Live shell | `qs -p /tmp/...` instance |
| :--- | :--- | :--- |
| Shell ID | derived from `~/.config/quickshell` | derived from the path you pass |
| State directory | `~/.local/state/quickshell/by-shell/<a>` | `by-shell/<b>`, so history and recents are untouched |
| Notification name | owns `org.freedesktop.Notifications` | fails to register, logs a warning, harmless |
| Failure blast radius | your desktop | a window that closes on its own |

---

## The recipe

Commands below assume the repository root as the working directory.

### 1. Copy the live config

```bash
cp -rL ~/.config/quickshell /tmp/qs-test
```

`-L` matters. The live config is a tree of symlinks into this repository, so a copy that keeps the links still writes into the repo: copying a changed file over one, or editing it in place, would modify the real source. Dereferencing gives a standalone copy, and nothing done in `/tmp` can touch the repo.

The copy includes the generated `Colours.qml`, which is why the component resolves its theme colours without a Nix rebuild.

### 2. Copy in the file under test

```bash
cp modules/features/desktop-env/quickshell/config/common/SliderControl.qml \
   /tmp/qs-test/common/
```

Always copy the repository file over the copy, never edit the copy. That way what you tested is exactly what you commit.

### 3. Write a minimal `shell.qml`

Replace the copy's `shell.qml`. This is the wave bar harness that was used to check the seek bar:

```qml
import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
  PanelWindow {
    anchors.top: true
    anchors.left: true
    margins.top: 200
    margins.left: 200
    implicitWidth: 420
    implicitHeight: 120
    color: "#101010"
    aboveWindows: true

    Component.onCompleted: quitTimer.start()
    Timer { id: quitTimer; interval: 6000; onTriggered: Qt.quit() }

    SliderControl {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.margins: 20
      value: 0.6
      style: "wavy"
      fillColour: "#88ccff"
      trackColour: "#334455"
    }
  }
}
```

Three rules for the harness:

- **Import only the component.** `Config`, `Colours` and `Session` arrive with the component through `import ".."`; avoid pulling in services that talk to D-Bus.
- **Always include the quit timer.** A forgotten instance holds a layer surface over the desktop and confuses the next run.
- **Give the component distinctive colours.** You will search the screenshot for them.

### 4. Run it as a separate instance

```bash
qs -p /tmp/qs-test > /tmp/qs-test.log 2>&1 &
grep -iE "error|warn" /tmp/qs-test.log
```

`-p` selects a config by path, which is what gives the instance its own shell ID. `-c default` would run *your* config and duplicate every bar.

To apply an edit you just copied in, kill the instance and launch it again. A reload happens only when `shell.qml` itself changes, not when a component does.

### 5. Capture the result

```bash
grim -g "200,200 420x120" /tmp/wave1.png
sleep 0.35
grim -g "200,200 420x120" /tmp/wave2.png
cmp -s /tmp/wave1.png /tmp/wave2.png && echo "static" || echo "animating"
```

Two frames a few hundred milliseconds apart separate "renders" from "renders and animates", which is the whole question for a moving component.

The region is in screen coordinates. Read [Gotchas](#gotchas) before you blame the component for sitting in the wrong place.

---

## Three levels of verification

Cheapest first. Use the lowest level that answers the question.

### Level 1: log the state

For anything that is values rather than pixels, skip the screenshots. A `Timer` that prints and quits is enough:

```qml
property int ticks: 0

Timer {
  interval: 1000
  repeat: true
  running: true
  onTriggered: {
    ticks++
    console.log("tick", ticks, "cpu", card.cpuPercent, "mem", card.memPercent)
    if (ticks >= 6) Qt.quit()
  }
}
```

Six ticks of output proved that one `cat` over `/proc/stat` and `/proc/meminfo` still fed both meters. No screenshot was involved.

### Level 2: measure the pixels

Do not eyeball geometry. Render the component's own numbers next to it, then compare what it says with what it painted.

```qml
Text {
  x: 260
  color: "#88ccff"
  text: "contentY " + Math.round(list.contentY)
    + "\nthumb h " + Math.round(bar._thumbHeight)
    + "\nthumb y " + Math.round(bar._thumbHeightY)
}
```

Then find the painted thumb by its colour. Crop to the bar's column, which is the view's right edge minus `Config.scrollBarWidth`:

```bash
magick /tmp/scroll.png -crop 16x400+206+0 +repage txt:- \
  | awk -F'[,: ]+' 'NR>1 && /878787/{print $2}' \
  | sort -n | uniq \
  | awk 'NR==1{min=$1} {max=$1} END{print "rows "min".."max" height="(max-min+1)}'
```

`878787` is `Colours.fgMid`, the thumb colour. This is how a 16 px overflow past the track end was caught: the wave canvas was one wavelength wider than the track and painted outside it until the track clipped.

The same trick found a bug in the harness rather than the code, described below.

### Level 3: lint before running anything

`qmllint` catches bad ids, typos and type errors without starting a shell. It needs the same import paths the shell uses, which you can lift from the running process:

```bash
lint() {
  local pid imports qmllint
  pid=$(pidof quickshell)
  imports=$(tr '\0' '\n' < "/proc/$pid/environ" | sed -n 's/^NIXPKGS_QT6_QML_IMPORT_PATH=//p')
  qmllint=$(ls /nix/store/*-qtdeclarative-*/bin/qmllint | head -1)
  local args=(-I "$HOME/.config/quickshell")
  local path
  for path in ${imports//:/ }; do args+=(-I "$path"); done
  "$qmllint" "${args[@]}" "$@"
}

lint modules/features/desktop-env/quickshell/config/common/SliderControl.qml
```

Two warnings are expected and not your fault. `Warnings occurred while importing ...` and `Colours.qml is listed as component in .../qmldir but does not exist` both come from linting the *source* tree, where the Nix-generated `Colours.qml` is absent. Lint the copy in `/tmp/qs-test` if you want a clean run.

---

## Gotchas

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| Component sits lower than `margins.top`, and the capture shows desktop around it | Layer surfaces are pushed below the bar's exclusive zone, which is `barHeight` 35 plus `borderWidth` 1 = 36 px here | Capture the whole screen and crop, or add the bar height to your anchor and capture region |
| `pkill -f qs-test` kills your shell | The pattern matches the command line of the bash running it | `pkill -f 'qs-tes[t]'`, or save the PID |
| `Property value set multiple times` and the config will not load | Two `Component.onCompleted` blocks on one object | Merge them |
| Deprecation warnings about `width`/`height` | `PanelWindow` wants `implicitWidth`/`implicitHeight` | Use the implicit forms |
| Warning about `org.freedesktop.Notifications` | The component imports `NotificationService` | Harmless; the live shell keeps the name |

A worked example of the first row. A scrollbar thumb appeared 36 px lower than the value the component reported, and the window looked like it had no background. Both were the same mistake: the window sat 36 px below the capture region, so most of each screenshot was the desktop underneath. Measure the offset once, against the bar height, and check the window background colour before you debug anything else.

---

## Measuring performance

Isolation is also how you measure, with limits worth knowing before you start.

**Startup dominates.** A shell spends most of its CPU compiling QML, so a single run tells you nothing about a per-frame change. Run each variant at least three times and compare medians:

```bash
for i in 1 2 3; do
  time qs -p /tmp/variant-a > /dev/null 2>&1
done
```

**GPU work is invisible to `time`.** Process user and sys time will not move for a shader, which is why the lock screen blur was verified by comparing renders (0.26% RMSE under the dim layer) rather than by clock. If the cost is GPU, compare output, or read a GPU counter such as `/sys/class/drm/card1/device/gpu_busy_percent`.

**Measure the thing you actually changed.** For the launcher scan, the useful number came from timing the script directly:

```bash
time bash launcher/desktop-entries.sh > /dev/null
```

0.78 s before the rewrite, 0.03 s after. No shell instance required.

---

## Cleanup

```bash
pkill -f 'qs-tes[t]'
rm -rf /tmp/qs-test
```

Then confirm nothing is left behind:

```bash
ps -eo pid,args | grep 'qs -p' | grep -v grep
```

---

## When not to bother

- **Pure JavaScript.** `node --test modules/features/desktop-env/quickshell/tests/*.test.js` covers `Utils.js` and the launcher calculator. No Qt involved.
- **Hardware state.** Audio sinks, brightness and tray icons depend on real devices and services. Check those in the live shell after a restart, and revert if it misbehaves.
- **One-line geometry tweaks.** If you can predict the outcome exactly, restart the shell once and look. The harness earns its keep when the thing moves, animates, or is measured.
