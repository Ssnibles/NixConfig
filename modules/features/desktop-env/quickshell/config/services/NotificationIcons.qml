pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import "../Utils.js" as Utils
import ".."

// Resolves notification icons, avatars, and fallback glyphs. Owns the on-disk
// cache used to keep ephemeral /tmp images alive after the sender unlinks them.
Singleton {
  id: root

  property string cacheDir: ""

  // Emitted when a temporary /tmp image has been copied into the cache.
  signal imageCopied(int uid, string url)

  Component.onCompleted: {
    var home = Quickshell.env("HOME") || ("/home/" + (Quickshell.env("USER") || "user"))
    var xdgCache = Quickshell.env("XDG_CACHE_HOME")
    root.cacheDir = (xdgCache || (home + "/.cache")) + "/quickshell/notif-images"
    Quickshell.execDetached(["mkdir", "-p", root.cacheDir])
    Quickshell.execDetached(["sh", "-c", 'find "$1" -type f -mtime +7 -delete', "sh", root.cacheDir])
  }

  Component {
    id: tmpCopyWorker
    Process {
      id: proc
      property int uid: 0
      property string src: ""
      property string dst: ""
      command: ["cp", "-f", src, dst]
      Component.onCompleted: running = true
      onExited: function(code) {
        if (code === 0) root.imageCopied(proc.uid, "file://" + proc.dst)
        proc.destroy()
      }
    }
  }

  function _iconUrl(name) {
    if (!name) return ""
    if (name.startsWith("/")) return "file://" + name
    if (name.startsWith("file://") || name.startsWith("image://") || name.startsWith("http://") || name.startsWith("https://")) return name
    var p = Quickshell.iconPath(name, true)
    return p ? (p.startsWith("/") ? "file://" + p : p) : ""
  }

  function _isExplicitImage(raw) {
    var s = Utils.cleanUrl(raw || "")
    return s.startsWith("/tmp/") || s.startsWith("file:///tmp/") || s.startsWith("image://qsimage/") || s.startsWith("http://") || s.startsWith("https://")
  }

  function _resolveIconName(name) {
    var s = Utils.cleanUrl(String(name || ""))
    if (!s) return ""
    if (s.startsWith("image://icon/")) s = s.substring(13).split("?")[0].trim()
    if (s.startsWith("/") || s.startsWith("file://") || s.startsWith("http://") || s.startsWith("https://") || s.startsWith("image://")) {
      return _iconUrl(s)
    }

    var clean = s.replace(/\.(desktop|png|svg|xpm|ico)$/i, "").trim()
    if (!clean) return ""
    var lower = clean.toLowerCase()

    // 1. Configured alias in Config.notifAppIcons (exact or substring match)
    var aliases = Config.notifAppIcons || {}
    var mapped = aliases[lower] || ""
    if (!mapped) {
      for (var key in aliases) {
        if (lower.indexOf(key) !== -1) { mapped = aliases[key]; break }
      }
    }
    if (mapped) {
      var mappedUrl = _iconUrl(mapped)
      if (mappedUrl) return mappedUrl
    }

    // 2. Direct theme icon or DesktopEntries lookup
    var direct = _iconUrl(clean) || _iconUrl(lower)
    if (direct) return direct

    if (typeof DesktopEntries !== "undefined" && DesktopEntries) {
      var entry = DesktopEntries.byId(clean) || DesktopEntries.heuristicLookup(clean)
      if (entry && entry.icon) {
        var entryUrl = _iconUrl(entry.icon)
        if (entryUrl) return entryUrl
      }
    }

    // 3. Reverse-DNS segments (e.g. com.spotify.Client to spotify) or hyphenated name
    if (clean.indexOf(".") !== -1) {
      var parts = clean.split(".")
      var skip = ["com", "org", "io", "net", "app", "desktop", "client", "bin", "ui"]
      for (var i = parts.length - 1; i >= 0; i--) {
        var part = parts[i].toLowerCase()
        if (part && skip.indexOf(part) === -1) {
          var sub = _resolveIconName(part)
          if (sub) return sub
        }
      }
    }

    return _iconUrl(lower.replace(/\s+/g, "-"))
  }

  function resolveFallback(appIcon, desktopEntry, appName) {
    var list = [_isExplicitImage(appIcon) ? "" : appIcon, desktopEntry, appName, Config.notifDefaultFallbackLogo]
    for (var i = 0; i < list.length; i++) {
      var res = _resolveIconName(list[i])
      if (res) return res
    }
    return ""
  }

  function extractRawImage(notification) {
    if (!notification) return ""
    var img = Utils.cleanUrl(notification.image || "")
    if (img) return img

    var h = notification.hints
    if (h) {
      var hintImg = Utils.cleanUrl(h["image-path"] || h["image_path"] || h["sender-avatar"] || h["avatar-url"] || "")
      if (hintImg) return hintImg
    }

    var appIcon = Utils.cleanUrl(notification.appIcon || "")
    return _isExplicitImage(appIcon) ? appIcon : ""
  }

  // Returns an immediately usable URL, or "" when a /tmp image is still being
  // copied; `imageCopied(uid, url)` fires once the cache copy is ready.
  function resolvePrimary(uid, rawUrl) {
    var clean = Utils.cleanUrl(rawUrl || "")
    if (!clean) return ""

    if (clean.startsWith("/tmp/") || clean.startsWith("file:///tmp/")) {
      var localPath = clean.replace(/^file:\/\//, "")
      if (root.cacheDir !== "") {
        var lower = localPath.toLowerCase()
        var ext = (lower.indexOf(".jpg") !== -1 || lower.indexOf(".jpeg") !== -1) ? ".jpg"
          : (lower.indexOf(".webp") !== -1 ? ".webp" : (lower.indexOf(".svg") !== -1 ? ".svg" : ".png"))
        var dst = root.cacheDir + "/notif-" + uid + ext
        tmpCopyWorker.createObject(root, { uid: uid, src: localPath, dst: dst })
      }
      return ""
    }

    return _resolveIconName(clean)
  }

  function resolveGlyph(appName, desktopEntry, appIcon, summary, urgency, isMedia) {
    if (isMedia) return "󰎈"
    var app = ((appName || "") + " " + (desktopEntry || "") + " " + (appIcon || "")).toLowerCase()
    var sum = (summary || "").toLowerCase()
    var glyphs = Config.notifAppGlyphs || {}
    for (var key in glyphs) {
      if (app.indexOf(key) !== -1 || sum.indexOf(key) !== -1) return glyphs[key]
    }
    if (urgency === 2) return "󰀦"
    var match = (appName || desktopEntry || summary || "").trim().match(/[a-zA-Z0-9]/)
    return match ? match[0].toUpperCase() : (Config.notifDefaultFallbackGlyph || "󰂚")
  }
}
