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

  StatusMenu { }

  // Parked, not removed: the built-in launcher is unused while Vicinae covers
  // it. Add `Launcher { }` back here to load it again.

  ScreenshotOverlay { }

  LockScreen { }
}
