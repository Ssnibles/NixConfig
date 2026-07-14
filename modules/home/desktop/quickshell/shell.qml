import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Root shell that loads bar, notifications, and command center as separate QML
// components so they can be individually reloaded via IPC without restarting.
ShellRoot {
  id: root
  property bool barVisible: true

  IpcHandler {
    target: "quickshell"
    function reload(name: string) {
      if (!name || name === "all") {
        barLoader.source = ""
        barLoader.source = "bar.qml"
        notificationsLoader.source = ""
        notificationsLoader.source = "notifications.qml"
        commandCenterLoader.source = ""
        commandCenterLoader.source = "CommandCenter.qml"
      } else if (name === "bar") {
        barLoader.source = ""
        barLoader.source = "bar.qml"
      } else if (name === "notifications") {
        notificationsLoader.source = ""
        notificationsLoader.source = "notifications.qml"
      } else if (name === "commandcenter") {
        commandCenterLoader.source = ""
        commandCenterLoader.source = "CommandCenter.qml"
      }
    }
  }

  IpcHandler {
    target: "bar"
    function toggle() {
      root.barVisible = !root.barVisible
    }
  }

  IpcHandler {
    target: "controlpanel"

    function toggle() {
      if (commandCenterLoader.item) {
        if (commandCenterLoader.item.visible) {
          commandCenterLoader.item.requestHide()
        } else {
          commandCenterLoader.item.visible = true
        }
      }
    }

    function show() {
      if (commandCenterLoader.item) commandCenterLoader.item.visible = true
    }

    function hide() {
      if (commandCenterLoader.item) commandCenterLoader.item.requestHide()
    }

    function toggleDnd() {
      if (notificationsLoader.item) {
        notificationsLoader.item.doNotDisturb = !notificationsLoader.item.doNotDisturb
      }
    }
  }

  IpcHandler {
    target: "sessionlock"
    function lock() {
      sessionLock.locked = true
    }
  }

  WlSessionLock {
    id: sessionLock
    surface: Component {
      LockScreen {
        onAuthenticated: sessionLock.locked = false
      }
    }
  }

  Loader {
    id: barLoader
    source: "bar.qml"
    active: root.barVisible
  }

  Loader {
    id: notificationsLoader
    source: "notifications.qml"
    onItemChanged: {
      if (item) {
        // Bind notification popup top-margin to bar visibility so popups
        // don't overlap the bar when it's shown.
        item.barVisible = Qt.binding(function() { return root.barVisible })
        if (commandCenterLoader.item) commandCenterLoader.item.root = item
      }
    }
  }

  Loader {
    id: commandCenterLoader
    active: true
    source: "CommandCenter.qml"
    onItemChanged: {
      if (item && notificationsLoader.item) {
        item.root = notificationsLoader.item
      }
    }
  }
}
