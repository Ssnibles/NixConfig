pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

// Screen backlight control via brightnessctl, with a sysfs watcher for changes
// made by other tools.
Singleton {
  id: root

  // Emitted when the level changed and the OSD should be shown.
  signal osdRequested()

  property real brightness: 0.5
  property bool brightnessAvailable: false
  property string backlightDevice: ""
  property bool _notifyBrightnessOnNextRead: false
  property bool _brightnessRefreshPending: false
  readonly property int brightnessPercent: Math.round(root.brightness * 100)

  function refreshBrightness(notifyOsd) {
    if (notifyOsd) root._notifyBrightnessOnNextRead = true
    if (!brightnessGetProc.running) {
      brightnessGetProc.exec(["brightnessctl", "-m"])
    } else {
      root._brightnessRefreshPending = true
    }
  }

  function setBrightness(val) {
    var clamped = Math.max(0, Math.min(1.0, val))
    root.brightness = clamped
    brightnessSetTimer.targetVal = clamped
    brightnessSetTimer.restart()
  }

  function stepBrightness(direction) {
    if (!root.brightnessAvailable) return
    var dir = direction > 0 ? 1 : -1
    root.setBrightness(root.brightness + dir * Config.brightnessStep)
    root.osdRequested()
  }

  FileView {
    id: backlightWatcher
    path: root.backlightDevice !== "" ? ("/sys/class/backlight/" + root.backlightDevice + "/brightness") : ""
    watchChanges: root.backlightDevice !== ""
    onFileChanged: {
      if (!brightnessSetTimer.running) {
        root.refreshBrightness(true)
      }
    }
  }

  Process {
    id: brightnessGetProc
    command: ["brightnessctl", "-m"]
    stdout: StdioCollector {
      onStreamFinished: {
        var shouldNotify = root._notifyBrightnessOnNextRead
        root._notifyBrightnessOnNextRead = false
        var lines = this.text.trim().split("\n")
        for (var i = 0; i < lines.length; i++) {
          var parts = lines[i].split(",")
          if (parts.length >= 4 && parts[1] === "backlight") {
            var pct = parseInt(parts[3].replace("%", "")) / 100.0
            if (!isNaN(pct)) {
              var prevPct = root.brightnessPercent
              root.backlightDevice = parts[0] || ""
              root.brightness = pct
              root.brightnessAvailable = true
              if (shouldNotify && root.brightnessPercent !== prevPct) {
                root.osdRequested()
              }
              if (root._brightnessRefreshPending) {
                root._brightnessRefreshPending = false
                brightnessGetProc.exec(["brightnessctl", "-m"])
              }
              return
            }
          }
        }
        root.brightnessAvailable = false
        if (root._brightnessRefreshPending) {
          root._brightnessRefreshPending = false
          brightnessGetProc.exec(["brightnessctl", "-m"])
        }
      }
    }
  }

  Timer {
    id: brightnessSetTimer
    interval: 50
    repeat: false
    property real targetVal: 0
    onTriggered: {
      Quickshell.execDetached(["brightnessctl", "set", Math.round(brightnessSetTimer.targetVal * 100) + "%"])
    }
  }

  Component.onCompleted: root.refreshBrightness(false)
}
