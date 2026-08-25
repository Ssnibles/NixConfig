import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "Utils.js" as Utils

QtObject {
  id: root

  property int selectedTagMask: 1
  property int occupiedTagMask: 0
  property string currentTitle: ""
  property string currentAppId: ""

  readonly property Process _statusWatcher: Process {
    command: ["sh", "-c", "exec tail -F -n +1 /tmp/dwl-status.fifo 2>/dev/null"]
    running: true

    stdout: SplitParser {
      onRead: line => {
        var clean = line.trim()
        if (!clean) return
        var parts = clean.split(/\s+/)
        if (parts.length < 2) return

        var component = parts[1]

        if (component === "title") {
          var titleStr = parts.slice(2).join(" ").trim()
          root.currentTitle = Utils.formatActiveTitle(titleStr, root.currentAppId)
        } else if (component === "appid") {
          var appIdStr = parts.slice(2).join(" ").trim()
          root.currentAppId = appIdStr
        } else if (component === "tags") {
          if (parts.length >= 4) {
            var occupied = parseInt(parts[2], 10)
            var selected = parseInt(parts[3], 10)
            if (!isNaN(occupied)) root.occupiedTagMask = occupied
            if (!isNaN(selected)) root.selectedTagMask = selected
          }
        }
      }
    }
  }

  function focusTag(tagNum) {
    var key = tagNum === 10 ? "0" : tagNum.toString()
    Quickshell.execDetached(["wtype", "-M", "logo", "-k", key])
  }

  function getWorkspaces() {
    var result = []
    var highestOccupiedOrSelected = 1

    for (var j = 1; j <= 10; j++) {
      var m = 1 << (j - 1)
      if ((root.selectedTagMask & m) !== 0 || (root.occupiedTagMask & m) !== 0) {
        highestOccupiedOrSelected = Math.max(highestOccupiedOrSelected, j)
      }
    }

    var count = Math.max(5, highestOccupiedOrSelected)

    for (var i = 1; i <= count; i++) {
      var mask = 1 << (i - 1)
      var active = (root.selectedTagMask & mask) !== 0
      var occupied = (root.occupiedTagMask & mask) !== 0
      result.push({
        id: i,
        is_focused: active,
        is_active: active,
        is_occupied: occupied,
        is_urgent: false
      })
    }
    return result
  }
}
