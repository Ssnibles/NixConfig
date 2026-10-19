pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import "Utils.js" as Utils

// Unified Window Manager singleton bridging MangoWC, Hyprland, and Niri
// backends for workspaces, active window title, layouts, and active-screen
// resolution.
Singleton {
  id: root

  readonly property string wm: Config.wm

  Loader {
    id: backendLoader
    source: {
      switch (root.wm) {
        case "mangowc":  return "MangoService.qml"
        case "hyprland": return "HyprlandService.qml"
        case "niri":     return "NiriService.qml"
        default:         return "MangoService.qml"
      }
    }
    onLoaded: {
      if (item) item.active = true
    }
  }

  readonly property var activeSvc: backendLoader.item

  // Bumps whenever the backend's tag/workspace list changes so per-output
  // layout bindings re-evaluate (method calls alone are not reactive).
  readonly property var allTags: (activeSvc && activeSvc.allMonitorsTags !== undefined) ? activeSvc.allMonitorsTags : []

  readonly property string currentTitle: activeSvc ? (activeSvc.currentTitle || "") : ""

  readonly property string currentLayoutSymbol: {
    if (activeSvc && activeSvc.currentLayoutSymbol !== undefined) {
      return activeSvc.currentLayoutSymbol || ""
    }
    return ""
  }

  readonly property var availableLayouts: {
    if (activeSvc && activeSvc.availableLayouts !== undefined) {
      return activeSvc.availableLayouts || []
    }
    return []
  }

  function getLayoutSymbol(outputName) {
    if (!activeSvc) return ""
    if (root.wm === "mangowc" && activeSvc.layoutForOutput) {
      return activeSvc.layoutForOutput(outputName)
    }
    return activeSvc.currentLayoutSymbol || ""
  }

  function getLayoutInfo(symbol) {
    if (activeSvc && activeSvc.getLayoutInfo) {
      return activeSvc.getLayoutInfo(symbol)
    }
    return { symbol: symbol, name: symbol || "Unknown", icon: "󰕰", key: "" }
  }

  function setLayout(symbol) {
    if (activeSvc && activeSvc.setLayout) {
      activeSvc.setLayout(symbol)
    }
  }

  function nextLayout() {
    if (activeSvc && activeSvc.nextLayout) {
      activeSvc.nextLayout()
    }
  }

  function getWorkspaces(outputName) {
    if (!activeSvc) return []

    if (root.wm === "mangowc") {
      var tags = activeSvc.tagsForOutput(outputName)
      var maxIdx = 1
      for (var i = 0; i < tags.length; i++) {
        if (tags[i].is_active || tags[i].client_count > 0) {
          maxIdx = Math.max(maxIdx, tags[i].index)
        }
      }
      var minCount = (typeof Config !== "undefined" && Config.mangowcMinWorkspaces) ? Config.mangowcMinWorkspaces : 5
      var count = Math.max(minCount, maxIdx)
      var res = []
      for (var j = 0; j < count; j++) {
        var tData = (tags && j < tags.length) ? tags[j] : null
        var active = tData ? tData.is_active : false
        var countClients = tData ? (tData.client_count > 0) : false
        var urgent = tData ? (tData.is_urgent === true) : false
        res.push({
          id: j + 1,
          is_focused: active,
          is_active: active,
          is_occupied: countClients,
          is_urgent: urgent
        })
      }
      return res
    }

    if (root.wm === "hyprland") return activeSvc.workspacesList || []
    if (root.wm === "niri") return activeSvc.workspacesForOutput(outputName)
    return []
  }

  function focusWorkspace(id) {
    if (!activeSvc) return
    if (root.wm === "mangowc") activeSvc.focusTag(id)
    else if (root.wm === "hyprland") activeSvc.focusWorkspace(id)
    else if (root.wm === "niri") activeSvc.focusWorkspace(id)
  }

  function focusWindow(patterns) {
    WindowFocuser.focus(patterns)
  }

  // =========================================================================
  // Active / Cursor Screen Detection
  // =========================================================================
  property var _screenQueryCallback: null
  readonly property bool queryingScreen: root._screenQueryCallback !== null

  function _finishScreenQuery(foundScreen) {
    var cb = root._screenQueryCallback
    root._screenQueryCallback = null
    screenQueryTimer.stop()

    if (foundScreen) {
      Config.targetScreen = foundScreen
      Config.lastActiveScreen = foundScreen
    } else if (!Config.targetScreen) {
      Config.targetScreen = Utils.resolveActiveScreen(Config.targetScreen, Config.lastActiveScreen, Quickshell.screens)
    }

    if (typeof cb === "function") {
      cb(Config.targetScreen)
    }
  }

  function cancelScreenQuery() {
    root._screenQueryCallback = null
    screenQueryTimer.stop()
  }

  function resolveTargetScreen(callback) {
    if (Quickshell.screens.length <= 1) {
      root._screenQueryCallback = callback || null
      root._finishScreenQuery(Quickshell.screens.length === 1 ? Quickshell.screens[0] : null)
      return
    }

    var cmd = null
    if (root.wm === "mangowc") {
      cmd = ["mmsg", "get", "cursorpos"]
    } else if (root.wm === "hyprland") {
      cmd = ["hyprctl", "cursorpos"]
    } else if (root.wm === "niri") {
      cmd = ["niri", "msg", "--json", "focused-output"]
    }

    if (!cmd) {
      root._screenQueryCallback = callback || null
      root._finishScreenQuery(null)
      return
    }

    root._screenQueryCallback = callback || null
    screenQueryTimer.restart()
    cursorQueryProc.exec(cmd)
  }

  Timer {
    id: screenQueryTimer
    // Fallback for when the cursor-query process hangs. Kept generous so a
    // normal (but not instant) WM query isn't pre-empted, which would open the
    // panel on the stale `lastActiveScreen`.
    interval: 250
    repeat: false
    onTriggered: {
      if (root.queryingScreen) {
        root._finishScreenQuery(null)
      }
    }
  }

  Process {
    id: cursorQueryProc
    stdout: SplitParser {
      onRead: line => {
        if (!root.queryingScreen) return
        var txt = line.trim()
        if (!txt) return

        var foundScreen = null
        try {
          if (root.wm === "mangowc") {
            var data = JSON.parse(txt)
            if (data && data.monitor) {
              foundScreen = Utils.screenByName(data.monitor, Quickshell.screens)
            } else if (data && data.x !== undefined && data.y !== undefined) {
              foundScreen = Utils.screenAt(data.x, data.y, Quickshell.screens)
            }
          } else if (root.wm === "hyprland") {
            var parts = txt.split(",")
            if (parts.length >= 2) {
              var hx = parseInt(parts[0].trim())
              var hy = parseInt(parts[1].trim())
              if (!isNaN(hx) && !isNaN(hy)) {
                foundScreen = Utils.screenAt(hx, hy, Quickshell.screens)
              }
            }
          } else if (root.wm === "niri") {
            var niriData = JSON.parse(txt)
            if (niriData && niriData.name) {
              foundScreen = Utils.screenByName(niriData.name, Quickshell.screens)
            }
          }
        } catch (e) {}

        root._finishScreenQuery(foundScreen)
      }
    }

    onExited: function() {
      if (root.queryingScreen) {
        root._finishScreenQuery(null)
      }
    }
  }
}
