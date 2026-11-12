pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import "../Utils.js" as Utils
import ".."

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

  // Temporary /tmp images arrive asynchronously once copied into the cache.
  Connections {
    target: NotificationIcons
    function onImageCopied(uid, url) { service._setItemProperty(uid, "primaryIcon", url) }
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

  function _trimActive() {
    while (activeModel.count >= service.maxVisible) {
      delete service._hoverCounts[activeModel.get(0).uid]
      activeModel.remove(0)
    }
  }

  function _pushToModels(item, showToast) {
    historyModel.insert(0, item)
    while (historyModel.count > service.maxHistory) {
      historyModel.remove(historyModel.count - 1)
    }
    if (showToast && !service.dnd) {
      service._trimActive()
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
      primaryIcon: NotificationIcons.resolvePrimary(uid, opts.rawImage || ""),
      fallbackIcon: NotificationIcons.resolveFallback(appIcon, desktopEntry, appName),
      glyph: NotificationIcons.resolveGlyph(appName, desktopEntry, appIcon, summary, urgency, isMedia),
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

  function _isSameMediaItem(item, trackKey) {
    if (!item || !item.isMedia) return false
    var sameTrack = (item.trackTitle || "").toLowerCase().trim() === trackKey
    var placeholderArtist = (Date.now() - (item.createdAt || 0) < 20000) && item.subtext === "Unknown Artist"
    return sameTrack || placeholderArtist
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

    var topHistory = historyModel.count > 0 ? historyModel.get(0) : null
    var topHistorySame = service._isSameMediaItem(topHistory, trackKey)

    var resolvedUid = activeIdx !== -1 ? activeModel.get(activeIdx).uid : undefined
    if (resolvedUid === undefined && topHistorySame) {
      resolvedUid = topHistory.uid
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
      service._trimActive()
      activeModel.append(item)
      service.scheduleDismiss()
    }

    if (topHistorySame) {
      if (opts.notification) _trackNotification(item.uid, opts.notification)
      historyModel.set(0, item)
      _gcNotifications()
      return
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
      var rawImg = NotificationIcons.extractRawImage(notification)

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
