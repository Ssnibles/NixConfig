pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick

Scope {
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
    source: "bar/bar.qml"
  }

  NotificationOverlay { }

  OsdOverlay { }

  CommandCentre { }

  Launcher { }

  LockScreen { }
}
