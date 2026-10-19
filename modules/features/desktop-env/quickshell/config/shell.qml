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
    source: "bar.qml"
  }

  NotificationOverlay { }

  OsdOverlay { }

  CommandCentre { }

  LockScreen { }
}
