import Quickshell
import Quickshell.Io
import QtQuick

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
      } else if (component === "bar") {
        barLoader.source = ""
        barLoader.source = "bar.qml"
      } else if (component === "notifications") {
        notificationsLoader.source = ""
        notificationsLoader.source = "notifications.qml"
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
      if (notificationsLoader.item) {
        notificationsLoader.item.controlPanelVisible = !notificationsLoader.item.controlPanelVisible;
      }
    }
    function show(): void    {
      if (notificationsLoader.item) notificationsLoader.item.controlPanelVisible = true;
    }
    function hide(): void    {
      if (notificationsLoader.item) notificationsLoader.item.controlPanelVisible = false;
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
  }
}
