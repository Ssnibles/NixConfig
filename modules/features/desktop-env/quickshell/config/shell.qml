pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick

Scope {
  id: root

  // Expose bar toggle via IPC
  IpcHandler {
    target: "bar"

    function toggle(): void {
      Config.barVisible = !Config.barVisible
    }

    function show(): void {
      Config.barVisible = true
    }

    function hide(): void {
      Config.barVisible = false
    }
  }

  Loader {
    id: barLoader
    source: (Config.barType === "niri") ? "niri-bar.qml" : "bar.qml"
  }

  // Propagate barVisible into the loaded bar component
  Binding {
    target: barLoader.item
    property: "barVisible"
    value: Config.barVisible
    when: barLoader.item !== null
  }

  NotificationOverlay { }

  CommandCenter { }

  LockScreen { }
}
