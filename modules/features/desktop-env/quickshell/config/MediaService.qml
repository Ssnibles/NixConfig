pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import "Utils.js" as Utils

// Centralised singleton managing MPRIS player state, unified position/progress
// sampling, and synchronised ticking across the bar, command centre, and lock
// screen.
//
// Position handling note: Quickshell's MprisPlayer.position is already
// interpolated against the wall clock (honouring the player's reported rate and
// pause state) and reading it always returns the current value. Crucially, its
// `positionChanged` signal only fires on non-linear changes (seeks, track
// changes) *not* continuously during normal playback -- the docs explicitly
// recommend re-reading the property or re-emitting the signal while it is being
// watched. We therefore re-read the property on every tick (and on every
// relevant player change) instead of keeping our own extrapolated copy, which
// used to drift whenever the player did not push Position updates (Firefox /
// Chromium players, live streams, after a rewind, ...).
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
  // UI surface is showing live elapsed/total time or the seek bar. Surfaces
  // register by name so overlapping hovers/overlays can't drift a counter.
  property var _consumers: ({})
  property int activeConsumers: 0
  property bool lockActive: false

  function setConsumer(name, active) {
    if (!name) return
    var was = root._consumers[name] === true
    if (active === was) return
    if (active) root._consumers[name] = true
    else delete root._consumers[name]
    var n = 0
    for (var k in root._consumers) {
      if (root._consumers[k]) n++
    }
    root.activeConsumers = n
  }

  readonly property bool isConsumerActive: (
    Config.commandCentreVisible ||
    root.lockActive ||
    (Config.barType === "niri" && Config.barVisible) ||
    root.activeConsumers > 0
  )

  // --- Position & Progress Sampling ---
  property real lastPosition: 0
  property real lastLength: 0
  property real estimatedPosition: 0
  property real progress: 0

  // Live streams report no `mpris:length`; Quickshell surfaces that as
  // lengthSupported == false (and its `length` getter falls back to `position`).
  // Such a track must never be rendered as a seekable bar with a bogus total.
  readonly property bool isLive: root.hasPlayer && !root.player.lengthSupported
  readonly property bool hasPosition: root.hasPlayer && root.player.positionSupported

  readonly property int tickInterval: 300

  // True between a seek request and the debounced seek being issued. Sampling is
  // suspended during this window so a tick can't clobber the optimistic
  // position the user just dragged to.
  property bool _seekPending: false

  // True after the seek is issued until the player confirms a position near the
  // target. Prevents a stale in-flight Position report from snapping the bar
  // back to the pre-seek time.
  property bool _seekSettling: false

  // After a track change Quickshell re-reads Position asynchronously; suppress
  // sampling until the settle timer fires so the previous track's time can't
  // flash on the new one before that refresh lands.
  property bool _trackSettling: false

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

  // Re-read the authoritative position from the player. Safe to call at any time
  // and cheap enough to run every tick.
  function sample() {
    if (root._seekPending || root._trackSettling) return
    if (!root.player) {
      root.lastPosition = 0
      root.lastLength = 0
      root.estimatedPosition = 0
      root.progress = 0
      return
    }
    var pos = root.safePos(root.player)
    var len = root.safeLen(root.player)
    // While settling a seek, ignore reports far from the target; accept the
    // first report that lands near it (seekSettleTimer releases us otherwise).
    if (root._seekSettling) {
      if (Math.abs(pos - root.lastPosition) > 1.0) return
      root._seekSettling = false
    }
    root.lastPosition = pos
    root.lastLength = len
    // Never let a stale/overrunning player base render past the track end.
    root.estimatedPosition = len > 0 ? Math.min(pos, len) : pos
    root.progress = len > 0
      ? Math.min(1, Math.max(0, pos / len))
      : 0
  }

  onPlayerChanged: {
    root._seekPending = false
    root._seekSettling = false
    root._trackSettling = false
    seekDebounceTimer.stop()
    seekSettleTimer.stop()
    trackSettleTimer.stop()
    root.sample()
  }

  // Refresh immediately as soon as a UI surface opens or is hovered.
  onIsConsumerActiveChanged: {
    if (root.isConsumerActive) root.sample()
  }

  Connections {
    target: root.player
    ignoreUnknownSignals: true
    function onPositionChanged() { root.sample() }
    function onPositionSupportedChanged() { root.sample() }
    function onLengthChanged() { root.sample() }
    function onLengthSupportedChanged() { root.sample() }
    function onTrackChanged() {
      // trackChanged fires before the new metadata/track id is applied, so
      // sampling here would resurrect the previous track's position. Clear it
      // immediately and resample once the async Position refresh has landed.
      root._trackSettling = true
      root.lastPosition = 0
      root.lastLength = 0
      root.estimatedPosition = 0
      root.progress = 0
      trackSettleTimer.restart()
    }
    function onIsPlayingChanged() { root.sample() }
  }

  // Position tick: only runs while a surface is showing the time/seek bar and
  // playback is actually advancing. Each tick re-reads the player property.
  Timer {
    id: tickTimer
    interval: root.tickInterval
    running: root.isConsumerActive && root.isPlaying
    repeat: true
    onTriggered: root.sample()
  }

  // Resamples after a track change once Quickshell's async Position refresh has
  // had time to complete (covers paused tracks too, where the tick is stopped).
  Timer {
    id: trackSettleTimer
    interval: 400
    repeat: false
    onTriggered: {
      root._trackSettling = false
      root.sample()
    }
  }

  // Fallback release for a seek that the player never confirms near the target
  // (e.g. a keyframe seek landing further away).
  Timer {
    id: seekSettleTimer
    interval: 600
    repeat: false
    onTriggered: {
      root._seekSettling = false
      root.sample()
    }
  }

  // --- Centralised Debounced Seeking ---
  Timer {
    id: seekDebounceTimer
    interval: Config.mediaSeekDebounceMs || 200
    repeat: false
    property real targetProgress: 0
    onTriggered: {
      root._seekPending = false
      if (!root.player || !root.player.canSeek) {
        root.sample()
        return
      }
      var targetPos = targetProgress * root.lastLength
      if (root.player.positionSupported) {
        root.player.position = targetPos
      } else {
        var currentPos = root.estimatedPosition
        root.player.seek(targetPos - currentPos)
      }
      // Setting position triggers a positionChanged -> sample() reading the
      // target; keep showing it until the player confirms (or the settle timer
      // releases us) so a stale report can't rewind the bar.
      root._seekSettling = true
      seekSettleTimer.restart()
    }
  }

  function seek(progressFraction) {
    if (!root.player || !root.canSeek) return
    var p = Math.max(0, Math.min(1, progressFraction))
    root._seekPending = true
    seekDebounceTimer.targetProgress = p
    seekDebounceTimer.restart()
    // Move the estimate immediately so the position tick can't rewind it before
    // the debounced MPRIS seek lands.
    root.lastPosition = p * root.lastLength
    root.estimatedPosition = root.lastPosition
    if (root.lastLength > 0) {
      root.progress = Math.min(1, Math.max(0, p))
    }
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
    WindowFocuser.focusSource(root.player)
  }
}
