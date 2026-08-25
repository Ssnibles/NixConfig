import Quickshell
import QtQuick

QtObject {
  id: root

  readonly property string wm: (Quickshell.env("QS_BAR") || "mangowc").toLowerCase()

  // Service Backends
  readonly property MangoService mangoSvc: MangoService { active: root.wm === "mangowc" }
  readonly property RiverService riverSvc: RiverService { active: root.wm === "river" }
  readonly property DwlService dwlSvc: DwlService { active: root.wm === "dwl" }
  readonly property HyprlandService hyprSvc: HyprlandService { active: root.wm === "hyprland" }
  readonly property NiriService niriSvc: NiriService { active: root.wm === "niri" }

  readonly property string currentTitle: {
    if (root.wm === "mangowc") return mangoSvc.currentTitle
    if (root.wm === "river") return riverSvc.currentTitle
    if (root.wm === "dwl") return dwlSvc.currentTitle
    if (root.wm === "hyprland") return hyprSvc.currentTitle
    if (root.wm === "niri") return niriSvc.currentTitle
    return ""
  }

  function getWorkspaces(outputName) {
    if (root.wm === "mangowc") {
      var tags = mangoSvc.tagsForOutput(outputName)
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

    if (root.wm === "river") return riverSvc.getWorkspaces()
    if (root.wm === "dwl") return dwlSvc.getWorkspaces(outputName)
    if (root.wm === "hyprland") return hyprSvc.workspacesList
    if (root.wm === "niri") return niriSvc.workspacesForOutput(outputName)
    return []
  }

  function focusWorkspace(id) {
    if (root.wm === "mangowc") mangoSvc.focusTag(id)
    else if (root.wm === "river") riverSvc.focusTag(id)
    else if (root.wm === "dwl") dwlSvc.focusTag(id)
    else if (root.wm === "hyprland") hyprSvc.focusWorkspace(id)
    else if (root.wm === "niri") niriSvc.focusWorkspace(id)
  }
}
