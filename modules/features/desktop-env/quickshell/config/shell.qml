import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import Quickshell.Wayland

Scope {
  id: root

  readonly property string barType: (Quickshell.env("QS_BAR") || "").toLowerCase()

  Loader {
    id: barLoader
    source: (root.barType === "niri") ? "niri-bar.qml" : "bar.qml"
  }

  NotificationOverlay { }

  CommandCenter { }

  LockScreen { }
}
