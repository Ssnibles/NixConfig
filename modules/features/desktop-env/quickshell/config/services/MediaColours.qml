pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import ".."

// Palette pulled from the current cover art with Quickshell's ColorQuantizer, so
// the bento media card can tint its text, controls and seek bar from the
// artwork. The art itself is cached as a local file by MediaService, so this
// reads the same file the cards display and fetches nothing.
Singleton {
  id: root

  property string artUrl: MediaService.trackArtUrl
  property string artFile: MediaService.artFile
  property var _cache: ({})
  property string _pendingUrl: ""

  readonly property var fallback: ({
    accent: Colours.accent,
    onAccent: Colours.bg,
    text: Colours.fg,
    detail: Colours.fgMid,
    track: Colours.bgSubtle,
    trackStrong: Colours.bgRaised,
    pill: Colours.bgSubtle,
    pillStrong: Colours.bgRaised
  })

  // Last resolved palette. A track change keeps these colours until the new
  // artwork's palette lands, so the card never flashes back to the theme.
  property var _lastPalette: root.fallback

  readonly property var palette: root._cache[root.artUrl] !== undefined
    ? root._cache[root.artUrl]
    : root._lastPalette

  onArtUrlChanged: {
    // Nothing playing: drop the tinted colours so the card returns to the theme.
    if (root.artUrl === "") root._lastPalette = root.fallback
  }
  onArtFileChanged: root.request()
  Component.onCompleted: root.request()

  function request() {
    if (root.artFile === "" || root.artUrl === "" || root._pendingUrl !== "") return
    if (root._cache[root.artUrl] !== undefined) return
    root._pendingUrl = root.artUrl
    // Clearing first makes the quantiser rerun even if this file was read before.
    quantizer.source = ""
    quantizer.source = root.artFile
  }

  function finish(colours) {
    if (colours && colours.length > 0) root.store(root._pendingUrl, colours)
    root._pendingUrl = ""
    root.request()
  }

  // Turns the quantised list into a small palette that works on a dark theme:
  // one accent at a fixed lightness, tinted text, and opaque quiet surfaces.
  function store(url, colours) {
    if (url === "") return

    var best = null
    var bestScore = -1
    for (var i = 0; i < colours.length; i++) {
      var colour = colours[i]
      var saturation = colour.hslSaturation
      var lightness = colour.hslLightness
      if (saturation < 0.12 || lightness < 0.12 || lightness > 0.9) continue
      var score = saturation * (1 - Math.abs(lightness - 0.55))
      if (score > bestScore) {
        bestScore = score
        best = colour
      }
    }
    if (!best) best = colours[0]
    if (best.hslHue < 0) return

    var hue = best.hslHue
    var saturation = best.hslSaturation

    // The scrim above the text always leaves a mid-to-dark background, even on
    // a near-white cover, so the text stays light. The tint is kept low: a
    // strong tint of a muted cover (beige, sepia) blends into the artwork.
    var textColour = Qt.hsla(hue, Math.min(0.18, saturation), 0.97, 1)
    var detailColour = Qt.hsla(hue, Math.min(0.16, saturation), 0.84, 1)

    // Quiet surfaces follow the cover's own lightness so they stay visible on
    // the scrimmed artwork: a pale rail over a light cover, a dark one over a
    // dark cover.
    var totalLightness = 0
    for (var j = 0; j < colours.length; j++) totalLightness += colours[j].hslLightness
    var lightCover = totalLightness / colours.length > 0.62

    var next = {}
    for (var key in root._cache) next[key] = root._cache[key]
    next[url] = {
      accent: Qt.hsla(hue, Math.max(0.45, Math.min(0.85, saturation)), 0.62, 1),
      onAccent: Qt.hsla(hue, 0.35, 0.12, 1),
      text: textColour,
      detail: detailColour,
      track: lightCover
        ? Qt.hsla(hue, 0.22, 0.82, 1)
        : Qt.hsla(hue, 0.28, 0.24, 1),
      trackStrong: lightCover
        ? Qt.hsla(hue, 0.26, 0.7, 1)
        : Qt.hsla(hue, 0.32, 0.36, 1),
      // Chips stay dark so the light detail text sits on them.
      pill: Qt.hsla(hue, 0.28, 0.22, 1),
      pillStrong: Qt.hsla(hue, 0.32, 0.34, 1)
    }

    var keys = Object.keys(next)
    if (keys.length > 24) delete next[keys[0]]
    root._cache = next
    if (url === root.artUrl) root._lastPalette = next[url]
  }

  ColorQuantizer {
    id: quantizer
    // 16 colours from a 32px copy: stable enough for a dominant hue, cheap
    // enough to run per track on the thread pool.
    depth: 4
    rescaleSize: 32

    // 0.3.2 reports the result through colorsChanged; operationFinished is the
    // internal slot, not a signal handler.
    onColorsChanged: root.finish(quantizer.colors)
  }
}
