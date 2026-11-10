pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

// On-screen display state and the `system` IPC target. Hardware state lives in
// AudioService, BrightnessService, NetworkService, BatteryService,
// BluetoothService, and TrayService; this singleton only observes it.
Singleton {
  id: root

  property bool osdVisible: false
  property string osdKind: "volume" // "volume" | "mic" | "brightness"

  readonly property bool osdMuted: {
    if (root.osdKind === "volume") return AudioService.muted
    if (root.osdKind === "mic") return AudioService.micMuted
    return false
  }

  readonly property string osdIcon: {
    if (root.osdKind === "mic") return AudioService.micIcon
    if (root.osdKind === "brightness") return "󰃠"
    return AudioService.volumeIcon
  }

  // The level currently being shown, as a 0..1+ fraction (mic and volume can
  // exceed 100%). Single source for the label and the progress bar.
  readonly property real _osdLevel: root.osdKind === "mic"
    ? AudioService.micVolume
    : (root.osdKind === "brightness" ? BrightnessService.brightness : AudioService.volume)

  // Always numeric, even when muted: mute is signalled by the icon, the pill
  // border and the label colour, so the level stays visible and the label width
  // stays stable across mute and digit-count changes.
  readonly property string osdLabel: Math.round(root._osdLevel * 100) + "%"

  readonly property real osdValue: Math.max(0, Math.min(1.0, root._osdLevel))

  function showOsd(kind) {
    if (!Config.osdEnabled || Config.commandCentreVisible) return
    root.osdKind = kind || "volume"
    root.osdVisible = true
    osdHideTimer.restart()
  }

  Timer {
    id: osdHideTimer
    interval: Config.osdTimeoutMs
    repeat: false
    onTriggered: root.osdVisible = false
  }

  Connections {
    target: Config
    function onCommandCentreVisibleChanged() {
      if (Config.commandCentreVisible) {
        root.osdVisible = false
        osdHideTimer.stop()
      }
    }
  }

  // Audio and mic changes are ignored until the sink/source settles, so
  // swapping devices does not flash an OSD for the initial level report.
  property bool _audioReady: false
  property int _lastVolPct: -1
  property bool _lastMuted: false
  property int _lastMicPct: -1
  property bool _lastMicMuted: false

  function _armAudioSettle() {
    root._audioReady = false
    audioSettleTimer.restart()
  }

  function _checkSinkOsd() {
    if (!root._audioReady || !AudioService.audioSink) return
    if (AudioService.volumePercent !== root._lastVolPct || AudioService.muted !== root._lastMuted) {
      root._lastVolPct = AudioService.volumePercent
      root._lastMuted = AudioService.muted
      root.showOsd("volume")
    }
  }

  function _checkMicOsd() {
    if (!root._audioReady || !AudioService.audioSource) return
    if (AudioService.micVolumePercent !== root._lastMicPct || AudioService.micMuted !== root._lastMicMuted) {
      root._lastMicPct = AudioService.micVolumePercent
      root._lastMicMuted = AudioService.micMuted
      root.showOsd("mic")
    }
  }

  Connections {
    target: AudioService
    function onAudioSinkChanged() { root._armAudioSettle() }
    function onAudioSourceChanged() { root._armAudioSettle() }
    function onVolumePercentChanged() { root._checkSinkOsd() }
    function onMutedChanged() { root._checkSinkOsd() }
    function onMicVolumePercentChanged() { root._checkMicOsd() }
    function onMicMutedChanged() { root._checkMicOsd() }
  }

  Connections {
    target: BrightnessService
    function onOsdRequested() { root.showOsd("brightness") }
  }

  Timer {
    id: audioSettleTimer
    interval: 300
    repeat: false
    onTriggered: {
      root._lastVolPct = AudioService.volumePercent
      root._lastMuted = AudioService.muted
      root._lastMicPct = AudioService.micVolumePercent
      root._lastMicMuted = AudioService.micMuted
      root._audioReady = true
    }
  }

  IpcHandler {
    target: "system"

    function volumeUp(): void {
      AudioService.stepVolume(1)
    }

    function volumeDown(): void {
      AudioService.stepVolume(-1)
    }

    function toggleMute(): void {
      AudioService.toggleMute()
    }

    function micUp(): void {
      AudioService.stepMicVolume(1)
    }

    function micDown(): void {
      AudioService.stepMicVolume(-1)
    }

    function toggleMicMute(): void {
      AudioService.toggleMicMute()
    }

    function brightnessUp(): void {
      BrightnessService.stepBrightness(1)
    }

    function brightnessDown(): void {
      BrightnessService.stepBrightness(-1)
    }
  }

  IpcHandler {
    target: "tray"

    function toggle(): void {
      Config.trayEnabled = !Config.trayEnabled
    }

    function toggleExpanded(): void {
      Config.trayExpanded = !Config.trayExpanded
    }

    function toggleExpandButton(): void {
      Config.trayShowExpandButton = !Config.trayShowExpandButton
    }
  }

  Component.onCompleted: root._armAudioSettle()
}
