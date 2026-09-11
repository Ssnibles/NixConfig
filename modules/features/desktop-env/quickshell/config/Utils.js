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

function stripMarkup(text) {
  if (!text) return ""
  return String(text).replace(/<[^>]*>/g, "")
}

var _appNameOverrides = {
  "antigravity": "Antigravity",
  "antigravity-editor": "Antigravity",
  "zen": "Zen",
  "zen-browser": "Zen",
  "zen-alpha": "Zen",
  "zen-beta": "Zen",
  "zen-twilight": "Zen",
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
  "ghostty": "Ghostty",
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

function wifiIcon(signalStrength, connected) {
  if (!connected) return "\u{F092F}"
  if (signalStrength < 0.2) return "\u{F091F}"
  if (signalStrength < 0.4) return "\u{F0922}"
  if (signalStrength < 0.6) return "\u{F0925}"
  return "\u{F0928}"
}

function focusWindow(patterns, quickshellObj, toplevelManagerObj) {
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

  // 1. Try native Wayland ToplevelManager first (if available in scope or passed in)
  var manager = toplevelManagerObj || null
  if (!manager && typeof ToplevelManager !== "undefined") {
    manager = ToplevelManager
  } else if (!manager && quickshellObj && typeof quickshellObj.ToplevelManager !== "undefined") {
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

  // 2. Compositor IPC focus action (MangoWC, Niri, Hyprland, etc.)
  var qs = quickshellObj
  if (!qs && typeof Quickshell !== "undefined") qs = Quickshell
  if (qs && typeof qs.execDetached === "function") {
    var nodeScript = [
      'const cp = require("child_process");',
      'const pats = process.argv.slice(2).map(p => p.toLowerCase());',
      'if (!pats.length) process.exit(0);',
      'function sh(cmd) {',
      '  try { return cp.execSync(cmd, { encoding: "utf-8", stdio: ["ignore", "pipe", "ignore"] }); }',
      '  catch (e) { return ""; }',
      '}',
      'function matchScore(appId, title) {',
      '  appId = (appId || "").toLowerCase();',
      '  title = (title || "").toLowerCase();',
      '  for (let i = 0; i < pats.length; i++) {',
      '    const p = pats[i];',
      '    if (appId === p) return 100 - i;',
      '    if (appId.includes(p)) return 80 - i;',
      '    if (title === p) return 90 - i;',
      '    if (title.includes(p)) return 70 - i;',
      '  }',
      '  return 0;',
      '}',
      'const d = (process.env.XDG_CURRENT_DESKTOP || "").toLowerCase();',
      'const b = (process.env.QS_BAR || "").toLowerCase();',
      '// 1. MangoWC',
      'if (process.env.MANGO_INSTANCE_SIGNATURE || b === "mangowc" || d.includes("mango")) {',
      '  const raw = sh("mmsg get all-clients");',
      '  if (raw) {',
      '    try {',
      '      const clients = JSON.parse(raw).clients || [];',
      '      let best = null, bestScore = 0;',
      '      for (const c of clients) {',
      '        const score = matchScore(c.appid, c.title);',
      '        if (score > bestScore) { bestScore = score; best = c; }',
      '      }',
      '      if (best) { sh(`mmsg dispatch focusid client,${best.id}`); process.exit(0); }',
      '    } catch (e) {}',
      '  }',
      '}',
      '// 2. Niri',
      'if (process.env.NIRI_SOCKET || b === "niri" || d.includes("niri")) {',
      '  const raw = sh("niri msg --json windows");',
      '  if (raw) {',
      '    try {',
      '      const wins = JSON.parse(raw);',
      '      let best = null, bestScore = 0;',
      '      for (const w of wins) {',
      '        const score = matchScore(w.app_id, w.title);',
      '        if (score > bestScore) { bestScore = score; best = w; }',
      '      }',
      '      if (best) { sh(`niri msg action focus-window --id ${best.id}`); process.exit(0); }',
      '    } catch (e) {}',
      '  }',
      '}',
      '// 3. Hyprland',
      'if (process.env.HYPRLAND_INSTANCE_SIGNATURE || b === "hyprland" || d.includes("hyprland")) {',
      '  const raw = sh("hyprctl clients -j");',
      '  if (raw) {',
      '    try {',
      '      const clients = JSON.parse(raw);',
      '      let best = null, bestScore = 0;',
      '      for (const c of clients) {',
      '        const score = Math.max(matchScore(c.class, c.title), matchScore(c.initialClass, c.initialTitle));',
      '        if (score > bestScore) { bestScore = score; best = c; }',
      '      }',
      '      if (best && best.address) { sh(`hyprctl dispatch focuswindow address:${best.address}`); process.exit(0); }',
      '    } catch (e) {}',
      '  }',
      '}',
      '// Fallback: check available tools',
      'try {',
      '  const mRaw = sh("mmsg get all-clients");',
      '  if (mRaw) {',
      '    const clients = JSON.parse(mRaw).clients || [];',
      '    let best = null, bestScore = 0;',
      '    for (const c of clients) {',
      '      const score = matchScore(c.appid, c.title);',
      '      if (score > bestScore) { bestScore = score; best = c; }',
      '    }',
      '    if (best) { sh(`mmsg dispatch focusid client,${best.id}`); process.exit(0); }',
      '  }',
      '} catch (e) {}',
      'try {',
      '  const nRaw = sh("niri msg --json windows");',
      '  if (nRaw) {',
      '    const wins = JSON.parse(nRaw);',
      '    let best = null, bestScore = 0;',
      '    for (const w of wins) {',
      '      const score = matchScore(w.app_id, w.title);',
      '      if (score > bestScore) { bestScore = score; best = w; }',
      '    }',
      '    if (best) { sh(`niri msg action focus-window --id ${best.id}`); process.exit(0); }',
      '  }',
      '} catch (e) {}',
      'try {',
      '  const hRaw = sh("hyprctl clients -j");',
      '  if (hRaw) {',
      '    const clients = JSON.parse(hRaw);',
      '    let best = null, bestScore = 0;',
      '    for (const c of clients) {',
      '      const score = Math.max(matchScore(c.class, c.title), matchScore(c.initialClass, c.initialTitle));',
      '      if (score > bestScore) { bestScore = score; best = c; }',
      '    }',
      '    if (best && best.address) { sh(`hyprctl dispatch focuswindow address:${best.address}`); process.exit(0); }',
      '  }',
      '} catch (e) {}'
    ].join('\n')

    qs.execDetached(["node", "-e", nodeScript, "node"].concat(cleanTargets))
    return true
  }

  return false
}

function goToSource(source, quickshellObj, toplevelManagerObj) {
  if (!source) return
  var qs = quickshellObj
  if (!qs && typeof Quickshell !== "undefined") qs = Quickshell

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

  if (targets.length === 0) return

  focusWindow(targets, qs, toplevelManagerObj)
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
