import Quickshell
import Quickshell.Io
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

  // Bar visibility state (toggled via IPC)
  property bool barVisible: true

  // Expose bar toggle via IPC
  IpcHandler {
    target: "bar"

    function toggle(): void {
      root.barVisible = !root.barVisible
    }

    function show(): void {
      root.barVisible = true
    }

    function hide(): void {
      root.barVisible = false
    }
  }

  Loader {
    id: barLoader
    source: (root.barType === "niri") ? "niri-bar.qml" : "bar.qml"
  }

  // Propagate barVisible into the loaded bar component
  Binding {
    target: barLoader.item
    property: "barVisible"
    value: root.barVisible
    when: barLoader.item !== null
  }

  NotificationOverlay { }

  CommandCenter { }

  LockScreen { }
}
