import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import Quickshell.Wayland

Scope {
  id: root

  Loader {
    id: barLoader
    source: {
      var bar = Quickshell.env("QS_BAR")
      return bar === "niri" ? "niri-bar.qml" : (bar === "river" ? "river-bar.qml" : "mangowc-bar.qml")
    }
  }

  NotificationOverlay { }

  CommandCenter { }

  LockScreen { }
}
