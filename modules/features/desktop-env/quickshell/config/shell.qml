import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import Quickshell.Wayland

Scope {
  id: root

  Loader {
    id: barLoader
    source: {
      if (bar === "niri") return "niri-bar.qml"
      if (bar === "river") return "river-bar.qml"
      if (bar === "hyprland") return "hyprland-bar.qml"
      return "mangowc-bar.qml"
    }
  }

  NotificationOverlay { }

  CommandCenter { }

  LockScreen { }
}
