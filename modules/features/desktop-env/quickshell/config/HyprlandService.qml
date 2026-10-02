pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Hyprland
import QtQuick
import "Utils.js" as Utils

QtObject {
  id: root

  property bool active: false
  property var workspacesList: []
  property string currentTitle: ""
  property int currentFocusedId: 1

  function updateData() {
    var focusedId = 1
    if (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > 0) {
      focusedId = Hyprland.focusedWorkspace.id
    }
    root.currentFocusedId = focusedId

    // Quickshell exposes the focused window through `activeToplevel`; the app
    // class lives on its raw IPC object (`class` / `initialClass`).
    var toplevel = Hyprland.activeToplevel
    if (toplevel && toplevel.title) {
      var obj = toplevel.lastIpcObject || {}
      var appId = obj.class || obj.initialClass || ""
      root.currentTitle = Utils.formatActiveTitle(toplevel.title, appId)
    } else {
      root.currentTitle = ""
    }

    if (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name) {
      var sc = Utils.screenByName(Hyprland.focusedMonitor.name, Quickshell.screens)
      if (sc) Config.lastActiveScreen = sc
    }

    var highestId = focusedId
    var occupiedMap = {}

    // `Hyprland.workspaces` is an UntypedObjectModel: iterate its `values`
    // rather than using Object.keys (which does not enumerate model entries).
    var wsList = (Hyprland.workspaces && Hyprland.workspaces.values) ? Hyprland.workspaces.values : []
    for (var k = 0; k < wsList.length; k++) {
      var wsObj = wsList[k]
      if (!wsObj) continue
      if (wsObj.id > highestId) highestId = wsObj.id
      var topl = (wsObj.toplevels && wsObj.toplevels.values) ? wsObj.toplevels.values : []
      if (topl.length > 0) occupiedMap[wsObj.id] = true
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

  // Hyprland can emit several raw events for a single action; coalesce them into
  // one recompute per event-loop turn instead of running updateData() repeatedly.
  property bool _updatePending: false

  function scheduleUpdate() {
    if (root._updatePending) return
    root._updatePending = true
    Qt.callLater(root.runUpdate)
  }

  function runUpdate() {
    root._updatePending = false
    root.updateData()
  }

  // Native zero-latency Quickshell.Hyprland IPC signal handlers
  readonly property Connections _hyprConn: Connections {
    target: root.active ? Hyprland : null
    function onFocusedWorkspaceChanged() { root.scheduleUpdate() }
    function onActiveToplevelChanged() { root.scheduleUpdate() }
    function onRawEvent(name, data) {
      if (name.startsWith("workspace") || name.startsWith("focusedmon") ||
          name.startsWith("activewindow") || name.startsWith("createworkspace") ||
          name.startsWith("destroyworkspace") || name.startsWith("movewindow") ||
          name === "urgent" || name === "openwindow" || name === "closewindow") {
        root.scheduleUpdate()
      }
    }
  }

  function focusWorkspace(id) {
    root.currentFocusedId = id
    Hyprland.dispatch("workspace " + id)
    root.scheduleUpdate()
  }

  Component.onCompleted: root.updateData()
}
