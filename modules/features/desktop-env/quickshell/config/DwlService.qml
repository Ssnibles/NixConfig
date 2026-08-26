import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "Utils.js" as Utils

QtObject {
  id: root

  property bool active: false
  property var monitorTags: ({})
  property int selectedTagMask: 1
  property int occupiedTagMask: 0
  property string currentTitle: ""
  property string currentAppId: ""
  property string currentLayoutSymbol: "RT"

  readonly property Process _statusWatcher: Process {
    command: ["sh", "-c", "exec stdbuf -oL tail -F -n +1 /tmp/dwl-status.fifo 2>/dev/null"]
    running: root.active

    stdout: SplitParser {
      onRead: line => {
        var clean = line.trim()
        if (!clean) return
        var parts = clean.split(/\s+/)
        if (parts.length < 2) return

        var outputName = parts[0]
        var component = parts[1]

        if (component === "title") {
          var titleStr = parts.slice(2).join(" ").trim()
          root.currentTitle = Utils.formatActiveTitle(titleStr, root.currentAppId)
        } else if (component === "appid") {
          var appIdStr = parts.slice(2).join(" ").trim()
          root.currentAppId = appIdStr
        } else if (component === "layout") {
          var layoutStr = parts.slice(2).join(" ").trim()
          if (layoutStr) root.currentLayoutSymbol = layoutStr
        } else if (component === "tags" || component === "workspace") {
          if (parts.length >= 4) {
            var occupied = parseInt(parts[2], 10)
            var selected = parseInt(parts[3], 10)
            if (!isNaN(occupied) && !isNaN(selected)) {
              var copy = Object.assign({}, root.monitorTags)
              copy[outputName] = { occupied: occupied, selected: selected }
              root.monitorTags = copy

              root.occupiedTagMask = occupied
              root.selectedTagMask = selected
            }
          }
        }
      }
    }
  }

  function focusTag(tagNum) {
    var key = tagNum === 10 ? "0" : tagNum.toString()
    Quickshell.execDetached(["wtype", "-M", "logo", "-k", key, "-m", "logo"])
  }

  function setLayout(symbol) {
    var key = ""
    var useShift = false
    if (symbol === "RT" || symbol === "tree") { key = "t"; }
    else if (symbol === "[]=" || symbol === "tile") { key = "t"; useShift = true; }
    else if (symbol === "><>" || symbol === "floating") { key = "v"; }
    else if (symbol === "[M]" || symbol === "monocle" || /^\[\d+\]$/.test(symbol)) { key = "m"; }
    else if (symbol === "[\\]" || symbol === "dwindle") { key = "r"; }
    else if (symbol === "(@)" || symbol === "spiral") { key = "s"; }

    if (key !== "") {
      if (useShift) {
        Quickshell.execDetached(["wtype", "-M", "logo", "-M", "shift", "-k", key, "-m", "shift", "-m", "logo"])
      } else {
        Quickshell.execDetached(["wtype", "-M", "logo", "-k", key, "-m", "logo"])
      }
    }
  }

  function getWorkspaces(outputName) {
    var selMask = root.selectedTagMask
    var occMask = root.occupiedTagMask

    if (outputName && root.monitorTags[outputName]) {
      selMask = root.monitorTags[outputName].selected
      occMask = root.monitorTags[outputName].occupied
    }

    var result = []
    var highestOccupiedOrSelected = 1

    for (var j = 1; j <= 10; j++) {
      var m = 1 << (j - 1)
      if ((selMask & m) !== 0 || (occMask & m) !== 0) {
        highestOccupiedOrSelected = Math.max(highestOccupiedOrSelected, j)
      }
    }

    var count = Math.max(5, highestOccupiedOrSelected)

    for (var i = 1; i <= count; i++) {
      var mask = 1 << (i - 1)
      var active = (selMask & mask) !== 0
      var occupied = (occMask & mask) !== 0
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
