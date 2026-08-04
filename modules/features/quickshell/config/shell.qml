import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Scope {
  id: root

  Loader {
    id: barLoader
    source: {
      var bar = Quickshell.env("QS_BAR")
      return bar === "niri" ? "niri-bar.qml" : "mangowc-bar.qml"
    }
  }

  NotificationOverlay { position: "top-right" }
}
