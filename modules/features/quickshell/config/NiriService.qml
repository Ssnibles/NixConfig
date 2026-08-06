import Quickshell
import Quickshell.Io
import QtQuick
import "Utils.js" as Utils

QtObject {
  id: root

  property var allWorkspaces: []
  property string currentTitle: ""

  readonly property Process _niriEvents: Process {
    command: ["niri", "msg", "--json", "event-stream"]
    running: true

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
      var updated = []
      for (var j = 0; j < root.allWorkspaces.length; j++) {
        var ws = root.allWorkspaces[j]
        if (ws.output === outputName) {
          updated.push({
            id: ws.id,
            idx: ws.idx,
            name: ws.name,
            output: ws.output,
            is_active: ws.id === activated.id,
            is_focused: activated.focused ? ws.id === activated.id : ws.is_focused,
            is_urgent: ws.is_urgent
          })
        } else {
          updated.push(ws)
        }
      }
      root.allWorkspaces = updated
    } else if (event.WindowFocused !== undefined) {
      var focus = event.WindowFocused
      if (focus) {
        root.currentTitle = root.formatActiveTitle(focus.title, focus.app_id)
      } else {
        root.currentTitle = ""
      }
    }
  }

  function formatActiveTitle(title, appId) {
    return Utils.formatActiveTitle(title, appId)
  }

  function focusWorkspace(id) {
    Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", id.toString()])
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
