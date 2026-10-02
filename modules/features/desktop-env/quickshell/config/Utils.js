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

var _appNameOverrides = {
  "antigravity": "Antigravity",
  "antigravity-editor": "Antigravity",
  "helium": "Helium",
  "helium-browser": "Helium",
  "firefox": "Firefox",
  "firefox-developer-edition": "Firefox",
  "firefox-devedition": "Firefox",
  "firefoxdevedition": "Firefox",
  "firefox-aurora": "Firefox",
  "org.mozilla.firefox": "Firefox",
  "org.mozilla.firefoxdeveloperedition": "Firefox",
  "nvim": "Neovim",
  "neovim": "Neovim",
  "foot": "Foot",
  "kitty": "Kitty",
  "alacritty": "Alacritty",
  "code": "Code",
  "code-url-handler": "Code",
  "vscode": "Code",
  "discord": "Discord",
  "vesktop": "Vesktop",
  "webcord": "Discord",
  "spotify": "Spotify",
  "thunar": "Files",
  "nemo": "Files",
  "nautilus": "Files",
  "qutebrowser": "Qutebrowser"
}

var _knownApps = [
  "Antigravity",
  "Neovim",
  "Zen Browser",
  "Zen",
  "Firefox Developer Edition",
  "Firefox Dev Edition",
  "Firefox",
  "Mozilla Firefox",
  "Google Chrome",
  "Chromium",
  "Foot",
  "Kitty",
  "Ghostty",
  "Alacritty",
  "Code",
  "VSCode",
  "VSCodium",
  "Discord",
  "Vesktop",
  "WebCord",
  "Spotify",
  "Obsidian",
  "Thunderbird",
  "LibreOffice",
  "Qutebrowser",
  "Thunar",
  "Nemo",
  "Nautilus",
  "Steam",
  "GIMP",
  "Inkscape",
  "Blender",
  "VLC",
  "mpv",
  "Telegram",
  "Slack",
  "Signal"
]

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
  " — Firefox Developer Edition": "Firefox",
  " - Firefox Developer Edition": "Firefox",
  " — Firefox Dev Edition": "Firefox",
  " - Firefox Dev Edition": "Firefox",
  " — Mozilla Firefox": "Firefox",
  " - Mozilla Firefox": "Firefox",
  " — Firefox": "Firefox",
  " - Firefox": "Firefox",
  " — Zen Browser": "Zen",
  " - nvim": "Neovim",
  " - foot": null // keep app name, just drop the suffix
}

