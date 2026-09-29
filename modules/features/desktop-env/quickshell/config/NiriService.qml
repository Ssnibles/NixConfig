import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "Utils.js" as Utils

QtObject {
  id: root

  property bool active: false
  property var allWorkspaces: []
  property string currentTitle: ""
  // Niri may send only a window id in `WindowFocusChanged`; track it so
  // follow-up `WindowOpenedOrChanged`/`WindowClosed` events can be correlated.
  property var focusedWindowId: null

  readonly property Process _niriInitWs: Process {
    command: ["niri", "msg", "--json", "workspaces"]
    running: root.active
    stdout: StdioCollector {
      onDataChanged: {
        try {
          var wsList = JSON.parse(this.text)
          if (Array.isArray(wsList)) {
            wsList.sort((a, b) => a.idx - b.idx)
            root.allWorkspaces = wsList
          }
        } catch (e) {}
      }
    }
  }

  readonly property Process _niriEvents: Process {
    command: ["niri", "msg", "--json", "event-stream"]
    running: root.active
    onExited: if (root.active) root.eventsRestartTimer.restart()

    stdout: SplitParser {
      onRead: line => {
        var cleanLine = line.trim()
        if (!cleanLine.startsWith("{")) return
        try {
          var event = JSON.parse(cleanLine)
          root.handleEvent(event)
        } catch (e) {}
      }
    }
  }

  // Restart the event stream if the compositor connection drops.
  // (QtObject has no default property, so this must be a named property.)
  readonly property Timer eventsRestartTimer: Timer {
    interval: 2000
    repeat: false
    onTriggered: if (root.active) root._niriEvents.running = true
  }

  function handleEvent(event) {
    if (event.WorkspacesChanged) {
      var wsList = event.WorkspacesChanged.workspaces
      wsList.sort((a, b) => a.idx - b.idx)
      root.allWorkspaces = wsList
    } else if (event.WorkspaceActivated) {
      var activated = event.WorkspaceActivated
      var outputName = null
      for (var i = 0; i < root.allWorkspaces.length; i++) {
        if (root.allWorkspaces[i].id === activated.id) {
          outputName = root.allWorkspaces[i].output
          break
        }
      }
      if (!outputName) return
      if (activated.focused) {
        var sc = Utils.screenByName(outputName, Quickshell.screens)
        if (sc) Config.lastActiveScreen = sc
      }
      var updated = []
      for (var j = 0; j < root.allWorkspaces.length; j++) {
        var ws = root.allWorkspaces[j]
        var isThisOutput = (ws.output === outputName)
        updated.push({
          id: ws.id,
          idx: ws.idx,
          name: ws.name,
          output: ws.output,
          is_active: isThisOutput ? (ws.id === activated.id) : ws.is_active,
          is_focused: activated.focused ? (ws.id === activated.id) : (isThisOutput ? ws.is_focused : false),
          is_urgent: ws.is_urgent
        })
      }
      root.allWorkspaces = updated
    } else if (event.WindowsChanged !== undefined) {
      // Full window list; seed the title from the currently focused window.
      var wins = event.WindowsChanged.windows || []
      var focusedWin = null
      for (var w = 0; w < wins.length; w++) {
        if (wins[w] && wins[w].is_focused) { focusedWin = wins[w]; break }
      }
      root.applyFocusedWindow(focusedWin)
    } else if (event.WindowOpenedOrChanged !== undefined) {
      // Metadata update for one window; only refresh if it is focused.
      var opened = event.WindowOpenedOrChanged.window || event.WindowOpenedOrChanged
      if (opened && root.focusedWindowId !== null && opened.id === root.focusedWindowId) {
        root.applyFocusedWindow(opened)
      }
    } else if (event.WindowFocusChanged !== undefined) {
      var wf = event.WindowFocusChanged
      var win = wf ? (wf.window || (wf.title !== undefined ? wf : null)) : null
      if (win) {
        root.applyFocusedWindow(win)
      } else if (!wf || wf.id === null || wf.id === undefined) {
        root.applyFocusedWindow(null)
      } else {
        root.focusedWindowId = wf.id
      }
    } else if (event.WindowClosed !== undefined) {
      if (event.WindowClosed.id === root.focusedWindowId) {
        root.applyFocusedWindow(null)
      }
    }
  }

  function applyFocusedWindow(win) {
    if (win && win.title !== undefined) {
      if (win.id !== undefined) root.focusedWindowId = win.id
      root.currentTitle = root.formatActiveTitle(win.title, win.app_id || win.appId || "")
    } else {
      root.focusedWindowId = null
      root.currentTitle = ""
    }
  }

  function formatActiveTitle(title, appId) {
    return Utils.formatActiveTitle(title, appId)
  }

  function focusWorkspace(id) {
    Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", id.toString()])
  }

  function focusWindow(patterns) {
    Utils.focusWindow(patterns, Quickshell, typeof ToplevelManager !== "undefined" ? ToplevelManager : null)
  }


  function workspacesForOutput(outputName) {
    var result = []
    var wsList = root.allWorkspaces
    for (var i = 0; i < wsList.length; i++) {
      if (wsList[i].output === outputName) {
        result.push(wsList[i])
      }
    }
    return result
  }
}
