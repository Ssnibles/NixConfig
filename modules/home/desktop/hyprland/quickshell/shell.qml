import Quickshell
import Quickshell.Io
import QtQuick

// Root shell that loads bar, notifications, and command center as separate QML
// components so they can be individually reloaded via IPC without restarting.
ShellRoot {
  id: root
  property bool barVisible: true

  IpcHandler {
    target: "quickshell"
    function reload(component: string): void {
      if (!component || component === "all") {
        barLoader.source = ""
        barLoader.source = "bar.qml"
        notificationsLoader.source = ""
        notificationsLoader.source = "notifications.qml"
        commandCenterLoader.source = ""
        commandCenterLoader.source = "CommandCenter.qml"
      } else if (component === "bar") {
        barLoader.source = ""
        barLoader.source = "bar.qml"
      } else if (component === "notifications") {
        notificationsLoader.source = ""
        notificationsLoader.source = "notifications.qml"
      } else if (component === "commandcenter") {
        commandCenterLoader.source = ""
        commandCenterLoader.source = "CommandCenter.qml"
      }
    }
  }

  IpcHandler {
    target: "bar"
    function toggle(): void { root.barVisible = !root.barVisible; }
  }

  IpcHandler {
    target: "controlpanel"

    function toggle(): void  {
      if (commandCenterLoader.item) {
        if (commandCenterLoader.item.visible) {
          commandCenterLoader.item.requestHide();
        } else {
          commandCenterLoader.item.visible = true;
        }
      }
    }
    function show(): void    {
      if (commandCenterLoader.item) commandCenterLoader.item.visible = true;
    }
    function hide(): void    {
      if (commandCenterLoader.item) commandCenterLoader.item.requestHide();
    }
    function toggleDnd(): void {
      if (notificationsLoader.item) notificationsLoader.item.doNotDisturb = !notificationsLoader.item.doNotDisturb;
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
        item.barVisible = Qt.binding(function() { return root.barVisible; });
        if (commandCenterLoader.item) commandCenterLoader.item.root = item;
      }
    }
  }

  Loader {
    id: commandCenterLoader
    active: true
    source: "CommandCenter.qml"
    onItemChanged: {
      if (item && notificationsLoader.item) {
        item.root = notificationsLoader.item;
      }
    }
  }
}
