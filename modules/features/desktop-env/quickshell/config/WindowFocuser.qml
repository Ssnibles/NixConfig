pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "Utils.js" as Utils

// Window activation with a native-first strategy:
//   1. Quickshell's `ToplevelManager` (`zwlr_foreign_toplevel_management`) when
//      the compositor exposes it — zero process spawns.
//   2. Otherwise the compositor's own IPC (MangoWC `mmsg`, Niri, Hyprland),
//      queried and scored in QML. This replaces the old fallback that shelled
//      out to a large inline Node script.
Singleton {
  id: root

  // Patterns for the in-flight IPC query, in preference order.
  property var _pendingPatterns: []

  Process {
    id: listProc
    stdout: StdioCollector {
      onStreamFinished: root._handleList(this.text)
    }
  }

  Process {
    id: focusProc
  }

  // Focus the window behind a notification / MPRIS player / app descriptor.
  function focusSource(source) {
    if (!source) return
    var targets = Utils.goToSource(source)
    if (targets && targets.length > 0) focus(targets)
  }

  function focus(patterns) {
    if (!patterns || patterns.length === 0) return

    // 1. Native foreign-toplevel path.
    var manager = typeof ToplevelManager !== "undefined" ? ToplevelManager : null
    if (manager && manager.toplevels) {
      var nativeBest = _bestMatch(manager.toplevels.values || [], null, patterns)
      if (nativeBest && typeof nativeBest.activate === "function") {
        nativeBest.activate()
        return
      }
    }

    // 2. Compositor IPC fallback.
    _focusViaIpc(patterns)
  }

  function _focusViaIpc(patterns) {
    root._pendingPatterns = patterns
    var wm = Config.wm
    if (wm === "niri") listProc.exec(["niri", "msg", "--json", "windows"])
    else if (wm === "hyprland") listProc.exec(["hyprctl", "clients", "-j"])
    else listProc.exec(["mmsg", "get", "all-clients"])
  }

  function _handleList(text) {
    var patterns = root._pendingPatterns
    root._pendingPatterns = []
    if (!patterns || patterns.length === 0 || !text) return

    var wm = Config.wm
    var list = []
    try {
      var data = JSON.parse(text)
      if (wm === "niri" || wm === "hyprland") list = Array.isArray(data) ? data : []
      else list = (data && data.clients) ? data.clients : []
    } catch (e) {
      return
    }

    var best = _bestMatch(list, wm, patterns)
    if (best) _activate(best, wm)
  }

  function _activate(win, wm) {
    if (wm === "niri") {
      focusProc.exec(["niri", "msg", "action", "focus-window", "--id", String(win.id)])
    } else if (wm === "hyprland") {
      if (win.address) focusProc.exec(["hyprctl", "dispatch", "focuswindow", "address:" + win.address])
    } else {
      focusProc.exec(["mmsg", "dispatch", "focusid", "client," + win.id])
    }
  }

  function _appIdOf(win, wm) {
    if (!win) return ""
    if (wm === null) return win.appId || win.app_id || ""
    if (wm === "niri") return win.app_id || win.appId || ""
    if (wm === "hyprland") return win.class || win.initialClass || ""
    return win.appid || win.app_id || win.class || ""
  }

  // Mirrors the previous Node scorer: exact appId > exact title > appId
  // substring > title substring, with earlier patterns preferred.
  function _matchScore(appId, title, patterns) {
    appId = (appId || "").toLowerCase()
    title = (title || "").toLowerCase()
    for (var i = 0; i < patterns.length; i++) {
      var p = String(patterns[i]).toLowerCase()
      if (appId === p) return 100 - i
      if (title === p) return 90 - i
      if (appId.indexOf(p) !== -1) return 80 - i
      if (title.indexOf(p) !== -1) return 70 - i
    }
    return 0
  }

  function _bestMatch(list, wm, patterns) {
    var best = null
    var bestScore = 0
    for (var i = 0; i < list.length; i++) {
      var win = list[i]
      if (!win) continue
      var score = _matchScore(_appIdOf(win, wm), win.title || "", patterns)
      if (score > bestScore) {
        bestScore = score
        best = win
      }
    }
    return best
  }
}
