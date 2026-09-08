import Quickshell
import Quickshell.Io
import QtQuick
import "Utils.js" as Utils

QtObject {
  id: root

  property bool active: false
  property var allMonitorsTags: []
  property string currentTitle: ""
  property string currentLayoutSymbol: "DW"

  // Continuous listener for MangoWC JSON stream for workspace tags
  readonly property Process _tagsWatcher: Process {
    command: ["mmsg", "watch", "all-tags"]
    running: root.active

    stdout: SplitParser {
      onRead: line => {
        var cleanLine = line.trim()
        if (!cleanLine.startsWith("{")) return

        try {
          var data = JSON.parse(cleanLine)
          if (data.all_tags) {
            root.allMonitorsTags = data.all_tags

            var activeMonName = Config.lastActiveScreen ? Config.lastActiveScreen.name : ""
            var foundSym = ""
            for (var m = 0; m < data.all_tags.length; m++) {
              var mon = data.all_tags[m]
              if (!activeMonName || mon.monitor === activeMonName) {
                for (var t = 0; t < mon.tags.length; t++) {
                  if (mon.tags[t].is_active) {
                    foundSym = mon.tags[t].layout
                    break
                  }
                }
                if (foundSym) break
              }
            }
            if (!foundSym && data.all_tags.length > 0 && data.all_tags[0].tags) {
              for (var t0 = 0; t0 < data.all_tags[0].tags.length; t0++) {
                if (data.all_tags[0].tags[t0].is_active) {
                  foundSym = data.all_tags[0].tags[t0].layout
                  break
                }
              }
            }
            if (foundSym) {
              root.currentLayoutSymbol = foundSym
            }
          }
        } catch (e) {}
      }
    }
  }

  // Continuous listener for focused client changes (window title)
  readonly property Process _titleWatcher: Process {
    command: ["mmsg", "watch", "focusing-client"]
    running: root.active

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
          if (data && (data.title || data.app_id || data.appId || data.class || data.name)) {
            var title = data.title || data.name || ""
            var appId = data.app_id || data.appId || data.class || data.instance || ""
            root.currentTitle = Utils.formatActiveTitle(title, appId)
          } else {
            root.currentTitle = ""
          }
          if (data && data.monitor) {
            var sc = Config.screenByName(data.monitor)
            if (sc) Config.lastActiveScreen = sc
          }
        } catch (e) {
          root.currentTitle = ""
        }
      }
    }
  }

  readonly property var availableLayouts: [
    { symbol: "DW", name: "Dwindle", layoutName: "dwindle", icon: "󱗼", key: "r" },
    { symbol: "T",  name: "Tile",    layoutName: "tile",    icon: "󰙀", key: "t" },
    { symbol: "M",  name: "Monocle", layoutName: "monocle", icon: "󰍹", key: "m" },
    { symbol: "S",  name: "Scroller",layoutName: "scroller",icon: "󰡍", key: "p" },
    { symbol: "G",  name: "Grid",    layoutName: "grid",    icon: "󱒅", key: "" },
    { symbol: "K",  name: "Deck",    layoutName: "deck",    icon: "󰘲", key: "" }
  ]

  function getLayoutInfo(symbol) {
    var sym = symbol || root.currentLayoutSymbol || "DW"
    var symUpper = sym.toUpperCase()
    var symLower = sym.toLowerCase()

    for (var i = 0; i < availableLayouts.length; i++) {
      var item = availableLayouts[i]
      if (symUpper === item.symbol || symLower === item.layoutName || symLower === item.name.toLowerCase()) {
        return item
      }
    }

    if (symUpper === "CT" || symLower === "center_tile") {
      return { symbol: "CT", name: "Center Tile", layoutName: "center_tile", icon: "󰕴", key: "" }
    }
    if (symUpper === "RT" || symLower === "right_tile") {
      return { symbol: "RT", name: "Right Tile", layoutName: "right_tile", icon: "󰙀", key: "" }
    }
    if (symUpper === "VS" || symLower === "vertical_scroller") {
      return { symbol: "VS", name: "V-Scroller", layoutName: "vertical_scroller", icon: "󰡍", key: "" }
    }
    if (symUpper === "VT" || symLower === "vertical_tile") {
      return { symbol: "VT", name: "V-Tile", layoutName: "vertical_tile", icon: "󰙀", key: "" }
    }
    if (symUpper === "VG" || symLower === "vertical_grid") {
      return { symbol: "VG", name: "V-Grid", layoutName: "vertical_grid", icon: "󱒅", key: "" }
    }
    if (symUpper === "VK" || symLower === "vertical_deck") {
      return { symbol: "VK", name: "V-Deck", layoutName: "vertical_deck", icon: "󰘲", key: "" }
    }
    if (symUpper === "F" || symLower === "fair") {
      return { symbol: "F", name: "Fair", layoutName: "fair", icon: "󰕰", key: "" }
    }
    if (symUpper === "VF" || symLower === "vertical_fair") {
      return { symbol: "VF", name: "V-Fair", layoutName: "vertical_fair", icon: "󰕰", key: "" }
    }
    if (symLower === "overview" || sym === "󰃇") {
      return { symbol: "󰃇", name: "Overview", layoutName: "overview", icon: "󰃇", key: "" }
    }
    if (sym === "><>" || symLower === "floating") {
      return { symbol: "><>", name: "Floating", layoutName: "floating", icon: "󰀽", key: "v" }
    }

    return { symbol: sym, name: sym, layoutName: symLower, icon: "󰕰", key: "" }
  }

  function setLayout(symbolOrName) {
    var info = getLayoutInfo(symbolOrName)
    var name = info.layoutName || (info.name ? info.name.toLowerCase() : symbolOrName.toLowerCase())
    root.currentLayoutSymbol = info.symbol
    Quickshell.execDetached(["mmsg", "dispatch", "setlayout," + name])
  }

  function nextLayout() {
    var curSym = (root.currentLayoutSymbol || "DW").toUpperCase()
    var curIdx = -1
    for (var i = 0; i < availableLayouts.length; i++) {
      if (availableLayouts[i].symbol === curSym || availableLayouts[i].layoutName === curSym.toLowerCase()) {
        curIdx = i
        break
      }
    }
    var nextIdx = (curIdx + 1) % availableLayouts.length
    setLayout(availableLayouts[nextIdx].symbol)
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

  function layoutForOutput(outputName) {
    var tags = tagsForOutput(outputName)
    for (var i = 0; i < tags.length; i++) {
      if (tags[i].is_active) {
        return tags[i].layout || "DW"
      }
    }
    return root.currentLayoutSymbol || "DW"
  }
}
