import Quickshell
import QtQuick

Scope {
  id: root

  readonly property string wm: Config.wm

  Loader {
    id: backendLoader
    source: {
      switch (root.wm) {
        case "mangowc":  return "MangoService.qml"
        case "river":    return "RiverService.qml"
        case "dwl":      return "DwlService.qml"
        case "hyprland": return "HyprlandService.qml"
        case "niri":     return "NiriService.qml"
        default:         return "MangoService.qml"
      }
    }
    onLoaded: {
      if (item) item.active = true
    }
  }

  readonly property var activeSvc: backendLoader.item

  readonly property string currentTitle: activeSvc ? (activeSvc.currentTitle || "") : ""

  readonly property string currentLayoutSymbol: {
    if (root.wm === "dwl" && activeSvc) return activeSvc.currentLayoutSymbol || ""
    return ""
  }

  readonly property var availableLayouts: {
    if (root.wm === "dwl" && activeSvc) return activeSvc.availableLayouts || []
    return []
  }

  function getLayoutInfo(symbol) {
    if (root.wm === "dwl" && activeSvc) return activeSvc.getLayoutInfo(symbol)
    return { symbol: symbol, name: symbol || "Unknown", icon: "󰕰", key: "" }
  }

  function setLayout(symbol) {
    if (root.wm === "dwl" && activeSvc) activeSvc.setLayout(symbol)
  }

  function getWorkspaces(outputName) {
    if (!activeSvc) return []

    if (root.wm === "mangowc") {
      var tags = activeSvc.tagsForOutput(outputName)
      var maxIdx = 1
      for (var i = 0; i < tags.length; i++) {
        if (tags[i].is_active || tags[i].client_count > 0) {
          maxIdx = Math.max(maxIdx, tags[i].index)
        }
      }
      var count = Math.max(5, maxIdx)
      var res = []
      for (var j = 0; j < count; j++) {
        var tData = (tags && j < tags.length) ? tags[j] : null
        var active = tData ? tData.is_active : (j === 0)
        var countClients = tData ? (tData.client_count > 0) : false
        res.push({
          id: j + 1,
          is_focused: active,
          is_active: active,
          is_occupied: countClients,
          is_urgent: false
        })
      }
      return res
    }

    if (root.wm === "river") return activeSvc.getWorkspaces()
    if (root.wm === "dwl") return activeSvc.getWorkspaces(outputName)
    if (root.wm === "hyprland") return activeSvc.workspacesList || []
    if (root.wm === "niri") return activeSvc.workspacesForOutput(outputName)
    return []
  }

  function focusWorkspace(id) {
    if (!activeSvc) return
    if (root.wm === "mangowc") activeSvc.focusTag(id)
    else if (root.wm === "river") activeSvc.focusTag(id)
    else if (root.wm === "dwl") activeSvc.focusTag(id)
    else if (root.wm === "hyprland") activeSvc.focusWorkspace(id)
    else if (root.wm === "niri") activeSvc.focusWorkspace(id)
  }
}
