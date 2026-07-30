import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

Scope {
  id: root

  Loader {
    id: barLoader
  }

  NotificationOverlay { position: "top-right" }

  Process {
    id: barCheck
    command: ["sh", "-c", "echo -n ${QS_BAR:-mangowc}"]
    running: true

    stdout: SplitParser {
      onRead: function (line) {
        var bar = line.trim()
        barLoader.source = bar === "niri" ? "niri-bar.qml" : "mangowc-bar.qml"
      }
    }
  }
}
