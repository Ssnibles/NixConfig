import Quickshell
import QtQuick

// Reusable MPRIS position estimator. Watch a player object and expose live
// estimatedPosition (seconds) and progress (0..1), including wall-clock
// drift while playing and rewind/restart detection.
Scope {
  id: root

  property var player: null
  property int tickInterval: 300

  property real lastPosition: 0
  property real lastLength: 0
  property int tick: 0
  property int resetToken: 0
  property real wallClock: 0

  function reset(pos, len) {
    root.lastPosition = Math.max(0, pos || 0)
    root.lastLength = Math.max(0, len || 0)
    root.wallClock = Date.now() / 1000
    root.tick = 0
    root.resetToken++
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
  }

  property real estimatedPosition: {
    var _ = root.tick
    var __ = root.resetToken
    if (!root.player) return root.lastPosition
    var elapsed = Date.now() / 1000 - root.wallClock
    return root.lastPosition + (root.player.isPlaying ? elapsed : 0)
  }

  property real progress: {
    var _ = root.tick
    var __ = root.resetToken
    if (!root.player || root.lastLength <= 0) return 0
    return Math.min(1, Math.max(0, root.estimatedPosition / root.lastLength))
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
    }
    function onTrackChanged() {
      if (!root.player) return
      root.reset(root.player.position, root.player.length)
    }
  }

  Timer {
    id: tickTimer
    interval: root.tickInterval
    running: root.player && root.player.isPlaying
    repeat: true
    onTriggered: {
      if (root.player) {
        root.updatePosition(root.player.position, root.player.length)
      }
      root.tick++
    }
  }
}