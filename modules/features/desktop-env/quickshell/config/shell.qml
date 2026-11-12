pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick

Scope {
  IpcHandler {
    target: "bar"

    function toggle(): void {
      UiState.barVisible = !UiState.barVisible
    }

    function show(): void {
      UiState.barVisible = true
    }

    function hide(): void {
      UiState.barVisible = false
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
