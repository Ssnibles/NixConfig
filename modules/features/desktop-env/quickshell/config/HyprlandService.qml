import Quickshell
import Quickshell.Hyprland
import QtQuick
import "Utils.js" as Utils

QtObject {
  id: root

  property var workspacesList: []
  property string currentTitle: ""
  property int currentFocusedId: 1

  function updateData() {
    var focusedId = 1
    if (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > 0) {
      focusedId = Hyprland.focusedWorkspace.id
    }
    root.currentFocusedId = focusedId

    if (Hyprland.focusedWindow && Hyprland.focusedWindow.title) {
      root.currentTitle = Utils.formatActiveTitle(Hyprland.focusedWindow.title, Hyprland.focusedWindow.class || "")
    } else if (Hyprland.activeWindow && Hyprland.activeWindow.title) {
      root.currentTitle = Utils.formatActiveTitle(Hyprland.activeWindow.title, Hyprland.activeWindow.class || "")
    } else {
      root.currentTitle = ""
    }

    var highestId = focusedId
    var occupiedMap = {}

    if (Hyprland.workspaces) {
      var keys = Object.keys(Hyprland.workspaces)
      for (var k = 0; k < keys.length; k++) {
        var wsObj = Hyprland.workspaces[keys[k]]
        if (wsObj) {
          if (wsObj.id > highestId) highestId = wsObj.id
          if (wsObj.windows > 0) occupiedMap[wsObj.id] = true
        }
      }
    }

    var totalCount = Math.max(5, highestId)
    var result = []

    for (var i = 1; i <= totalCount; i++) {
      var isFocused = (i === focusedId)
      var isOccupied = occupiedMap[i] ? true : false
      result.push({
        id: i,
        is_focused: isFocused,
        is_active: isFocused,
        is_occupied: isOccupied,
        is_urgent: false
      })
    }
    root.workspacesList = result
  }

  // Native zero-latency Quickshell.Hyprland IPC signal handlers
  readonly property Connections _hyprConn: Connections {
    target: Hyprland
    function onFocusedWorkspaceChanged() { root.updateData() }
    function onRawEvent(name, data) { root.updateData() }
  }

  function focusWorkspace(id) {
    root.currentFocusedId = id
    Hyprland.dispatch("workspace " + id)
    root.updateData()
  }

  Component.onCompleted: root.updateData()
}
