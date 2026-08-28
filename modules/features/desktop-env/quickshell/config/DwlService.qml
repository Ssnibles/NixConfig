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
  property string currentLayoutSymbol: "[\\]"

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

  readonly property var availableLayouts: [
    { symbol: "[\\]", name: "Dwindle", icon: "󱗼", key: "r", wtypeKey: "r", shift: false },
    { symbol: "[]=",  name: "Tile",    icon: "󰙀", key: "t", wtypeKey: "t", shift: false },
    { symbol: "[M]",  name: "Monocle", icon: "󰍹", key: "m", wtypeKey: "m", shift: false },
    { symbol: "|||",  name: "Columns", icon: "󰡍", key: "c", wtypeKey: "c", shift: false }
  ]

  function getLayoutInfo(symbol) {
    var sym = symbol || currentLayoutSymbol
    for (var i = 0; i < availableLayouts.length; i++) {
      var item = availableLayouts[i]
      if (sym === item.symbol || sym === item.name.toLowerCase()) return item
    }
    if (sym === "><>" || sym === "floating") {
      return { symbol: "><>", name: "Floating", icon: "󰀽", key: "Shift+Space", wtypeKey: "space", shift: true }
    }
    if (sym === "[M]" || sym === "monocle" || /^\[\d+\]$/.test(sym)) {
      return { symbol: sym, name: "Monocle", icon: "󰍹", key: "m", wtypeKey: "m", shift: false }
    }
    if (sym === "[O]" || sym === "overview") {
      return { symbol: "[O]", name: "Overview", icon: "󰕰", key: "o", wtypeKey: "o", shift: false }
    }
    return { symbol: sym, name: sym || "Unknown", icon: "󰕰", key: "", wtypeKey: "", shift: false }
  }

  function focusTag(tagNum) {
    var key = tagNum === 10 ? "0" : tagNum.toString()
    Quickshell.execDetached(["wtype", "-M", "logo", "-k", key, "-m", "logo"])
  }

  function setLayout(symbol) {
    var info = getLayoutInfo(symbol)
    if (info && info.wtypeKey) {
      if (info.shift) {
        Quickshell.execDetached(["wtype", "-M", "logo", "-M", "shift", "-k", info.wtypeKey, "-m", "shift", "-m", "logo"])
      } else {
        Quickshell.execDetached(["wtype", "-M", "logo", "-k", info.wtypeKey, "-m", "logo"])
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
