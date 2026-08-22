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
      if (bar === "niri") return "niri-bar.qml"
      if (bar === "hyprland") return "hyprland-bar.qml"
      return "mangowc-bar.qml"
    }
  }

  NotificationOverlay { }

  CommandCenter { }

  LockScreen { }
}
