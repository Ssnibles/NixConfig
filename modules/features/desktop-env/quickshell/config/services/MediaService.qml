pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import "../Utils.js" as Utils
import ".."

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

  // Active MPRIS Player (Single Source of Truth)
  readonly property var mediaPlayers: Mpris.players.values
  property var selectedPlayer: null
  readonly property var player: Utils.resolveMprisPlayer(root.mediaPlayers, root.selectedPlayer, MprisPlaybackState.Paused)
  readonly property bool hasPlayer: !!root.player
  readonly property bool isPlaying: !!(root.player && root.player.isPlaying)
  readonly property int playerCount: root.mediaPlayers ? root.mediaPlayers.length : 0
  readonly property int playerIndex: (root.player && root.mediaPlayers) ? root.mediaPlayers.indexOf(root.player) : -1
  readonly property string playerName: root.player ? Utils.prettifyAppName(root.player.identity || root.player.desktopEntry || "Media") : ""
  readonly property string playerGlyph: {
    var key = root.playerName.toLowerCase()
    if (Config.notifAppGlyphs && Config.notifAppGlyphs[key]) return Config.notifAppGlyphs[key]
    return "󰎈"
  }

  onMediaPlayersChanged: {
    if (root.selectedPlayer && (!root.mediaPlayers || root.mediaPlayers.indexOf(root.selectedPlayer) === -1)) {
      root.selectedPlayer = null
    }
  }

  function cyclePlayer(step) {
    var next = Utils.cyclePlayer(root.mediaPlayers, root.player, step)
    if (next) root.selectedPlayer = next
  }

  // Track Metadata
  readonly property string rawTrackTitle: root.player ? (root.player.trackTitle || "") : ""
  readonly property string trackTitle: Utils.cleanTrackTitle(root.rawTrackTitle)
  readonly property string trackArtist: root.player ? (root.player.trackArtist || "") : ""
  readonly property string trackArtUrl: {
    var u = Utils.cleanUrl(root.player ? (root.player.trackArtUrl || "") : "")
    return u.startsWith("/") ? ("file://" + u) : u
  }

  // Local copy of the current artwork, as a file URL. Every surface that shows
  // the cover and the colour palette read this one file, so a track's art is
  // fetched once instead of once per consumer. artSource is what the cards
  // display (falling back to the raw URL if the fetch fails); artFile is the
  // local copy, and is what the palette reads.
  property string artSource: ""
  property string artFile: ""
  property string _artSourceUrl: ""
  property var _artFiles: ({})
  property var _artQueue: []
  property string _downloadingUrl: ""

  readonly property string artCacheDir: Quickshell.cacheDir + "/media-art"

  onTrackArtUrlChanged: root.refreshArtSource()
  Component.onCompleted: root.refreshArtSource()

  function refreshArtSource() {
    var url = root.trackArtUrl
    if (url === root._artSourceUrl) return
    root._artSourceUrl = url
    root.artSource = ""
    root.artFile = ""

    if (url === "") return
    if (url.startsWith("file://")) {
      root.artSource = url
      root.artFile = url
      return
    }
    if (!url.startsWith("http")) {
      // Providers such as image://qsimage/ are loadable by Image directly.
      root.artSource = url
      return
    }

    var cached = root._artFiles[url]
    if (cached && cached.ready) {
      root.artSource = cached.path
      root.artFile = cached.path
      return
    }
    if (!cached) {
      root._artFiles[url] = { path: "file://" + root.artCacheDir + "/" + root.hashUrl(url), ready: false }
      root.pruneArtFiles()
    }
    if (root._artQueue.indexOf(url) === -1) root._artQueue.push(url)
    root.startArtDownload()
  }

  // Downloads run one at a time so a track change mid-fetch cannot mix up which
  // file belongs to which artwork.
  function startArtDownload() {
    if (root._downloadingUrl !== "" || root._artQueue.length === 0) return
    var url = root._artQueue.shift()
    var entry = root._artFiles[url]
    if (!entry || entry.ready) {
      root.startArtDownload()
      return
    }
    root._downloadingUrl = url
    artDownloadProc.exec([
      "sh", "-c",
      "mkdir -p \"$1\" && curl -fsSL --max-time 20 --max-filesize 4000000 -o \"$2\" \"$3\"",
      "media-art", root.artCacheDir, entry.path.replace("file://", ""), url
    ])
  }

  function dropArtFile(url) {
    var entry = root._artFiles[url]
    if (!entry) return
    delete root._artFiles[url]
    artCleanProc.exec(["rm", "-f", entry.path.replace("file://", "")])
  }

  function pruneArtFiles() {
    var keys = Object.keys(root._artFiles)
    if (keys.length <= 24) return
    for (var i = 0; i < keys.length; i++) {
      if (keys[i] === root._artSourceUrl || keys[i] === root._downloadingUrl) continue
      root.dropArtFile(keys[i])
      return
    }
  }

  function hashUrl(url) {
    var hash = 0
    var hash2 = 7
    for (var i = 0; i < url.length; i++) {
      hash = (hash * 31 + url.charCodeAt(i)) | 0
      hash2 = (hash2 * 17 + url.charCodeAt(i)) | 0
    }
    return Math.abs(hash).toString(16) + Math.abs(hash2).toString(16)
  }

  Process {
    id: artDownloadProc

    onExited: function(exitCode) {
      var url = root._downloadingUrl
      root._downloadingUrl = ""
      var entry = root._artFiles[url]
      if (entry) {
        if (exitCode === 0) {
          entry.ready = true
          root.artFile = entry.path
          if (url === root._artSourceUrl) root.artSource = entry.path
        } else {
          root.dropArtFile(url)
          // Fall back to the raw URL so the cards still show the cover.
          if (url === root._artSourceUrl) root.artSource = root.trackArtUrl
        }
      }
      root.startArtDownload()
    }
  }

  Process {
    id: artCleanProc
  }
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

  // Consumer Demand & Activity Tracking
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

  readonly property bool isSeekbarConsumerActive: (
    UiState.commandCentreVisible ||
    root.lockActive ||
    root.activeConsumers > 0
  )

  readonly property bool isConsumerActive: (
    root.isSeekbarConsumerActive ||
    (Session.barType === "niri" && UiState.barVisible)
  )

  // Position & Progress Sampling
  property real lastPosition: 0
  property real lastLength: 0
  property real estimatedPosition: 0
  property real progress: 0

  // Live streams report no `mpris:length`; Quickshell surfaces that as
  // lengthSupported == false (and its `length` getter falls back to `position`).
  // Such a track must never be rendered as a seekable bar with a bogus total.
  // lengthSupported also drops out for a moment while a new track's metadata
  // arrives, so a track only counts as live once it has stayed unsupported.
  property bool _lengthUnsupported: false
  readonly property bool isLive: root.hasPlayer && root._lengthUnsupported

  function refreshLengthSupport() {
    if (!root.player || root.player.lengthSupported) {
      liveSettleTimer.stop()
      root._lengthUnsupported = false
    } else if (!liveSettleTimer.running) {
      liveSettleTimer.restart()
    }
  }

  readonly property int tickInterval: root.isSeekbarConsumerActive ? 400 : 1000

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
    root.refreshLengthSupport()
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
    function onLengthSupportedChanged() {
      root.refreshLengthSupport()
      root.sample()
    }
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
      root.refreshLengthSupport()
    }
    function onIsPlayingChanged() { root.sample() }
  }

  // Position tick: only runs while a surface is showing the time/seek bar and
  // playback is actually advancing. Each tick re-reads the player property.
  Timer {
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

  // Releases the live decision only after a track has kept reporting no length,
  // so a track change does not flash the seek bar out and back.
  Timer {
    id: liveSettleTimer
    interval: 1200
    repeat: false
    onTriggered: root._lengthUnsupported = root.player ? !root.player.lengthSupported : false
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

  // Centralised Debounced Seeking
  Timer {
    id: seekDebounceTimer
    interval: Config.mediaSeekDebounceMs
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
      // Setting position triggers a positionChanged, which samples the
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

  // Common Playback Actions
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

  IpcHandler {
    target: "media"

    function playPause(): void {
      root.playPause()
    }

    function next(): void {
      root.next()
    }

    function previous(): void {
      root.previous()
    }

    function cyclePlayer(): void {
      root.cyclePlayer(1)
    }
  }
}
