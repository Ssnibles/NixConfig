pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import "../Utils.js" as Utils
import ".."

// Central PipeWire state for the default output sink and the microphone.
Singleton {
  id: root

  readonly property var audioSink: (Pipewire.ready && Pipewire.defaultAudioSink) ? Pipewire.defaultAudioSink : null
  readonly property var audioSource: (Pipewire.ready && Pipewire.defaultAudioSource) ? Pipewire.defaultAudioSource : null

  readonly property var audioSinks: {
    if (!Pipewire.ready || !Pipewire.nodes) return []
    var list = Pipewire.nodes.values || []
    var out = []
    for (var i = 0; i < list.length; i++) {
      var n = list[i]
      if (n && !n.isStream && n.isSink && n.audio) {
        out.push(n)
      }
    }
    return out
  }

  PwObjectTracker {
    objects: {
      var tracked = []
      if (root.audioSink) tracked.push(root.audioSink)
      if (root.audioSource) tracked.push(root.audioSource)
      for (var i = 0; i < root.audioSinks.length; i++) {
        if (tracked.indexOf(root.audioSinks[i]) === -1) {
          tracked.push(root.audioSinks[i])
        }
      }
      return tracked
    }
  }

  readonly property var audioInfo: root.audioSink ? root.audioSink.audio : null
  readonly property real volume: root.audioInfo ? root.audioInfo.volume : 0
  readonly property bool muted: root.audioInfo ? root.audioInfo.muted : false
  readonly property int volumePercent: Math.round(root.volume * 100)
  readonly property string volumeIcon: Utils.volumeIcon(root.volume, root.muted)

  function sinkDisplayName(node) {
    if (!node) return "Audio Output"
    return node.description || node.nickname || node.name || ("Output " + node.id)
  }

  // Short label for places where the full description is too long. PipeWire's
  // nickname drops the trailing "Analog Stereo": "DAWN PRO2" rather than
  // "DAWN PRO2 Analog Stereo".
  function sinkLabel(node) {
    if (!node) return "Audio Output"
    return node.nickname || root.sinkDisplayName(node)
  }

  // The auto-eq WirePlumber script overrides the stored default unless its
  // latch is set, so a manual choice has to set it first. `pipewire-eq on`
  // clears the latch and returns to automatic selection.
  function selectAudioSink(node) {
    if (!node) return
    Quickshell.execDetached(["pw-metadata", "-n", "default", "0", "default.auto-eq", "manual"])
    Pipewire.preferredDefaultAudioSink = node
  }

  function toggleMute() {
    if (root.audioInfo) {
      root.audioInfo.muted = !root.muted
    }
  }

  function setVolume(val) {
    if (!root.audioInfo) return
    root.audioInfo.volume = Math.max(0, Math.min(Config.volMax, val))
  }

  function setVolumeDebounced(val) {
    volSetTimer.targetVal = Math.max(0, Math.min(Config.volMax, val))
    volSetTimer.restart()
  }

  function stepVolume(direction) {
    var dir = direction > 0 ? 1 : -1
    root.setVolume(root.volume + dir * Config.volStep)
  }

  function openMixer() {
    Quickshell.execDetached(Config.cmdMixer)
  }

  Timer {
    id: volSetTimer
    interval: 50
    repeat: false
    property real targetVal: 0
    onTriggered: root.setVolume(volSetTimer.targetVal)
  }

  readonly property var audioSourceInfo: root.audioSource ? root.audioSource.audio : null
  readonly property bool hasMic: root.audioSource !== null && root.audioSourceInfo !== null
  readonly property real micVolume: root.audioSourceInfo ? root.audioSourceInfo.volume : 0
  readonly property bool micMuted: root.audioSourceInfo ? root.audioSourceInfo.muted : false
  readonly property int micVolumePercent: Math.round(root.micVolume * 100)
  readonly property string micIcon: Utils.micIcon(root.micVolume, root.micMuted)

  // True while an audio capture stream exists. A client that keeps the stream
  // open counts as trying to use the mic, even when it is idle.
  readonly property bool micInUse: {
    if (!root.hasMic || !Pipewire.ready || !Pipewire.nodes) return false
    var list = Pipewire.nodes.values || []
    for (var i = 0; i < list.length; i++) {
      var node = list[i]
      if (!node || !node.isStream) continue
      if ((node.type & PwNodeType.Audio) !== 0 && (node.type & PwNodeType.Source) !== 0) {
        return true
      }
    }
    return false
  }

  function toggleMicMute() {
    if (root.audioSourceInfo) {
      root.audioSourceInfo.muted = !root.micMuted
    }
  }

  function setMicVolume(val) {
    if (!root.audioSourceInfo) return
    root.audioSourceInfo.volume = Math.max(0, Math.min(1.0, val))
  }

  function setMicVolumeDebounced(val) {
    micSetTimer.targetVal = Math.max(0, Math.min(1.0, val))
    micSetTimer.restart()
  }

  function stepMicVolume(direction) {
    var dir = direction > 0 ? 1 : -1
    root.setMicVolume(root.micVolume + dir * Config.micStep)
  }

  Timer {
    id: micSetTimer
    interval: 50
    repeat: false
    property real targetVal: 0
    onTriggered: root.setMicVolume(micSetTimer.targetVal)
  }
}
