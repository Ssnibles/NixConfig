pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import "Utils.js" as Utils

// Centralised notification service.
// Owns the freedesktop NotificationServer, MPRIS "Now Playing" track-change
// toasts, icon/avatar/glyph resolution, temporary /tmp image persistence,
// auto-dismiss timers, hover pausing, and window activation.
Singleton {
  id: service

  property bool dnd: false
  readonly property int maxVisible: Config.notifMaxVisible
  readonly property int timeoutMs: Config.notifTimeoutMs
  readonly property int maxHistory: Config.notifMaxHistory

  ListModel { id: activeModel; dynamicRoles: true }
  ListModel { id: historyModel; dynamicRoles: true }

  property alias activeModel: activeModel
  property alias historyModel: historyModel

  property int _nextUid: 1
  property var _hoverCounts: ({})
  property var _notificationsByUid: ({})
  property var _retainedNotifications: []
  property string _lastMediaTrack: ""
  property string cacheDir: ""
  property bool _startupFinished: false

  // Retain live C++ Notification objects while they remain in active or history
  // models so in-memory `image://qsimage/...` avatars and D-Bus actions stay
  // valid even after a popup toast expires or while Command Centre is closed.
  Instantiator {
    model: service._retainedNotifications
    delegate: RetainableLock {
      required property var modelData
      object: modelData
      locked: Boolean(modelData)
    }
  }

  Component.onCompleted: {
    var home = Quickshell.env("HOME") || ("/home/" + (Quickshell.env("USER") || "user"))
    var xdgCache = Quickshell.env("XDG_CACHE_HOME")
    service.cacheDir = (xdgCache || (home + "/.cache")) + "/quickshell/notif-images"
    Quickshell.execDetached(["mkdir", "-p", service.cacheDir])
    Quickshell.execDetached(["sh", "-c", 'find "$1" -type f -mtime +7 -delete', "sh", service.cacheDir])
  }

  // Copies ephemeral `/tmp/` notification images (e.g. Chromium / Vesktop user
  // avatars) into `cacheDir` before the sender unlinks them.
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
        if (code === 0) service._setItemProperty(proc.uid, "primaryIcon", "file://" + proc.dst)
        proc.destroy()
      }
    }
  }

  // --- Icon, Avatar & Glyph Resolution ---

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

    // 3. Reverse-DNS segments (e.g. com.spotify.Client -> spotify) or hyphenated name
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

  function _resolveFallbackIcon(appIcon, desktopEntry, appName) {
    var list = [_isExplicitImage(appIcon) ? "" : appIcon, desktopEntry, appName, Config.notifDefaultFallbackLogo]
    for (var i = 0; i < list.length; i++) {
      var res = _resolveIconName(list[i])
      if (res) return res
    }
    return ""
  }

  function _extractRawImage(notification) {
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

  function _resolvePrimaryImage(uid, rawUrl) {
    var clean = Utils.cleanUrl(rawUrl || "")
    if (!clean) return ""

    if (clean.startsWith("/tmp/") || clean.startsWith("file:///tmp/")) {
      var localPath = clean.replace(/^file:\/\//, "")
      if (service.cacheDir !== "") {
        var lower = localPath.toLowerCase()
        var ext = (lower.indexOf(".jpg") !== -1 || lower.indexOf(".jpeg") !== -1) ? ".jpg"
          : (lower.indexOf(".webp") !== -1 ? ".webp" : (lower.indexOf(".svg") !== -1 ? ".svg" : ".png"))
        var dst = service.cacheDir + "/notif-" + uid + ext
        tmpCopyWorker.createObject(service, { uid: uid, src: localPath, dst: dst })
      }
      return ""
    }

    return _resolveIconName(clean)
  }

  function _resolveGlyph(appName, desktopEntry, appIcon, summary, urgency, isMedia) {
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

  // --- Notification Lifecycle & Model Helpers ---

  function _trackNotification(uid, notification) {
    if (!notification) return
    notification.tracked = true
    service._notificationsByUid[uid] = notification
    if (service._retainedNotifications.indexOf(notification) === -1) {
      service._retainedNotifications = service._retainedNotifications.concat([notification])
    }
    if (notification.closed) {
      notification.closed.connect(function() {
        service._removeFromModel(activeModel, function(it) {
          return service._notificationsByUid[it.uid] === notification
        })
      })
    }
  }

  function _gcNotifications() {
    var retainUids = {}
    for (var a = 0; a < activeModel.count; a++) {
      var act = activeModel.get(a)
      if (act) retainUids[act.uid] = true
    }
    for (var h = 0; h < historyModel.count; h++) {
      var hist = historyModel.get(h)
      if (hist && (hist.hasActions || String(hist.primaryIcon || "").startsWith("image://qsimage/"))) {
        retainUids[hist.uid] = true
      }
    }

    var keepObjects = []
    var nextMap = {}
    for (var uidKey in service._notificationsByUid) {
      var n = service._notificationsByUid[uidKey]
      if (retainUids[uidKey] && n) {
        nextMap[uidKey] = n
        if (keepObjects.indexOf(n) === -1) keepObjects.push(n)
      } else if (n) {
        try { if (n.tracked) n.tracked = false } catch (e) {}
      }
    }
    service._notificationsByUid = nextMap
    service._retainedNotifications = keepObjects
  }

  function _setItemProperty(uid, prop, value) {
    var models = [activeModel, historyModel]
    for (var m = 0; m < models.length; m++) {
      for (var i = 0; i < models[m].count; i++) {
        if (models[m].get(i).uid === uid) models[m].setProperty(i, prop, value)
      }
    }
  }

  function _removeFromModel(model, predicate) {
    for (var i = model.count - 1; i >= 0; i--) {
      var item = model.get(i)
      if (item && predicate(item)) {
        if (model === activeModel) delete service._hoverCounts[item.uid]
        model.remove(i)
      }
    }
    service.scheduleDismiss()
    _gcNotifications()
  }

  function _pushToModels(item, showToast) {
    historyModel.insert(0, item)
    while (historyModel.count > service.maxHistory) {
      historyModel.remove(historyModel.count - 1)
    }
    if (showToast && !service.dnd) {
      while (activeModel.count >= service.maxVisible) {
        delete service._hoverCounts[activeModel.get(0).uid]
        activeModel.remove(0)
      }
      activeModel.append(item)
      service.scheduleDismiss()
    }
    _gcNotifications()
  }

  function _buildItem(opts) {
    var uid = opts.uid || service._nextUid++
    var isMedia = Boolean(opts.isMedia)
    var urgency = isMedia ? 0 : (opts.urgency !== undefined ? opts.urgency : 1)
    var appName = opts.appName || ""
    var desktopEntry = opts.desktopEntry || ""
    var appIcon = Utils.cleanUrl(opts.appIcon || "")
    var summary = opts.summary || ""
    var notif = opts.notification || null

    if (notif) _trackNotification(uid, notif)

    var hasActions = false
    if (notif && notif.actions) {
      for (var i = 0; i < notif.actions.length; i++) {
        if (notif.actions[i].identifier !== "default") { hasActions = true; break }
      }
    }

    return {
      uid: uid,
      title: isMedia ? "Now Playing" : (summary || Utils.prettifyAppName(appName || desktopEntry) || "Notification"),
      body: isMedia ? (opts.trackTitle || "") : (opts.body || ""),
      subtext: isMedia ? (opts.trackArtist || "") : "",
      timeStr: ClockService.timeStr,
      urgency: urgency,
      isMedia: isMedia,
      primaryIcon: _resolvePrimaryImage(uid, opts.rawImage || ""),
      fallbackIcon: _resolveFallbackIcon(appIcon, desktopEntry, appName),
      glyph: _resolveGlyph(appName, desktopEntry, appIcon, summary, urgency, isMedia),
      hasActions: hasActions,
      expireTimeout: (notif && notif.expireTimeout > 0) ? notif.expireTimeout : -1,
      appName: appName,
      desktopEntry: desktopEntry,
      appIcon: appIcon,
      trackTitle: opts.trackTitle || "",
      trackArtist: opts.trackArtist || "",
      createdAt: Date.now()
    }
  }

  // --- MPRIS "Now Playing" Toasts ---

  Timer {
    interval: 1500
    running: true
    onTriggered: {
      if (MediaService.trackTitle) service._lastMediaTrack = MediaService.trackTitle.toLowerCase().trim()
      service._startupFinished = true
    }
  }

  Timer {
    id: mediaDebounceTimer
    interval: 200
    onTriggered: {
      if (!MediaService.player || !MediaService.isPlaying) return
      var p = MediaService.player
      service._postMedia({
        trackTitle: MediaService.trackTitle,
        trackArtist: MediaService.trackArtist || "Unknown Artist",
        rawImage: MediaService.trackArtUrl,
        appName: p.name || p.identity || "",
        desktopEntry: p.desktopEntry || "",
        appIcon: p.desktopEntry || p.name || "",
        notification: null
      })
    }
  }

  Connections {
    target: MediaService
    function onTrackTitleChanged() { if (service._startupFinished) mediaDebounceTimer.restart() }
    function onTrackArtistChanged() { if (service._startupFinished) mediaDebounceTimer.restart() }
    function onTrackArtUrlChanged() { if (service._startupFinished) mediaDebounceTimer.restart() }
    function onIsPlayingChanged() { if (service._startupFinished) mediaDebounceTimer.restart() }
  }

  function _isPlaceholderMedia(title, artist) {
    if (!title) return true
    var unknownArtist = (!artist || artist === "Unknown Artist" || artist.toLowerCase() === "unknown")
    if (!unknownArtist) return false
    var placeholders = ["youtube", "soundcloud", "spotify", "netflix", "twitch", "instagram", "facebook", "twitter", "x", "unknown"]
    return placeholders.indexOf(title.toLowerCase().trim()) !== -1
  }

  function _postMedia(opts) {
    var cleanT = opts.trackTitle || ""
    var cleanA = opts.trackArtist || "Unknown Artist"
    if (_isPlaceholderMedia(cleanT, cleanA)) return

    var trackKey = cleanT.toLowerCase().trim()
    var isSameTrack = (trackKey === service._lastMediaTrack)
    service._lastMediaTrack = trackKey

    var activeIdx = -1
    for (var a = 0; a < activeModel.count; a++) {
      if (activeModel.get(a).isMedia) { activeIdx = a; break }
    }

    var resolvedUid = activeIdx !== -1 ? activeModel.get(activeIdx).uid : undefined
    if (resolvedUid === undefined && historyModel.count > 0) {
      var topCandidate = historyModel.get(0)
      var topCandidateSame = topCandidate && topCandidate.isMedia && (topCandidate.trackTitle || "").toLowerCase().trim() === trackKey
      var topCandidatePlaceholder = topCandidate && topCandidate.isMedia && (Date.now() - (topCandidate.createdAt || 0) < 20000) && topCandidate.subtext === "Unknown Artist"
      if (topCandidateSame || topCandidatePlaceholder) {
        resolvedUid = topCandidate.uid
      }
    }

    var item = _buildItem({
      uid: resolvedUid,
      isMedia: true,
      trackTitle: cleanT,
      trackArtist: cleanA,
      rawImage: opts.rawImage,
      appName: opts.appName,
      desktopEntry: opts.desktopEntry,
      appIcon: opts.appIcon,
      notification: opts.notification
    })

    if (activeIdx !== -1) {
      activeModel.set(activeIdx, item)
      if (!isSameTrack) service.scheduleDismiss()
    } else if (!isSameTrack && !service.dnd && Config.notifShowMediaToasts !== false) {
      while (activeModel.count >= service.maxVisible) {
        delete service._hoverCounts[activeModel.get(0).uid]
        activeModel.remove(0)
      }
      activeModel.append(item)
      service.scheduleDismiss()
    }

    if (historyModel.count > 0) {
      var top = historyModel.get(0)
      var topSame = top && top.isMedia && (top.trackTitle || "").toLowerCase().trim() === trackKey
      var topPlaceholder = top && top.isMedia && (Date.now() - (top.createdAt || 0) < 20000) && top.subtext === "Unknown Artist"
      if (topSame || topPlaceholder) {
        if (opts.notification) _trackNotification(item.uid, opts.notification)
        historyModel.set(0, item)
        _gcNotifications()
        return
      }
    }

    if (!isSameTrack || historyModel.count === 0) {
      historyModel.insert(0, item)
      while (historyModel.count > service.maxHistory) {
        historyModel.remove(historyModel.count - 1)
      }
      _gcNotifications()
    }
  }

  // --- Freedesktop Notification Daemon ---

  function _isMediaDesktopNotification(notification, rawImg) {
    var appLower = ((notification.appName || "") + " " + (notification.desktopEntry || "")).toLowerCase()
    var isSpotify = appLower.indexOf("spotify") !== -1
    var isMediaApp = isSpotify
    var mediaList = Config.notifMediaApps || []
    for (var i = 0; i < mediaList.length && !isMediaApp; i++) {
      if (appLower.indexOf(String(mediaList[i]).toLowerCase()) !== -1) isMediaApp = true
    }
    if (!isMediaApp) return false

    var curTitle = MediaService.trackTitle ? MediaService.trackTitle.toLowerCase().trim() : ""
    var textLower = ((notification.summary || "") + " " + (notification.body || "")).toLowerCase()
    return (curTitle !== "" && textLower.indexOf(curTitle) !== -1) || (isSpotify && rawImg !== "")
  }

  NotificationServer {
    id: notificationServer
    bodySupported: true
    bodyMarkupSupported: true
    bodyHyperlinksSupported: true
    bodyImagesSupported: true
    imageSupported: true
    actionsSupported: true
    actionIconsSupported: true
    persistenceSupported: true
    inlineReplySupported: true
    keepOnReload: true

    onNotification: function(notification) {
      var rawImg = service._extractRawImage(notification)

      if (service._isMediaDesktopNotification(notification, rawImg)) {
        var mediaImg = (MediaService.trackArtUrl && String(rawImg).startsWith("image://qsimage/"))
          ? MediaService.trackArtUrl
          : (rawImg || MediaService.trackArtUrl)
        service._postMedia({
          trackTitle: Utils.cleanTrackTitle(notification.summary || MediaService.trackTitle || ""),
          trackArtist: notification.body || MediaService.trackArtist || "Unknown Artist",
          rawImage: mediaImg,
          appName: notification.appName || "",
          desktopEntry: notification.desktopEntry || "",
          appIcon: notification.appIcon || "",
          notification: String(mediaImg).startsWith("image://qsimage/") ? notification : null
        })
        return
      }

      var item = service._buildItem({
        isMedia: false,
        summary: notification.summary || "",
        body: notification.body || "",
        rawImage: rawImg,
        urgency: notification.urgency !== undefined ? notification.urgency : 1,
        appName: notification.appName || "",
        desktopEntry: notification.desktopEntry || "",
        appIcon: notification.appIcon || "",
        notification: notification
      })
      service._pushToModels(item, true)
    }
  }

  // --- Hover, Expiry & Dismissal ---

  function setHovered(uid, hovered) {
    if (uid === undefined || uid === null || uid < 0) return
    var n = (service._hoverCounts[uid] || 0) + (hovered ? 1 : -1)
    if (n > 0) service._hoverCounts[uid] = n
    else delete service._hoverCounts[uid]
    service.scheduleDismiss()
  }

  function _itemTimeoutMs(item) {
    if (!item) return service.timeoutMs
    if (item.expireTimeout > 0) return item.expireTimeout
    if (item.urgency === 0 && Config.notifTimeoutLowMs > 0) return Config.notifTimeoutLowMs
    if (item.urgency === 2) return Config.notifTimeoutCriticalMs
    return service.timeoutMs
  }

  function scheduleDismiss() {
    dismissTimer.stop()
    if (activeModel.count === 0) return

    var now = Date.now()
    var soonest = -1
    for (var i = 0; i < activeModel.count; i++) {
      var item = activeModel.get(i)
      if (!item || !item.createdAt || (service._hoverCounts[item.uid] || 0) > 0) continue
      var itemTimeout = _itemTimeoutMs(item)
      if (itemTimeout <= 0) continue
      var remaining = Math.max(0, item.createdAt + itemTimeout - now)
      if (soonest < 0 || remaining < soonest) soonest = remaining
    }
    if (soonest >= 0) {
      dismissTimer.interval = Math.max(1, soonest)
      dismissTimer.restart()
    }
  }

  Timer {
    id: dismissTimer
    repeat: false
    onTriggered: {
      var now = Date.now()
      service._removeFromModel(activeModel, function(item) {
        if (!item.createdAt || (service._hoverCounts[item.uid] || 0) > 0) return false
        var t = service._itemTimeoutMs(item)
        return t > 0 && (now - item.createdAt >= t)
      })
    }
  }

  function dismiss(uid, fromHistory) {
    _removeFromModel(activeModel, function(it) { return it.uid === uid })
    if (fromHistory) {
      _removeFromModel(historyModel, function(it) { return it.uid === uid })
    }
  }

  function clearHistory() {
    service._hoverCounts = ({})
    activeModel.clear()
    historyModel.clear()
    service.scheduleDismiss()
    _gcNotifications()
  }

  function toggleDnd() {
    service.dnd = !service.dnd
  }

  // --- Actions & Window Focus ---

  function actionsFor(uid) {
    var notif = service._notificationsByUid[uid]
    if (!notif || !notif.actions) return []
    var out = []
    for (var i = 0; i < notif.actions.length; i++) {
      if (notif.actions[i] && notif.actions[i].identifier !== "default") out.push(notif.actions[i])
    }
    return out
  }

  function invokeAction(uid, action, fromHistory) {
    if (action && typeof action.invoke === "function") {
      try { action.invoke() } catch (e) {}
    }
    var notif = service._notificationsByUid[uid]
    if (Config.notifDismissOnAction && (!notif || !notif.resident)) {
      dismiss(uid, fromHistory)
    }
  }

  function activate(uid, fromHistory) {
    var item = null
    for (var a = 0; a < activeModel.count && !item; a++) {
      if (activeModel.get(a).uid === uid) item = activeModel.get(a)
    }
    for (var h = 0; h < historyModel.count && !item; h++) {
      if (historyModel.get(h).uid === uid) item = historyModel.get(h)
    }
    if (item) {
      WindowFocuser.focusSource({
        notification: service._notificationsByUid[uid] || null,
        appName: item.appName,
        desktopEntry: item.desktopEntry,
        appIcon: item.appIcon,
        trackTitle: item.trackTitle,
        trackArtist: item.trackArtist
      })
    }
    if (!fromHistory) dismiss(uid, false)
  }
}
