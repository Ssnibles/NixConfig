import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
  id: root

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

  Loader {
    id: barLoader
    source: "bar.qml"
  }

  Loader {
    id: notificationsLoader
    source: "notifications.qml"
  }
}
