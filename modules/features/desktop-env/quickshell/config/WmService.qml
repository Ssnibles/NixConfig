import Quickshell
import QtQuick

QtObject {
  id: root

  readonly property string wm: {
    var xdg = (Quickshell.env("XDG_CURRENT_DESKTOP") || Quickshell.env("XDG_SESSION_DESKTOP") || "").toLowerCase()
    if (xdg.includes("dwl")) return "dwl"
    if (xdg.includes("hyprland")) return "hyprland"
    if (xdg.includes("river")) return "river"
    if (xdg.includes("niri")) return "niri"
    if (xdg.includes("mango")) return "mangowc"

    var envWm = (Quickshell.env("QS_BAR") || "").toLowerCase()
    if (envWm !== "") return envWm

    return "mangowc"
  }

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

  readonly property string currentLayoutSymbol: {
    if (root.wm === "dwl") return dwlSvc.currentLayoutSymbol
    return ""
  }

  readonly property var availableLayouts: [
    { symbol: "[]=", name: "Tile", icon: "󰙀", key: "t" },
    { symbol: "[M]", name: "Monocle", icon: "󰍹", key: "m" },
    { symbol: "[\\]", name: "Dwindle", icon: "󱗼", key: "r" },
    { symbol: "(@)", name: "Spiral", icon: "󰑖", key: "s" }
  ]

  function getLayoutInfo(symbol) {
    var sym = symbol || currentLayoutSymbol
    if (sym === "[]=") return { symbol: "[]=", name: "Tile", icon: "󰙀", key: "t" }
    if (sym === "><>") return { symbol: "><>", name: "Floating", icon: "󰀽", key: "v" }
    if (sym === "[M]" || /^\[\d+\]$/.test(sym)) return { symbol: "[M]", name: "Monocle", icon: "󰍹", key: "m" }
    if (sym === "[\\]") return { symbol: "[\\]", name: "Dwindle", icon: "󱗼", key: "r" }
    if (sym === "(@)") return { symbol: "(@)", name: "Spiral", icon: "󰑖", key: "s" }
    return { symbol: sym, name: sym || "Unknown", icon: "󰕰", key: "" }
  }

  function setLayout(symbol) {
    if (root.wm === "dwl") dwlSvc.setLayout(symbol)
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
