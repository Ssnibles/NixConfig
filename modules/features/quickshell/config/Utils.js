.pragma library

function findFirst(list, predicate) {
  for (var i = 0; i < list.length; i++) {
    if (predicate(list[i])) return list[i]
  }
  return null
}

function cleanTrackTitle(title) {
  if (!title) return ""
  var str = String(title).trim()
  // Strip leading browser tab notification counts like (940) or (12)
  str = str.replace(/^\(\d+\)\s*/, "")
  // Strip trailing site suffixes like - YouTube or - SoundCloud
  str = str.replace(/\s*-\s*(YouTube|SoundCloud|Spotify)$/i, "")
  return str.trim()
}

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value))
}

function pad2(n) {
  return n < 10 ? "0" + n : "" + n
}

function formatTime(seconds) {
  var s = Math.round(seconds)
  if (s < 0) s = 0
  var m = Math.floor(s / 60)
  s = s % 60
  return m + ":" + pad2(s)
}

function escapeRegex(value) {
  return String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
}

var _stripCache = ({})

function stripMarkup(text) {
  if (!text || text.length === 0) return ""
  var cached = _stripCache[text]
  if (cached !== undefined) return cached
  var result = text.replace(/<[^>]*>/g, "")
  if (Object.keys(_stripCache).length < 100) _stripCache[text] = result
  return result
}

var _appNameOverrides = {
  "zen": "Zen",
  "zen-browser": "Zen",
  "zen-beta": "Zen",
  "firefox": "Firefox",
  "org.mozilla.firefox": "Firefox",
  "nvim": "Neovim",
  "neovim": "Neovim",
  "foot": "Foot"
}

function prettifyAppName(className) {
  if (!className) return ""
  var key = String(className).toLowerCase()
  if (_appNameOverrides[key]) return _appNameOverrides[key]
  key = key.replace(/\.desktop$/, "")
  if (_appNameOverrides[key]) return _appNameOverrides[key]
  var base = String(className).split(".").pop()
  base = base.replace(/[-_]+/g, " ")
  return base.replace(/\b\w/g, function(c) { return c.toUpperCase() })
}

var _titleSuffixMap = {
  " — Zen Browser": "Zen",
  " — Mozilla Firefox": "Firefox",
  " - nvim": "Neovim",
  " - foot": null // keep app name, just drop the suffix
}

function formatActiveTitle(title, appId) {
  var appName = prettifyAppName(appId)
  title = title || ""

  for (var suffix in _titleSuffixMap) {
    if (title.endsWith(suffix)) {
      title = title.slice(0, title.length - suffix.length)
      if (_titleSuffixMap[suffix]) appName = _titleSuffixMap[suffix]
      break
    }
  }

  title = String(title).trim()
  if (appName && title && title !== appName) return appName + ": " + title
  return appName || title
}

function volumeIcon(volPct, muted) {
  if (muted || volPct <= 0) return "\u{F075F}"
  if (volPct < 0.33) return "\u{F057F}"
  if (volPct < 0.66) return "\u{F0580}"
  return "\u{F057E}"
}

function batteryIcon(pct, charging, plugged, present) {
  if (!present) return ""
  if (charging) return "\u{F0084}"
  if (plugged) return "\u{F06A5}"
  if (pct <= 10) return "\u{F007A}"
  if (pct <= 20) return "\u{F007B}"
  if (pct <= 30) return "\u{F007C}"
  if (pct <= 40) return "\u{F007D}"
  if (pct <= 50) return "\u{F007E}"
  if (pct <= 60) return "\u{F007F}"
  if (pct <= 70) return "\u{F0080}"
  if (pct <= 80) return "\u{F0042}"
  if (pct <= 90) return "\u{F0082}"
  return "\u{F0079}"
}

function wifiIcon(signalStrength, connected) {
  if (!connected) return "\u{F092F}"
  if (signalStrength < 0.2) return "\u{F091F}"
  if (signalStrength < 0.4) return "\u{F0922}"
  if (signalStrength < 0.6) return "\u{F0925}"
  return "\u{F0928}"
}