function formatActiveTitle(title, appId) {
  title = title ? String(title).trim() : ""
  var appName = prettifyAppName(appId)

  if (!title) return appName

  // If title is just the browser/app name itself (e.g. "Firefox Developer Edition")
  var tLower = title.toLowerCase()
  if (tLower === "firefox developer edition" || tLower === "firefox dev edition" || tLower === "mozilla firefox") {
    return appName || "Firefox"
  }

  // 1. If title already follows "Program: Title" format, keep it as is
  var colonIdx = title.indexOf(":")
  if (colonIdx > 0 && colonIdx < 30) {
    var prefix = title.substring(0, colonIdx).trim()
    var rest = title.substring(colonIdx + 1).trim()
    if (prefix && rest) {
      return title
    }
  }

  // 2. Strip known title suffixes like " — Firefox Developer Edition", " — Zen Browser", " - nvim", etc.
  for (var suffix in _titleSuffixMap) {
    if (title.endsWith(suffix)) {
      title = title.slice(0, title.length - suffix.length).trim()
      if (_titleSuffixMap[suffix]) appName = _titleSuffixMap[suffix]
      break
    }
  }

  // 3. Try splitting title by " - " or " — " or " | "
  var parts = title.split(/\s+[\-\u2014|]\s+/)

  if (parts.length > 1) {
    var detectedApp = ""
    var appIdx = -1

    // Check if any part matches appName or a known app in _knownApps list
    for (var i = 0; i < parts.length; i++) {
      var p = parts[i].trim()
      var pLower = p.toLowerCase()

      if (appName && pLower === appName.toLowerCase()) {
        detectedApp = appName
        appIdx = i
        break
      }

      for (var k = 0; k < _knownApps.length; k++) {
        if (pLower === _knownApps[k].toLowerCase()) {
          detectedApp = _knownApps[k]
          appIdx = i
          break
        }
      }
      if (appIdx !== -1) break
    }

    if (appIdx !== -1) {
      appName = detectedApp
      parts.splice(appIdx, 1)
      var remainingTitle = parts.join(" - ").trim()
      if (remainingTitle) {
        return appName + ": " + remainingTitle
      }
      return appName
    }

    // If no known app matched, but appName is known from appId, format with full title
    if (appName) {
      return appName + ": " + title
    }

    // Fallback: If title has multiple parts and last part looks like an App Name
    var lastPart = parts[parts.length - 1].trim()
    if (lastPart && lastPart.length < 25 && /^[A-Z][a-zA-Z0-9\s]*$/.test(lastPart)) {
      appName = lastPart
      parts.pop()
      var remTitle = parts.join(" - ").trim()
      if (remTitle) {
        return appName + ": " + remTitle
      }
      return appName
    }
  }

  // 4. Single title string without " - " separators
  if (appName && title) {
    if (title.toLowerCase() === appName.toLowerCase()) {
      return appName
    }
    return appName + ": " + title
  }

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

function goToSource(source) {
  if (!source) return []

  // 1. If source is an MPRIS player or media object with raise() method, invoke it
  try {
    if (typeof source.raise === "function") {
      source.raise()
    }
  } catch (e) {}

  // 2. If source is a notification with actions, invoke the default action (without returning early)
  var notif = source.notification || (source.actions ? source : null)
  if (notif && notif.actions) {
    for (var a = 0; a < notif.actions.length; a++) {
      if (notif.actions[a].identifier === "default") {
        try {
          notif.actions[a].invoke()
        } catch (e) {}
        break
      }
    }
  }

  // 3. Extract target patterns for window matching
  var targets = []

  function addTarget(str) {
    if (!str) return
    var s = String(str).trim()
    if (!s) return

    // Strip surrounding quotes
    if (s.charAt(0) === '"' && s.charAt(s.length - 1) === '"') {
      s = s.slice(1, -1).trim()
      if (!s) return
    }

    // If path, extract basename
    if (s.indexOf("/") !== -1) {
      s = s.substring(s.lastIndexOf("/") + 1)
    }

    // Strip image file extensions
    s = s.replace(/\.(png|svg|xpm|ico|jpg|jpeg|webp)$/i, "")
    if (!s) return

    // Strip MPRIS DBus prefix and instance suffix
    var sMprisClean = s.replace(/^org\.mpris\.MediaPlayer2\./i, "").replace(/\.instance[_\d].*$/i, "")
    if (sMprisClean !== s) {
      addTarget(sMprisClean)
    }

    // Strip .desktop extension
    var sNoDesktop = s.replace(/\.desktop$/i, "")
    if (sNoDesktop !== s) {
      addTarget(sNoDesktop)
    }

    if (targets.indexOf(s) === -1) targets.push(s)
    if (targets.indexOf(s.toLowerCase()) === -1) targets.push(s.toLowerCase())

    // If reverse domain identifier (e.g. org.mozilla.firefox, com.spotify.Client)
    if (sNoDesktop.indexOf(".") !== -1) {
      var parts = sNoDesktop.split(".")
      var lastPart = parts[parts.length - 1]
      if (lastPart) {
        var genericNames = ["client", "desktop", "app", "application", "ui", "bin"]
        if (genericNames.indexOf(lastPart.toLowerCase()) !== -1 && parts.length > 1) {
          var prevPart = parts[parts.length - 2]
          if (prevPart && targets.indexOf(prevPart.toLowerCase()) === -1) {
            targets.push(prevPart.toLowerCase())
          }
        }
        if (targets.indexOf(lastPart.toLowerCase()) === -1) {
          targets.push(lastPart.toLowerCase())
        }
      }
    }

    // Add prettified / overridden app name if known
    var pretty = prettifyAppName(sNoDesktop)
    if (pretty && pretty !== sNoDesktop) {
      if (targets.indexOf(pretty) === -1) targets.push(pretty)
      if (targets.indexOf(pretty.toLowerCase()) === -1) targets.push(pretty.toLowerCase())
    }
  }

  if (typeof source === "string") {
    addTarget(source)
  } else {
    // Add track title and combinations first for media (highest match priority)
    if (source.trackTitle) {
      var rawT = String(source.trackTitle).trim()
      var cleanT = cleanTrackTitle(rawT)
      addTarget(rawT)
      if (cleanT && cleanT !== rawT) addTarget(cleanT)
      if (source.trackArtist) {
        var artist = String(source.trackArtist).trim()
        if (artist && artist.toLowerCase() !== "unknown artist") {
          addTarget(artist + " - " + cleanT)
          addTarget(cleanT + " - " + artist)
          addTarget(artist)
        }
      }
    }

    addTarget(source.desktopEntry)
    addTarget(source.appName || source.name)
    addTarget(source.identity)
    addTarget(source.appIcon)
    if (source.dbusName) addTarget(source.dbusName)

    if (notif) {
      if (notif.desktopEntry) addTarget(notif.desktopEntry)
      if (notif.appName) addTarget(notif.appName)
      if (notif.appIcon) addTarget(notif.appIcon)
    }
  }

  return targets
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

  // 1. Actively playing with track title or artist
  var playingWithMeta = findFirst(players, function(p) {
    try {
      return p && p.isPlaying && (p.trackTitle || p.trackArtist)
    } catch (e) {
      return false
    }
  })
  if (playingWithMeta) return playingWithMeta

  // 2. Any actively playing player
  var playing = findFirst(players, function(p) {
    try {
      return p && p.isPlaying
    } catch (e) {
      return false
    }
  })
  if (playing) return playing

  // 3. Paused player with track title or artist (e.g. Spotify, mpv)
  var pausedWithMeta = findFirst(players, function(p) {
    if (!p) return false
    try {
      if (!p.trackTitle && !p.trackArtist) return false
      if (pausedEnum !== undefined) return p.playbackState === pausedEnum
      return p.playbackState === 1 || String(p.playbackState).toLowerCase().indexOf("paused") !== -1
    } catch (e) {
      return false
    }
  })
  if (pausedWithMeta) return pausedWithMeta

  // 4. Any paused player
  return findFirst(players, function(p) {
    if (!p) return false
    try {
      if (pausedEnum !== undefined) return p.playbackState === pausedEnum
      return p.playbackState === 1 || String(p.playbackState).toLowerCase().indexOf("paused") !== -1
    } catch (e) {
      return false
    }
  })
}

function findBatteryDevice(upowerDevices, displayDevice) {
  // UPower.devices is an UntypedObjectModel; read its `values` list. It does
  // not expose the QML ListModel `.count`/`.get` API.
  var list = (upowerDevices && upowerDevices.values) ? upowerDevices.values : []
  for (var i = 0; i < list.length; i++) {
    var d = list[i]
    if (d && d.isLaptopBattery && d.ready) return d
  }
  return (displayDevice && displayDevice.ready) ? displayDevice : null
}

function screenByName(arg1, arg2) {
  var name = typeof arg1 === "string" ? arg1 : (typeof arg2 === "string" ? arg2 : null)
  var screens = (arg1 && typeof arg1 !== "string") ? arg1 : ((arg2 && typeof arg2 !== "string") ? arg2 : null)
  if (screens && screens.screens) screens = screens.screens
  if (!screens && typeof Quickshell !== "undefined") {
    screens = Quickshell.screens
  }
  if (!name || !screens) return null
  var len = screens.length !== undefined ? screens.length : (screens.count !== undefined ? screens.count : 0)
  for (var i = 0; i < len; i++) {
    var s = screens[i] || (screens.get ? screens.get(i) : null)
    if (s && s.name === name) return s
  }
  return null
}

function screenAt(x, y, screens) {
  var list = screens
  if (list && list.screens) list = list.screens
  if (!list && typeof Quickshell !== "undefined") {
    list = Quickshell.screens
  }
  if (!list) return null
  var len = list.length !== undefined ? list.length : (list.count !== undefined ? list.count : 0)
  for (var i = 0; i < len; i++) {
    var s = list[i] || (list.get ? list.get(i) : null)
    if (s && x >= s.x && x < s.x + s.width && y >= s.y && y < s.y + s.height) {
      return s
    }
  }
  return null
}

function resolveActiveScreen(targetScreen, lastActiveScreen, screens) {
  var target = targetScreen || (typeof Config !== "undefined" ? Config.targetScreen : null)
  if (target) return target
  var last = lastActiveScreen || (typeof Config !== "undefined" ? Config.lastActiveScreen : null)
  if (last) return last
  var list = screens
  if (list && list.screens) list = list.screens
  if (!list && typeof Quickshell !== "undefined") {
    list = Quickshell.screens
  }
  if (list) {
    var len = list.length !== undefined ? list.length : (list.count !== undefined ? list.count : 0)
    if (len > 0) return list[0] || (list.get ? list.get(0) : null)
  }
  return null
}

function getOrdinalDate(date) {
  if (!date) return ""
  var day = date.getDate()
  var suffix = "th"
  if (day < 11 || day > 13) {
    switch (day % 10) {
      case 1: suffix = "st"; break
      case 2: suffix = "nd"; break
      case 3: suffix = "rd"; break
    }
  }
  return day + suffix + " " + Qt.formatDate(date, "of MMMM yyyy")
}


