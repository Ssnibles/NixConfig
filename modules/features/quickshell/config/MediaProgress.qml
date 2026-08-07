import Quickshell
import QtQuick

// Reusable MPRIS position estimator. Watch a player object and expose live
// estimatedPosition (seconds) and progress (0..1), including wall-clock
// drift while playing and rewind/restart detection.
Scope {
  id: root

  property bool enabled: true
  property var player: null
  property int tickInterval: 300

  property real lastPosition: 0
  property real lastLength: 0
  property real wallClock: 0

  property real estimatedPosition: 0
  property real progress: 0

  function reset(pos, len) {
    root.lastPosition = Math.max(0, pos || 0)
    root.lastLength = Math.max(0, len || 0)
    root.wallClock = Date.now() / 1000
    root.updateEstimatedPosition()
  }

  function updatePosition(pos, len) {
    var p = Math.max(0, pos || 0)
    var l = Math.max(0, len || 0)
    if (p + 0.5 < root.lastPosition) {
      root.reset(p, l)
      return
    }
    root.lastPosition = p
    root.lastLength = l
    root.wallClock = Date.now() / 1000
    root.updateEstimatedPosition()
  }

  function updateEstimatedPosition() {
    if (!root.player) {
      root.estimatedPosition = root.lastPosition
      root.progress = 0
      return
    }
    var elapsed = Date.now() / 1000 - root.wallClock
    root.estimatedPosition = root.lastPosition + (root.player.isPlaying ? elapsed : 0)
    if (root.lastLength > 0) {
      root.progress = Math.min(1, Math.max(0, root.estimatedPosition / root.lastLength))
    } else {
      root.progress = 0
    }
  }

  onPlayerChanged: {
    if (!root.player) {
      root.reset(0, 0)
      return
    }
    root.reset(root.player.position, root.player.length)
  }

  Connections {
    target: root.player
    ignoreUnknownSignals: true
    function onPositionChanged() {
      if (!root.player) return
      root.updatePosition(root.player.position, root.player.length)
    }
    function onLengthChanged() {
      if (!root.player) return
      root.lastLength = Math.max(0, root.player.length || 0)
      root.updateEstimatedPosition()
    }
    function onTrackChanged() {
      if (!root.player) return
      root.reset(root.player.position, root.player.length)
    }
    function onIsPlayingChanged() {
      if (!root.player) return
      root.updatePosition(root.player.position, root.player.length)
    }
  }

  Timer {
    id: tickTimer
    interval: root.tickInterval
    running: root.enabled && root.player && root.player.isPlaying
    repeat: true
    onTriggered: {
      root.updateEstimatedPosition()
    }
  }
}