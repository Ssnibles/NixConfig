pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import "Utils.js" as Utils

// System tray items, including the per-session hide/unhide lists. Shared by
// every bar so all monitors show the same items.
Singleton {
  id: root

  readonly property var trayAllItems: (Config.trayEnabled && SystemTray.items && SystemTray.items.values)
    ? SystemTray.items.values
    : []

  function trayItemKey(item) {
    if (!item) return ""
    return String(item.id || item.title || item.tooltipTitle || "")
  }

  function isTrayItemHidden(item) {
    if (!item) return false
    var key = root.trayItemKey(item)
    var sessionHidden = Config.runtimeHiddenTrayApps || []
    var sessionUnhidden = Config.runtimeUnhiddenTrayApps || []
    if (key && sessionHidden.indexOf(key) !== -1) return true
    if (key && sessionUnhidden.indexOf(key) !== -1) return false
    return Utils.isTrayItemHidden(item, Config.trayHiddenApps)
  }

  function toggleTrayItemHidden(item) {
    if (!item) return
    var key = root.trayItemKey(item)
    if (!key) return
    var currentlyHidden = root.isTrayItemHidden(item)
    var nextHidden = (Config.runtimeHiddenTrayApps || []).slice()
    var nextUnhidden = (Config.runtimeUnhiddenTrayApps || []).slice()
    var hIdx = nextHidden.indexOf(key)
    var uIdx = nextUnhidden.indexOf(key)

    if (currentlyHidden) {
      if (hIdx !== -1) nextHidden.splice(hIdx, 1)
      if (Utils.isTrayItemHidden(item, Config.trayHiddenApps) && uIdx === -1) {
        nextUnhidden.push(key)
      }
    } else {
      if (uIdx !== -1) nextUnhidden.splice(uIdx, 1)
      if (hIdx === -1) nextHidden.push(key)
    }

    Config.runtimeHiddenTrayApps = nextHidden
    Config.runtimeUnhiddenTrayApps = nextUnhidden
    if (root.trayHiddenCount === 0) Config.trayExpanded = false
  }

  readonly property int trayHiddenCount: {
    var count = 0
    for (var i = 0; i < root.trayAllItems.length; i++) {
      if (root.isTrayItemHidden(root.trayAllItems[i])) count++
    }
    return count
  }

  readonly property bool trayShowHiddenItems: Config.trayShowExpandButton && Config.trayExpanded

  readonly property var trayVisibleItems: {
    var out = []
    for (var i = 0; i < root.trayAllItems.length; i++) {
      var item = root.trayAllItems[i]
      if (!item) continue
      if (!root.isTrayItemHidden(item) || root.trayShowHiddenItems) {
        out.push(item)
      }
    }
    return out
  }

  readonly property bool trayHasContent: Config.trayEnabled
    && (root.trayVisibleItems.length > 0 || (Config.trayShowExpandButton && root.trayHiddenCount > 0))
}
