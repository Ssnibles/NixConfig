import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import Quickshell.Wayland

Scope {
  id: root

  readonly property string barType: {
    var env = (Quickshell.env("QS_BAR") || "").toLowerCase()
    if (env) return env
    var xdg = (Quickshell.env("XDG_CURRENT_DESKTOP") || Quickshell.env("XDG_SESSION_DESKTOP") || "").toLowerCase()
    if (xdg.indexOf("niri") !== -1) return "niri"
    return "bar"
  }

  Loader {
    id: barLoader
    source: (root.barType === "niri") ? "niri-bar.qml" : "bar.qml"
  }

  NotificationOverlay { }

  CommandCenter { }

  LockScreen { }
}
