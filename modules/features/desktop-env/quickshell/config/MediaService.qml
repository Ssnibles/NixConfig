pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import "Utils.js" as Utils

// Centralized singleton managing MPRIS player state, unified position/progress estimation,
// and synchronized ticking across the bar, command center, and lock screen.
Singleton {
  id: root

  // --- Active MPRIS Player (Single Source of Truth) ---
  readonly property var mediaPlayers: Mpris.players.values
  readonly property var player: Utils.findActivePlayer(root.mediaPlayers, MprisPlaybackState.Paused)
  readonly property bool hasPlayer: !!root.player
  readonly property bool isPlaying: !!(root.player && root.player.isPlaying)

  // --- Track Metadata ---
  readonly property string rawTrackTitle: root.player ? (root.player.trackTitle || "") : ""
  readonly property string trackTitle: Utils.cleanTrackTitle(root.rawTrackTitle)
  readonly property string trackArtist: root.player ? (root.player.trackArtist || "") : ""
  readonly property string trackArtUrl: root.player ? (root.player.trackArtUrl || "") : ""
  readonly property bool canSeek: !!(root.player && root.player.canSeek)
  readonly property bool canGoNext: !!(root.player && root.player.canGoNext)
  readonly property bool canGoPrevious: !!(root.player && root.player.canGoPrevious)

  // Formatted track label for status bars
  readonly property string mediaText: root.player
    ? (root.trackArtist
      ? root.trackTitle + " — " + root.trackArtist
      : root.trackTitle)
    : ""
  readonly property bool hasMedia: root.mediaText !== ""

  // --- Consumer Demand & Activity Tracking ---
  // The position timer ONLY ticks when media is actively playing AND at least one
  // UI surface is showing live elapsed/total time or the seek bar.
  property int barHoverCount: 0
  readonly property bool barHovered: barHoverCount > 0
  property bool lockActive: false
  property int activeConsumers: 0

  readonly property bool isConsumerActive: (
    Config.commandCenterVisible ||
    root.barHovered ||
    root.lockActive ||
    (Config.barType === "niri" && Config.barVisible) ||
    root.activeConsumers > 0
  )

  // --- Position & Progress Estimation ---
  property real lastPosition: 0
  property real lastLength: 0
  property real wallClock: 0

  property real estimatedPosition: 0
  property real progress: 0

  readonly property int tickInterval: 300

  function safePos(p) {
    if (!p) return 0
    try {
      if (p.positionSupported !== undefined && !p.positionSupported) return 0
      var val = p.position
      return (typeof val === "number" && !isNaN(val) && val >= 0) ? val : 0
    } catch (e) {
      return 0
    }
  }

  function safeLen(p) {
    if (!p) return 0
    try {
      if (p.lengthSupported !== undefined && !p.lengthSupported) return 0
      var val = p.length
      return (typeof val === "number" && !isNaN(val) && val >= 0) ? val : 0
    } catch (e) {
      return 0
    }
  }

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
    var playing = false
    try { playing = !!root.player.isPlaying } catch (e) {}
    var elapsed = Date.now() / 1000 - root.wallClock
    root.estimatedPosition = root.lastPosition + (playing ? elapsed : 0)
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
    root.reset(root.safePos(root.player), root.safeLen(root.player))
  }

  // Refresh position immediately as soon as a UI surface opens or is hovered
  onIsConsumerActiveChanged: {
    if (root.isConsumerActive && root.player) {
      root.updatePosition(root.safePos(root.player), root.safeLen(root.player))
    }
  }

  Connections {
    target: root.player
    ignoreUnknownSignals: true
    function onPositionChanged() {
      if (!root.player) return
      root.updatePosition(root.safePos(root.player), root.safeLen(root.player))
    }
    function onLengthChanged() {
      if (!root.player) return
      root.lastLength = Math.max(0, root.safeLen(root.player))
      root.updateEstimatedPosition()
    }
    function onTrackChanged() {
      if (!root.player) return
      root.reset(root.safePos(root.player), root.safeLen(root.player))
    }
    function onIsPlayingChanged() {
      if (!root.player) return
      root.updatePosition(root.safePos(root.player), root.safeLen(root.player))
    }
  }

  // Unified position ticking timer: stopped when no consumer UI is active or when paused.
  Timer {
    id: tickTimer
    interval: root.tickInterval
    running: root.isConsumerActive && root.isPlaying
    repeat: true
    onTriggered: root.updateEstimatedPosition()
  }

  // --- Centralized Debounced Seeking ---
  Timer {
    id: seekDebounceTimer
    interval: Config.mediaSeekDebounceMs || 200
    repeat: false
    property real targetProgress: 0
    onTriggered: {
      if (root.player && root.player.canSeek) {
        var targetPos = targetProgress * root.lastLength
        if (root.player.positionSupported) {
          root.player.position = targetPos
        } else {
          var currentPos = root.estimatedPosition
          root.player.seek(targetPos - currentPos)
        }
        root.reset(targetPos, root.lastLength)
      }
    }
  }

  function seek(progressFraction) {
    var p = Math.max(0, Math.min(1, progressFraction))
    seekDebounceTimer.targetProgress = p
    seekDebounceTimer.restart()
    root.estimatedPosition = p * root.lastLength
    root.progress = p
  }

  // --- Common Playback Actions ---
  function playPause() {
    if (root.player) root.player.isPlaying = !root.player.isPlaying
  }

  function next() {
    if (root.player && root.player.canGoNext) root.player.next()
  }

  function previous() {
    if (root.player && root.player.canGoPrevious) root.player.previous()
  }

  function focusSource() {
    if (!root.player) return
    Utils.goToSource(root.player, Quickshell, typeof ToplevelManager !== "undefined" ? ToplevelManager : null)
  }
}
