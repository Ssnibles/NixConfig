pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import ".."

// Frozen-screen capture. grim grabs the target output once, then the overlay
// draws that still frame with a drag selection, window snapping and a hint bar.
// A whole-screen capture skips the overlay and hands the frame straight to
// qs-screenshot, which crops, saves, copies and removes the frame afterwards.
Scope {
  id: root

  // "image" saves a PNG and copies it; "text" runs OCR and copies the text.
  property string captureMode: "image"
  // "region" drags, "window" clicks a window, "output" takes the whole screen.
  property string tool: "region"
  // Overlay visible. A whole-screen capture never sets it.
  property bool active: false
  // A whole-screen capture finishes as soon as grim exits, with no overlay.
  property bool instant: false
  property var targetScreen: null
  property bool frozenReady: false
  property var windows: []
  property var selection: null
  property var hoveredWindow: null
  property bool dragging: false
  property var dragOrigin: null

  readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
  property int freezeId: 0
  readonly property string frozenPath: root.runtimeDir + "/qs-screenshot-" + root.freezeId + ".png"
  readonly property bool busy: root.active || freezeProc.running

  // The rect that would be captured: the whole output in output mode,
  // otherwise whatever the pointer has selected.
  readonly property var effectiveSelection: {
    if (root.tool === "output" && root.targetScreen) {
      return { x: 0, y: 0, width: root.targetScreen.width, height: root.targetScreen.height }
    }
    return root.selection
  }

  IpcHandler {
    target: "screenshot"

    function output(): void {
      root.captureScreen()
    }

    function region(): void {
      root.open("image", "region")
    }

    function text(): void {
      root.open("text", "region")
    }

    function close(): void {
      root.cancel()
    }
  }

  // Whole screen, no overlay: grim writes the frame and qs-screenshot takes it
  // from there, so the common case costs one process and no drawing.
  function captureScreen(): void {
    root.start("image", "output", true)
  }

  // mode: "image" | "text"; tool: "region" | "window" | "output"
  function open(mode: string, tool: string): void {
    root.start(mode, tool, false)
  }

  function start(mode: string, tool: string, instant: bool): void {
    if (root.busy) return

    root.reset()
    root.captureMode = mode === "text" ? "text" : "image"
    root.tool = tool
    root.instant = instant

    WmService.resolveTargetScreen(function (screen) {
      var target = screen || Quickshell.screens[0]
      if (!target) {
        root.fail("No screen to capture")
        return
      }
      root.targetScreen = target
      root.freezeId += 1
      freezeProc.exec(["grim", "-o", target.name, root.frozenPath])
    })
  }

  function cancel(): void {
    var frozen = root.frozenReady ? root.frozenPath : ""
    root.reset()
    // A cancelled capture leaves the frame unconsumed, so remove it here.
    if (frozen !== "") Quickshell.execDetached(["rm", "-f", frozen])
  }

  function reset(): void {
    root.active = false
    root.instant = false
    root.frozenReady = false
    root.tool = "region"
    root.selection = null
    root.hoveredWindow = null
    root.windows = []
    root.dragging = false
    root.dragOrigin = null
    root.targetScreen = null
  }

  function fail(message: string): void {
    root.cancel()
    Quickshell.execDetached(["notify-send", "-a", "Screenshot", "Screenshot", message])
  }

  // Hand the frame to qs-screenshot, which owns it from here and deletes it once
  // it has cropped and copied. An empty crop means the whole frame.
  function finish(crop: string): void {
    var frozen = root.frozenPath
    var mode = root.captureMode
    root.reset()

    var command = ["qs-screenshot", "--frozen", frozen, "--mode", mode]
    if (crop !== "") command.push("--crop", crop)
    Quickshell.execDetached(command)
  }

  function setTool(value: string): void {
    root.tool = value
    root.selection = null
    root.hoveredWindow = null
    root.dragging = false
    root.dragOrigin = null
  }

  function clampX(x: real): real {
    if (!root.targetScreen) return x
    return Math.max(0, Math.min(root.targetScreen.width, x))
  }

  function clampY(y: real): real {
    if (!root.targetScreen) return y
    return Math.max(0, Math.min(root.targetScreen.height, y))
  }

  function rectBetween(x1: real, y1: real, x2: real, y2: real): var {
    return {
      x: Math.min(x1, x2),
      y: Math.min(y1, y2),
      width: Math.abs(x2 - x1),
      height: Math.abs(y2 - y1)
    }
  }

  // all-clients is tiling order, not stacking order, so hit testing ranks by
  // Mango's scene layers before geometry. The ranks follow client_target_layer()
  // with float_full_to_top set, which is what this config uses.
  function layerRank(c: var): int {
    var special = (c.tags || []).indexOf(0) !== -1
    if (c.is_overlay) return special ? 6 : 3
    if (c.is_floating || c.is_fullscreen) return 2
    if (special) return c.is_maximized ? 5 : 4
    return c.is_maximized ? 1 : 0
  }

  // root.windows is ordered topmost last, so the first hit walking back wins.
  function windowAt(x: real, y: real): var {
    for (var i = root.windows.length - 1; i >= 0; i--) {
      var w = root.windows[i]
      if (x >= w.x && x < w.x + w.width && y >= w.y && y < w.y + w.height) return w
    }
    return null
  }

  function pointerMoved(x: real, y: real): void {
    if (root.tool === "output") {
      if (root.hoveredWindow) root.hoveredWindow = null
      return
    }

    if (root.dragging && root.dragOrigin) {
      var rect = root.rectBetween(root.dragOrigin.x, root.dragOrigin.y, root.clampX(x), root.clampY(y))
      // A press and release on a window without dragging keeps the whole window.
      if (root.dragOrigin.window && rect.width < 4 && rect.height < 4) {
        root.selection = root.dragOrigin.window
      } else {
        root.selection = rect
      }
      if (root.hoveredWindow) root.hoveredWindow = null
      return
    }

    var hit = root.windowAt(x, y)
    if (hit !== root.hoveredWindow) root.hoveredWindow = hit
    if (root.tool === "region" && root.selection) root.selection = null
  }

  function pointerPressed(x: real, y: real): void {
    if (root.tool === "output") {
      root.confirm()
      return
    }

    var hit = root.windowAt(x, y)
    if (root.tool === "window") {
      if (hit) {
        root.selection = hit
        root.confirm()
      }
      return
    }

    root.dragging = true
    root.dragOrigin = { x: root.clampX(x), y: root.clampY(y), window: hit }
    root.selection = hit || { x: root.dragOrigin.x, y: root.dragOrigin.y, width: 0, height: 0 }
  }

  function pointerReleased(x: real, y: real): void {
    if (!root.dragging) return

    root.dragging = false
    var origin = root.dragOrigin
    root.dragOrigin = null
    if (!origin || !root.selection) return

    // A click on empty space with no drag has nothing to capture.
    if (!origin.window && root.selection.width < 4 && root.selection.height < 4) {
      root.selection = null
      return
    }
    root.confirm()
  }

  function confirm(): void {
    var sel = root.effectiveSelection
    var screen = root.targetScreen
    if (!screen || !sel || sel.width < 1 || sel.height < 1) {
      root.cancel()
      return
    }

    var scale = screen.devicePixelRatio || 1
    var crop = Math.round(sel.width * scale) + "x" + Math.round(sel.height * scale)
      + "+" + Math.round(sel.x * scale) + "+" + Math.round(sel.y * scale)
    root.finish(crop)
  }

  function loadWindows(): void {
    if (Session.wm !== "mangowc") return
    clientsProc.exec(["mmsg", "get", "all-clients"])
  }

  function applyClients(text: string): void {
    var screen = root.targetScreen
    if (!screen || !text) return

    var list = []
    try {
      var data = JSON.parse(text)
      var clients = (data && data.clients) || []
      for (var i = 0; i < clients.length; i++) {
        var c = clients[i]
        if (!c.is_visible || c.is_swallowedby || c.is_minimized) continue
        if (c.monitor !== screen.name) continue

        // Clamp to the output, so a window dragged past an edge cannot ask
        // for pixels the frozen frame does not have.
        var left = Math.max(0, c.x - screen.x)
        var top = Math.max(0, c.y - screen.y)
        var right = Math.min(screen.width, c.x - screen.x + c.width)
        var bottom = Math.min(screen.height, c.y - screen.y + c.height)
        if (right <= left || bottom <= top) continue

        list.push({
          x: left,
          y: top,
          width: right - left,
          height: bottom - top,
          // Nearer the viewer is higher: layer, then focus, which Mango raises
          // inside a layer. The list position breaks the remaining ties.
          rank: root.layerRank(c) * 2 + (c.is_focused === true ? 1 : 0),
          order: i
        })
      }
    } catch (e) {
      list = []
    }
    // Ascending rank, so the topmost window ends up last.
    list.sort(function (a, b) {
      return a.rank === b.rank ? a.order - b.order : a.rank - b.rank
    })
    root.windows = list
  }

  Process {
    id: freezeProc
    onExited: function (exitCode) {
      if (exitCode !== 0) {
        root.fail("Could not capture the screen")
        return
      }
      root.frozenReady = true
      if (root.instant) {
        root.finish("")
        return
      }
      root.active = true
      root.loadWindows()
    }
  }

  Process {
    id: clientsProc
    stdout: StdioCollector {
      onStreamFinished: root.applyClients(this.text)
    }
  }

  Loader {
    active: root.active && root.targetScreen !== null
    sourceComponent: surfaceComponent
  }

  Component {
    id: surfaceComponent

    ScreenshotSurface {
      overlay: root
      screen: root.targetScreen
    }
  }
}
