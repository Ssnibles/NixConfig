import Quickshell
import Quickshell.Io
import QtQuick
import "Utils.js" as Utils

QtObject {
  id: root

  property var allMonitorsTags: []
  property string currentTitle: ""

  // Continuous listener for MangoWC JSON stream for workspace tags
  readonly property Process _tagsWatcher: Process {
    command: ["mmsg", "watch", "all-tags"]
    running: true

    stdout: SplitParser {
      onRead: line => {
        var cleanLine = line.trim()
        if (!cleanLine.startsWith("{")) return

        try {
          var data = JSON.parse(cleanLine)
          if (data.all_tags) {
            root.allMonitorsTags = data.all_tags
          }
        } catch (e) {}
      }
    }
  }

  // Continuous listener for focused client changes (window title)
  readonly property Process _titleWatcher: Process {
    command: ["mmsg", "watch", "focusing-client"]
    running: true

    stdout: SplitParser {
      onRead: line => {
        var cleanLine = line.trim()
        if (!cleanLine.startsWith("{")) {
          if (cleanLine === "" || cleanLine === "null") {
            root.currentTitle = ""
          }
          return
        }

        try {
          var data = JSON.parse(cleanLine)
          if (data && (data.title || data.app_id || data.name)) {
            var title = data.title || data.name || ""
            var appId = data.app_id || data.appId || data.class || ""
            root.currentTitle = Utils.formatActiveTitle(title, appId)
          } else {
            root.currentTitle = ""
          }
        } catch (e) {
          root.currentTitle = ""
        }
      }
    }
  }

  function focusTag(tagNum) {
    Quickshell.execDetached(["mmsg", "tag", tagNum.toString()])
  }

  function tagsForOutput(outputName) {
    if (!root.allMonitorsTags || root.allMonitorsTags.length === 0) return []
    for (var i = 0; i < root.allMonitorsTags.length; i++) {
      if (root.allMonitorsTags[i].monitor === outputName) {
        return root.allMonitorsTags[i].tags || []
      }
    }
    return root.allMonitorsTags[0] ? (root.allMonitorsTags[0].tags || []) : []
  }
}
