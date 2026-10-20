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
  readonly property var workspacesDependency: (activeSvc && activeSvc.allMonitorsTags !== undefined)
    ? activeSvc.allMonitorsTags
    : ((activeSvc && activeSvc.allWorkspaces !== undefined)
        ? activeSvc.allWorkspaces
        : (activeSvc ? activeSvc.workspacesList : []))

  readonly property string currentTitle: activeSvc ? (activeSvc.currentTitle || "") : ""

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
    if (activeSvc.workspacesForOutput) return activeSvc.workspacesForOutput(outputName)
    if (activeSvc.workspacesList) return activeSvc.workspacesList
    return []
  }

  function focusWorkspace(id) {
    if (activeSvc && activeSvc.focusWorkspace) {
      activeSvc.focusWorkspace(id)
    }
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
    stdout: StdioCollector {
      onStreamFinished: {
        if (!root.queryingScreen) return
        var txt = this.text ? this.text.trim() : ""
        if (!txt) {
          root._finishScreenQuery(null)
          return
        }

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
