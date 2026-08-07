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

var _stripCache = {}
var _stripCacheCount = 0

function stripMarkup(text) {
  if (!text || text.length === 0) return ""
  var cached = _stripCache[text]
  if (cached !== undefined) return cached
  var result = text.replace(/<[^>]*>/g, "")
  if (_stripCacheCount > 100) {
    _stripCache = {}
    _stripCacheCount = 0
  }
  _stripCache[text] = result
  _stripCacheCount++
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

var _batteryGlyphs = [
  "\u{F007A}", // <= 10%
  "\u{F007B}", // <= 20%
  "\u{F007C}", // <= 30%
  "\u{F007D}", // <= 40%
  "\u{F007E}", // <= 50%
  "\u{F007F}", // <= 60%
  "\u{F0080}", // <= 70%
  "\u{F0042}", // <= 80%
  "\u{F0082}", // <= 90%
  "\u{F0079}"  // > 90%
]

function batteryIcon(pct, charging, plugged, present) {
  if (!present) return ""
  if (charging) return "\u{F0084}"
  if (plugged) return "\u{F06A5}"
  var idx = Math.min(9, Math.max(0, Math.ceil(pct / 10) - 1))
  return _batteryGlyphs[idx]
}

function wifiIcon(signalStrength, connected) {
  if (!connected) return "\u{F092F}"
  if (signalStrength < 0.2) return "\u{F091F}"
  if (signalStrength < 0.4) return "\u{F0922}"
  if (signalStrength < 0.6) return "\u{F0925}"
  return "\u{F0928}"
}

function focusWindow(patterns, quickshellObj) {
  if (!patterns) return false
  var targets = Array.isArray(patterns) ? patterns : [patterns]
  var cleanTargets = []
  for (var i = 0; i < targets.length; i++) {
    var p = String(targets[i]).trim().toLowerCase()
    if (p && cleanTargets.indexOf(p) === -1) {
      cleanTargets.push(p)
    }
  }
  if (cleanTargets.length === 0) return false

  // 1. Try native Wayland ToplevelManager first
  var manager = null
  if (typeof ToplevelManager !== "undefined") {
    manager = ToplevelManager
  } else if (quickshellObj && typeof quickshellObj.ToplevelManager !== "undefined") {
    manager = quickshellObj.ToplevelManager
  }

  if (manager && manager.toplevels) {
    var list = manager.toplevels.values || manager.toplevels
    var count = list.length !== undefined ? list.length : (list.count !== undefined ? list.count : 0)

    for (var j = 0; j < cleanTargets.length; j++) {
      var pat = cleanTargets[j]
      for (var k = 0; k < count; k++) {
        var win = list[k] || (list.get ? list.get(k) : null)
        if (!win) continue

        var appId = win.appId ? String(win.appId).toLowerCase() : ""
        var title = win.title ? String(win.title).toLowerCase() : ""

        if ((appId && appId.indexOf(pat) !== -1) || (title && title.indexOf(pat) !== -1)) {
          if (typeof win.activate === "function") {
            win.activate()
          }
        }
      }
    }
  }

  // 2. Niri IPC focus-window action (for Niri compositor where zwlr activate is restricted)
  var qs = quickshellObj
  if (!qs && typeof Quickshell !== "undefined") qs = Quickshell
  if (qs && typeof qs.execDetached === "function") {
    var script = 'wins=$(niri msg --json windows 2>/dev/null); ' +
                 'if [ -z "$wins" ]; then exit 0; fi; ' +
                 'id=$(echo "$wins" | node -e \'' +
                 '  const fs = require("fs"); ' +
                 '  const wins = JSON.parse(fs.readFileSync(0, "utf-8")); ' +
                 '  const pats = process.argv.slice(2).map(p => p.toLowerCase()); ' +
                 '  for (const p of pats) { ' +
                 '    const found = wins.find(w => (w.app_id && w.app_id.toLowerCase().includes(p)) || (w.title && w.title.toLowerCase().includes(p))); ' +
                 '    if (found) { console.log(found.id); break; } ' +
                 '  }\' node "$@"); ' +
                 'if [ -n "$id" ] && [ "$id" != "null" ]; then niri msg action focus-window --id "$id"; fi'

    qs.execDetached(["sh", "-c", script, "sh"].concat(cleanTargets))
    return true
  }

  return false
}

function goToSource(source, quickshellObj) {
  if (!source) return
  var qs = quickshellObj
  if (!qs && typeof Quickshell !== "undefined") qs = Quickshell

  if (source.notification && source.notification.actions) {
    var defaultAction = null
    for (var a = 0; a < source.notification.actions.length; a++) {
      if (source.notification.actions[a].identifier === "default") {
        defaultAction = source.notification.actions[a]
        break
      }
    }
    if (defaultAction) {
      defaultAction.invoke()
      return
    }
  }

  var targets = []

  function addTarget(str) {
    if (!str) return
    var s = String(str).trim()
    if (!s) return

    if (s.indexOf("/") !== -1) {
      s = s.substring(s.lastIndexOf("/") + 1)
    }
    if (s.lastIndexOf(".") !== -1 && !s.endsWith(".desktop")) {
      s = s.substring(0, s.lastIndexOf("."))
    }

    if (targets.indexOf(s) === -1) targets.push(s)

    var sNoDesktop = s.replace(/\.desktop$/i, "")
    if (sNoDesktop !== s && targets.indexOf(sNoDesktop) === -1) {
      targets.push(sNoDesktop)
    }

    var sNoMpris = s.replace(/^org\.mpris\.MediaPlayer2\./i, "")
    if (sNoMpris !== s && targets.indexOf(sNoMpris) === -1) {
      targets.push(sNoMpris)
    }

    var parts = sNoDesktop.split(".")
    var lastPart = parts[parts.length - 1]
    if (lastPart && targets.indexOf(lastPart) === -1) {
      targets.push(lastPart)
    }
  }

  addTarget(source.desktopEntry)
  addTarget(source.appName || source.name)
  addTarget(source.identity)
  addTarget(source.appIcon)
  if (source.isMedia) {
    addTarget(source.trackTitle)
  }

  if (targets.length === 0) return

  focusWindow(targets, qs)
}

function focusPlayer(player, quickshellObj) {
  goToSource(player, quickshellObj)
}

function cleanUrl(url) {
  if (!url) return ""
  var str = String(url).trim()
  if (str.charAt(0) === '"' && str.charAt(str.length - 1) === '"') {
    str = str.slice(1, -1)
  }
  return str
}

function findActivePlayer(players, pausedEnum) {
  if (!players || players.length === 0) return null
  var playing = findFirst(players, function(p) { return p && p.isPlaying })
  if (playing) return playing
  return findFirst(players, function(p) {
    if (!p) return false
    if (pausedEnum !== undefined) return p.playbackState === pausedEnum
    return p.playbackState === 1 || String(p.playbackState).toLowerCase().indexOf("paused") !== -1
  })
}

function findBatteryDevice(upowerDevices, displayDevice) {
  if (upowerDevices && upowerDevices.count > 0) {
    for (var i = 0; i < upowerDevices.count; i++) {
      var d = upowerDevices.get(i)
      if (d && d.isLaptopBattery && d.ready) return d
    }
  }
  return (displayDevice && displayDevice.ready) ? displayDevice : null
}
