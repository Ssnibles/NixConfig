import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "Utils.js" as Utils

QtObject {
  id: root

  property int focusedTagMask: 1
  property int viewsTagMask: 0
  property string currentTitle: ""

  // Watch focused tag bitmask from ristate -t
  readonly property Process _tagWatcher: Process {
    command: ["ristate", "-t"]
    running: true

    stdout: SplitParser {
      onRead: line => {
        var clean = line.trim()
        var val = parseInt(clean, 10)
        if (!isNaN(val)) {
          root.focusedTagMask = val
        }
      }
    }
  }

  // Watch occupied views tag bitmask from ristate -vt
  readonly property Process _viewsTagWatcher: Process {
    command: ["ristate", "-vt"]
    running: true

    stdout: SplitParser {
      onRead: line => {
        var clean = line.trim()
        var val = parseInt(clean, 10)
        if (!isNaN(val)) {
          root.viewsTagMask = val
        }
      }
    }
  }

  // Watch focused view title from ristate -w
  readonly property Process _titleWatcher: Process {
    command: ["ristate", "-w"]
    running: true

    stdout: SplitParser {
      onRead: line => {
        var clean = line.trim()
        if (clean === "" || clean === "null") {
          root.currentTitle = ""
        } else {
          try {
            var data = JSON.parse(clean)
            if (data && typeof data === "object") {
              var title = (data.title && data.title !== "null") ? String(data.title).trim() : ""
              var appId = (data.app_id || data.appid || data.appId) ? String(data.app_id || data.appid || data.appId).trim() : ""
              if (!title && !appId) {
                root.currentTitle = ""
              } else {
                root.currentTitle = Utils.formatActiveTitle(title, appId)
              }
            } else {
              root.currentTitle = Utils.formatActiveTitle(clean, "")
            }
          } catch (e) {
            root.currentTitle = Utils.formatActiveTitle(clean, "")
          }
        }
      }
    }
  }

  function focusTag(tagNum) {
    var mask = 1 << (tagNum - 1)
    Quickshell.execDetached(["riverctl", "set-focused-tags", mask.toString()])
  }

  function getWorkspaces() {
    var result = []
    var highestOccupiedOrFocused = 1

    for (var j = 1; j <= 9; j++) {
      var m = 1 << (j - 1)
      if ((root.focusedTagMask & m) !== 0 || (root.viewsTagMask & m) !== 0) {
        highestOccupiedOrFocused = Math.max(highestOccupiedOrFocused, j)
      }
    }

    var count = Math.max(5, highestOccupiedOrFocused)

    for (var i = 1; i <= count; i++) {
      var mask = 1 << (i - 1)
      var active = (root.focusedTagMask & mask) !== 0
      var occupied = (root.viewsTagMask & mask) !== 0
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
