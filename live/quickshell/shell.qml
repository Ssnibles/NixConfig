import Quickshell
import QtQuick

ShellRoot {
  id: root

  Loader {
    id: barLoader
    source: "bar.qml"
  }

  Loader {
    id: notificationsLoader
    source: "notifications.qml"
  }
}
