pragma Singleton

import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import "Utils.js" as Utils

Singleton {
  id: store

  property bool dnd: false
  property int maxVisible: Config.notifMaxVisible
  property int timeoutMs: Config.notifTimeoutMs
  property int maxHistory: Config.notifMaxHistory
  property int hoveredIndex: -1

  ListModel {
    id: activeModel
    dynamicRoles: true
  }

  ListModel {
    id: historyModel
    dynamicRoles: true
  }

  property alias activeModel: activeModel
  property alias historyModel: historyModel

  // --- MPRIS Track Change Listener ---
  readonly property var mediaPlayer: MediaService.player


  // --- Cover Art Cache System ---
  property int cacheVersion: 0
  property var artCache: ({})
  property var _pendingDownloads: ({})
  property var _downloadQueue: []
  property var _currentDownloadItem: null
  property var _hookedNotifications: []
  property string cacheDir: ""

  Component.onCompleted: {
    var home = Quickshell.env("HOME") || "/home/" + Quickshell.env("USER")
    var xdgCache = Quickshell.env("XDG_CACHE_HOME")
    if (xdgCache && xdgCache !== "") {
      store.cacheDir = xdgCache + "/quickshell/coverart"
    } else if (home && home !== "") {
      store.cacheDir = home + "/.cache/quickshell/coverart"
    } else {
      store.cacheDir = "/tmp/quickshell-coverart"
    }
    Quickshell.execDetached(["mkdir", "-p", store.cacheDir])
    // Prune cover art that hasn't been touched in 30 days so the cache can't
    // grow without bound.
    Quickshell.execDetached(["sh", "-c", 'find "$1" -type f -mtime +30 -delete', "sh", store.cacheDir])
  }

  Process {
    id: downloadProc
    stdout: StdioCollector {}
    onExited: function(exitCode, exitStatus) {
      if (store._currentDownloadItem) {
        var item = store._currentDownloadItem
        if (exitCode === 0) {
          var fileUrl = item.targetFileUrl
          if (item.cacheKey) store.artCache[item.cacheKey] = fileUrl
          if (item.fullKey) store.artCache[item.fullKey] = fileUrl
          if (item.titleKey) store.artCache[item.titleKey] = fileUrl
          // Callers receive the original URL immediately; rewrite any model rows
          // that still point at it once the local file is actually on disk.
          store.updateModelImages(item.fullKey, item.titleKey, fileUrl)
          if (item.cacheKey && item.cacheKey !== item.fullKey && item.cacheKey !== item.titleKey) {
            store.updateModelImages(item.cacheKey, item.cacheKey, fileUrl)
          }
          store.cacheVersion++
        }
        delete store._pendingDownloads[item.pendingKey || item.url]
        store._currentDownloadItem = null
      }
      store.processNextDownload()
    }
  }

  function enqueueDownload(job) {
    job.targetFileUrl = "file://" + job.targetPath
    job.pendingKey = job.pendingKey || job.url
    store._downloadQueue.push(job)
    processNextDownload()
  }

  function downloadCoverArt(url, targetPath, fullKey, titleKey) {
    enqueueDownload({
      url: url,
      targetPath: targetPath,
      fullKey: fullKey,
      titleKey: titleKey,
      pendingKey: url
    })
  }

  function processNextDownload() {
    if (downloadProc.running || store._downloadQueue.length === 0) return
    store._currentDownloadItem = store._downloadQueue.shift()
    var item = store._currentDownloadItem
    if (item.localSource) {
      downloadProc.exec(["sh", "-c", 'mkdir -p "$1" && cp -f "$2" "$3"', "sh", store.cacheDir, item.localSource, item.targetPath])
    } else {
      var script = 'if [ -f "$2" ]; then exit 0; fi; mkdir -p "$1" && curl -s -L -f --max-time 30 "$3" -o "$2"'
      downloadProc.exec(["sh", "-c", script, "sh", store.cacheDir, item.targetPath, item.url])
    }
  }

  // Bound the in-memory cover-art map so it can't grow without limit over a
  // long session. Object keys preserve insertion order, so drop the oldest.
  function maybeTrimArtCache() {
    var keys = Object.keys(store.artCache)
    if (keys.length <= 400) return
    for (var i = 0; i < 200; i++) {
      delete store.artCache[keys[i]]
    }
  }

  function _hashString(str) {
    if (!str) return "0"
    var hash = 0
    for (var i = 0; i < str.length; i++) {
      var c = str.charCodeAt(i)
      hash = ((hash << 5) - hash) + c
      hash |= 0
    }
    return Math.abs(hash).toString(16)
  }

  function _makeTrackKey(title, artist) {
    var cleanT = Utils.cleanTrackTitle(title || "").toLowerCase().trim()
    var cleanA = (artist || "").toLowerCase().trim()
    if (cleanA === "unknown artist") cleanA = ""
    if (cleanT && cleanA) return cleanT + " — " + cleanA
    return cleanT
  }

  function getCoverArt(title, artist, rawArtUrl) {
    var _v = store.cacheVersion

    var cleanT = Utils.cleanTrackTitle(title || "")
    var cleanA = (artist || "").trim()
    if (cleanA === "Unknown Artist") cleanA = ""
    var cleanU = Utils.cleanUrl(rawArtUrl || "")

    var fullKey = _makeTrackKey(cleanT, cleanA)
    var titleKey = cleanT ? cleanT.toLowerCase().trim() : ""

    if (fullKey && store.artCache[fullKey]) {
      return store.artCache[fullKey]
    }

    if (titleKey && store.artCache[titleKey]) {
      return store.artCache[titleKey]
    }

    if (cleanU !== "") {
      return cleanU
    }

    return ""
  }

  function cacheCoverArt(title, artist, rawArtUrl) {
    store.maybeTrimArtCache()
    var cleanT = Utils.cleanTrackTitle(title || "")
    var cleanA = (artist || "").trim()
    if (cleanA === "Unknown Artist") cleanA = ""
    var cleanU = Utils.cleanUrl(rawArtUrl || "")

    var fullKey = _makeTrackKey(cleanT, cleanA)
    var titleKey = cleanT ? cleanT.toLowerCase().trim() : ""

    if (!cleanU) return ""

    if (cleanU.startsWith("file://") || cleanU.startsWith("/")) {
      var fileUrl = cleanU.startsWith("/") ? ("file://" + cleanU) : cleanU
      if (fullKey) store.artCache[fullKey] = fileUrl
      if (titleKey) store.artCache[titleKey] = fileUrl
      return fileUrl
    }

    if (cleanU.startsWith("http://") || cleanU.startsWith("https://")) {
      var ext = ".jpg"
      var urlLower = cleanU.toLowerCase()
      if (urlLower.indexOf(".png") !== -1) ext = ".png"
      else if (urlLower.indexOf(".webp") !== -1) ext = ".webp"

      var fileHash = _hashString(cleanU)
      var targetPath = store.cacheDir + "/" + fileHash + ext
      var targetFileUrl = "file://" + targetPath

      if (store.artCache[fullKey] === targetFileUrl || store.artCache[titleKey] === targetFileUrl) {
        return targetFileUrl
      }

      if (fullKey && !store.artCache[fullKey]) store.artCache[fullKey] = cleanU
      if (titleKey && !store.artCache[titleKey]) store.artCache[titleKey] = cleanU

      if (!store._pendingDownloads[cleanU] && store.cacheDir !== "") {
        store._pendingDownloads[cleanU] = true
        downloadCoverArt(cleanU, targetPath, fullKey, titleKey)
      }

      return store.artCache[fullKey] || cleanU
    }

    if (fullKey) store.artCache[fullKey] = cleanU
    if (titleKey) store.artCache[titleKey] = cleanU
    return cleanU
  }

  function extractNotificationImage(notification) {
    if (!notification) return ""

    // 1. Quickshell built-in image property (handles image-data and image-path if decoded)
    if (notification.image) {
      var imgStr = String(notification.image).trim()
      if (imgStr.charAt(0) === '"' && imgStr.charAt(imgStr.length - 1) === '"') {
        imgStr = imgStr.slice(1, -1).trim()
      }
      if (imgStr !== "") return imgStr
    }

    // 2. Check hints dictionary for image-path or sender avatars
    var hints = notification.hints
    if (hints) {
      var p = hints["image-path"] || hints["image_path"] || hints["sender-avatar"] || hints["avatar-url"]
      if (p) {
        var str = String(p).trim()
        if (str.charAt(0) === '"' && str.charAt(str.length - 1) === '"') {
          str = str.slice(1, -1).trim()
        }
        if (str !== "") return str
      }
    }

    return ""
  }

  function cacheNotificationImage(rawUrl) {
    if (!rawUrl) return ""
    store.maybeTrimArtCache()
    var clean = Utils.cleanUrl(rawUrl)
    if (!clean) return ""

    // 1. Local file paths
    if (clean.startsWith("file://") || clean.startsWith("/")) {
      var localPath = clean.replace(/^file:\/\//, "")
      // If image is inside /tmp/, copy it to cacheDir immediately so it persists
      // even after Electron/Chromium/Discord unlinks the temporary file
      if (localPath.startsWith("/tmp/") && store.cacheDir !== "") {
        var ext = ".png"
        var lLower = localPath.toLowerCase()
        if (lLower.indexOf(".jpg") !== -1 || lLower.indexOf(".jpeg") !== -1) ext = ".jpg"
        else if (lLower.indexOf(".webp") !== -1) ext = ".webp"
        else if (lLower.indexOf(".svg") !== -1) ext = ".svg"
        var hash = _hashString(localPath)
        var target = store.cacheDir + "/" + hash + ext
        var originalUrl = "file://" + localPath
        if (!store._pendingDownloads[localPath]) {
          store._pendingDownloads[localPath] = true
          enqueueDownload({
            localSource: localPath,
            targetPath: target,
            cacheKey: originalUrl,
            fullKey: originalUrl,
            titleKey: "",
            pendingKey: localPath
          })
        }
        // Return the still-valid original straight away so the image can render;
        // the queued copy rewrites it to the persistent cache once complete.
        return originalUrl
      }
      return clean.startsWith("/") ? ("file://" + clean) : clean
    }

    // 2. HTTP / HTTPS remote URLs (e.g. Discord CDN avatars)
    if (clean.startsWith("http://") || clean.startsWith("https://")) {
      var ext = ".png"
      var uLower = clean.toLowerCase()
      if (uLower.indexOf(".jpg") !== -1 || uLower.indexOf(".jpeg") !== -1) ext = ".jpg"
      else if (uLower.indexOf(".webp") !== -1) ext = ".webp"

      var urlHash = _hashString(clean)
      var targetPath = store.cacheDir + "/" + urlHash + ext
      var targetFileUrl = "file://" + targetPath

      if (store.artCache[clean] === targetFileUrl) {
        return targetFileUrl
      }

      // Return the remote URL immediately so the image can load without waiting
      // for the download; the queue rewrites it to the local cache when done.
      store.artCache[clean] = clean
      if (!store._pendingDownloads[clean] && store.cacheDir !== "") {
        store._pendingDownloads[clean] = true
        enqueueDownload({
          url: clean,
          targetPath: targetPath,
          cacheKey: clean,
          fullKey: clean,
          titleKey: "",
          pendingKey: clean
        })
      }
      return clean
    }

    return clean
  }

  function hookNotificationClosed(notification) {
    if (!notification || !notification.closed) return
    if (store._hookedNotifications.indexOf(notification) !== -1) return
    store._hookedNotifications.push(notification)
    notification.closed.connect(function(reason) {
      store.removeActiveByNotification(notification)
      var idx = store._hookedNotifications.indexOf(notification)
      if (idx !== -1) store._hookedNotifications.splice(idx, 1)
    })
  }

  function removeActiveByNotification(notification) {
    for (var i = activeModel.count - 1; i >= 0; i--) {
      var item = activeModel.get(i)
      if (item && item.notification === notification) {
        activeModel.remove(i)
        if (store.hoveredIndex === i) store.hoveredIndex = -1
        else if (store.hoveredIndex > i) store.hoveredIndex--
      }
    }
  }

  function updateModelImages(fullKey, titleKey, resolvedUrl) {
    if (!resolvedUrl) return
    for (var i = 0; i < activeModel.count; i++) {
      var item = activeModel.get(i)
      if (item) {
        if (item.isMedia) {
          var k = _makeTrackKey(item.trackTitle, item.trackArtist)
          var tk = Utils.cleanTrackTitle(item.trackTitle || "").toLowerCase().trim()
          if ((fullKey && k === fullKey) || (titleKey && tk === titleKey)) {
            activeModel.setProperty(i, "image", resolvedUrl)
          }
        } else if (item.image && (item.image === fullKey || item.image === titleKey)) {
          activeModel.setProperty(i, "image", resolvedUrl)
        }
      }
    }
    for (var j = 0; j < historyModel.count; j++) {
      var hItem = historyModel.get(j)
      if (hItem) {
        if (hItem.isMedia) {
          var hk = _makeTrackKey(hItem.trackTitle, hItem.trackArtist)
          var htk = Utils.cleanTrackTitle(hItem.trackTitle || "").toLowerCase().trim()
          if ((fullKey && hk === fullKey) || (titleKey && htk === titleKey)) {
            historyModel.setProperty(j, "image", resolvedUrl)
          }
        } else if (hItem.image && (hItem.image === fullKey || hItem.image === titleKey)) {
          historyModel.setProperty(j, "image", resolvedUrl)
        }
      }
    }
  }

  function updateTrackArtUrl() {
    var title = mediaPlayer ? (mediaPlayer.trackTitle || "") : ""
    var artist = mediaPlayer ? (mediaPlayer.trackArtist || "") : ""
    var artUrl = mediaPlayer ? (mediaPlayer.trackArtUrl || "") : ""

    var resolved = store.cacheCoverArt(title, artist, artUrl)
    if (resolved) {
      var fullKey = _makeTrackKey(title, artist)
      var titleKey = Utils.cleanTrackTitle(title || "").toLowerCase().trim()
      updateModelImages(fullKey, titleKey, resolved)
    }
  }

  property bool _startupFinished: false
  Timer {
    id: startupTimer
    interval: 1500
    running: true
    repeat: false
    onTriggered: store._startupFinished = true
  }

  Timer {
    id: mediaDebounceTimer
    interval: 200
    repeat: false
    onTriggered: store.handleTrackChange()
  }

  function scheduleTrackChange() {
    if (!store._startupFinished) return
    mediaDebounceTimer.restart()
  }

  Connections {
    target: store.mediaPlayer
    function onTrackTitleChanged() { store.scheduleTrackChange() }
    function onTrackArtistChanged() { store.scheduleTrackChange() }
    function onTrackArtUrlChanged() { store.scheduleTrackChange() }
    function onIsPlayingChanged() { store.scheduleTrackChange() }
  }

  onMediaPlayerChanged: {
    updateTrackArtUrl()
    scheduleTrackChange()
  }

  function handleTrackChange() {
    if (!mediaPlayer || !mediaPlayer.isPlaying) return

    var rawTitle = mediaPlayer.trackTitle || ""
    var cleanT = Utils.cleanTrackTitle(rawTitle)
    var cleanA = mediaPlayer.trackArtist || "Unknown Artist"

    // Skip empty or generic placeholder site titles
    if (!cleanT) return
    var tLower = cleanT.toLowerCase().trim()
    var isUnknownArtist = (!cleanA || cleanA === "Unknown Artist" || cleanA.toLowerCase() === "unknown")
    if (isUnknownArtist && (
      tLower === "youtube" ||
      tLower === "soundcloud" ||
      tLower === "spotify" ||
      tLower === "netflix" ||
      tLower === "twitch" ||
      tLower === "instagram" ||
      tLower === "facebook" ||
      tLower === "twitter" ||
      tLower === "x" ||
      tLower === "unknown"
    )) {
      return
    }

    var rawArt = Utils.cleanUrl(mediaPlayer.trackArtUrl || "")
    var artUrl = rawArt ? (store.cacheCoverArt(cleanT, cleanA, rawArt) || "") : ""

    var itemData = {
      notification: null,
      summary: "Now Playing",
      body: "",
      trackTitle: cleanT,
      trackArtist: cleanA,
      appIcon: mediaPlayer.desktopEntry || mediaPlayer.name || "",
      image: artUrl,
      urgency: 0,
      isMedia: true,
      appName: mediaPlayer.name || "",
      desktopEntry: mediaPlayer.desktopEntry || "",
      timeStr: Qt.formatDateTime(new Date(), "hh:mm A"),
      createdAt: Date.now()
    }

    store.postMediaItem(itemData)
  }

  function postMediaItem(itemData) {
    if (!itemData || !itemData.trackTitle) return

    // 1. Check if an active media toast from the same player/app exists
    var existingActiveIndex = -1
    for (var a = 0; a < activeModel.count; a++) {
      var actItem = activeModel.get(a)
      if (actItem && actItem.isMedia) {
        var sameApp = (
          (itemData.desktopEntry && actItem.desktopEntry === itemData.desktopEntry) ||
          (itemData.appName && actItem.appName === itemData.appName)
        )
        var actClean = Utils.cleanTrackTitle(actItem.trackTitle)
        if (actClean === itemData.trackTitle || sameApp) {
          existingActiveIndex = a
          break
        }
      }
    }

    if (existingActiveIndex !== -1) {
      var existing = activeModel.get(existingActiveIndex)
      var existingClean = Utils.cleanTrackTitle(existing.trackTitle)
      if (existingClean === itemData.trackTitle) {
        if (existing.trackArtist === "Unknown Artist" && itemData.trackArtist !== "Unknown Artist") {
          activeModel.setProperty(existingActiveIndex, "trackArtist", itemData.trackArtist)
        }
        if (itemData.image && (!existing.image || existing.image === "")) {
          activeModel.setProperty(existingActiveIndex, "image", itemData.image)
        }
      } else {
        // Track changed on the same player: replace the active toast in-place
        activeModel.set(existingActiveIndex, itemData)
        dismissTimer.restart()
      }
    } else {
      if (!store.dnd && (Config.notifShowMediaToasts !== false)) {
        while (activeModel.count >= store.maxVisible) {
          store.dismissActiveAt(0, true)
        }
        activeModel.append(itemData)
        dismissTimer.restart()
      }
    }

    // 2. Deduplicate / update in historyModel
    var histUpdated = false
    if (historyModel.count > 0) {
      var topHist = historyModel.get(0)
      if (topHist && topHist.isMedia) {
        var sameHistApp = (
          (itemData.desktopEntry && topHist.desktopEntry === itemData.desktopEntry) ||
          (itemData.appName && topHist.appName === itemData.appName)
        )
        var topHistClean = Utils.cleanTrackTitle(topHist.trackTitle)
        var isRecent = (Date.now() - (topHist.createdAt || 0)) < 20000
        if (sameHistApp && isRecent) {
          if (topHistClean === itemData.trackTitle) {
            if (topHist.trackArtist === "Unknown Artist" && itemData.trackArtist !== "Unknown Artist") {
              historyModel.setProperty(0, "trackArtist", itemData.trackArtist)
            }
            if (itemData.image && (!topHist.image || topHist.image === "")) {
              historyModel.setProperty(0, "image", itemData.image)
            }
            histUpdated = true
          } else if (topHistClean.toLowerCase() === "youtube" || topHist.trackArtist === "Unknown Artist") {
            historyModel.set(0, itemData)
            histUpdated = true
          }
        }
      }
    }

    if (!histUpdated) {
      historyModel.insert(0, itemData)
      if (historyModel.count > maxHistory) {
        historyModel.remove(maxHistory)
      }
    }
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

    onNotification: function (notification) {
      store.hookNotificationClosed(notification)
      var appNameLower = (notification.appName || "").toLowerCase()
      var deLower = (notification.desktopEntry || "").toLowerCase()
      var summaryStr = notification.summary || ""
      var bodyStr = notification.body || ""
      var summaryLower = summaryStr.toLowerCase()
      var bodyLower = bodyStr.toLowerCase()

      // 1. Extract image (actual avatar / media art)
      var rawImg = store.extractNotificationImage(notification)
      var notifImage = rawImg ? store.cacheNotificationImage(rawImg) : ""

      // 2. Extract appIcon (app logo) - kept strictly separate from image/avatar
      var notifAppIcon = ""
      if (notification.appIcon) {
        notifAppIcon = String(notification.appIcon).trim()
        if (notifAppIcon.charAt(0) === '"' && notifAppIcon.charAt(notifAppIcon.length - 1) === '"') {
          notifAppIcon = notifAppIcon.slice(1, -1).trim()
        }
      }

      // Check if media player from Config.notifMediaApps
      var isSpotify = appNameLower.indexOf("spotify") !== -1 || deLower.indexOf("spotify") !== -1
      var isBrowserOrPlayer = isSpotify
      var mediaList = Config.notifMediaApps || []
      for (var m = 0; m < mediaList.length; m++) {
        var mKey = String(mediaList[m]).toLowerCase()
        if (appNameLower.indexOf(mKey) !== -1 || deLower.indexOf(mKey) !== -1) {
          isBrowserOrPlayer = true
          break
        }
      }

      var isMediaNotification = false
      if (store.mediaPlayer && store.mediaPlayer.trackTitle) {
        var cTitleLower = Utils.cleanTrackTitle(store.mediaPlayer.trackTitle).toLowerCase().trim()
        if (cTitleLower !== "" && isBrowserOrPlayer && (summaryLower.indexOf(cTitleLower) !== -1 || bodyLower.indexOf(cTitleLower) !== -1)) {
          isMediaNotification = true
        }
      } else if (isSpotify && notifImage) {
        isMediaNotification = true
      }

      if (isMediaNotification) {
        var isCurrentPlayerTrack = false
        if (store.mediaPlayer && store.mediaPlayer.trackTitle) {
          var curCleanT = Utils.cleanTrackTitle(store.mediaPlayer.trackTitle).toLowerCase().trim()
          if (curCleanT !== "" && (summaryLower.indexOf(curCleanT) !== -1 || bodyLower.indexOf(curCleanT) !== -1)) {
            isCurrentPlayerTrack = true
          }
        }

        var cleanT = Utils.cleanTrackTitle(notification.summary || (isCurrentPlayerTrack && store.mediaPlayer ? store.mediaPlayer.trackTitle : ""))
        var cleanA = notification.body || (isCurrentPlayerTrack && store.mediaPlayer ? store.mediaPlayer.trackArtist : "Unknown Artist")

        // Skip generic placeholder titles emitted while web player is initializing
        var tLower = cleanT.toLowerCase().trim()
        var isUnknownArtist = (!cleanA || cleanA === "Unknown Artist" || cleanA.toLowerCase() === "unknown")
        if (!cleanT || (isUnknownArtist && (
          tLower === "youtube" ||
          tLower === "soundcloud" ||
          tLower === "spotify" ||
          tLower === "netflix" ||
          tLower === "twitch" ||
          tLower === "instagram" ||
          tLower === "facebook" ||
          tLower === "twitter" ||
          tLower === "x" ||
          tLower === "unknown"
        ))) {
          return
        }

        var rawMediaArt = notifImage || (isCurrentPlayerTrack && store.mediaPlayer ? Utils.cleanUrl(store.mediaPlayer.trackArtUrl || "") : "")
        var mediaImage = rawMediaArt ? (store.cacheCoverArt(cleanT, cleanA, rawMediaArt) || "") : ""

        var mediaItemData = {
          notification: notification,
          summary: "Now Playing",
          body: "",
          trackTitle: cleanT,
          trackArtist: cleanA,
          appIcon: notifAppIcon || (store.mediaPlayer ? store.mediaPlayer.desktopEntry || store.mediaPlayer.name : ""),
          image: mediaImage,
          urgency: 0,
          isMedia: true,
          appName: notification.appName || "",
          desktopEntry: notification.desktopEntry || "",
          timeStr: Qt.formatDateTime(new Date(), "hh:mm A"),
          createdAt: Date.now()
        }

        store.postMediaItem(mediaItemData)
        return
      }

      var normalItemData = {
        notification: notification,
        summary: notification.summary || "",
        body: notification.body || "",
        trackTitle: "",
        trackArtist: "",
        appIcon: notifAppIcon,
        image: notifImage,
        urgency: notification.urgency !== undefined ? notification.urgency : 1,
        isMedia: false,
        appName: notification.appName || "",
        desktopEntry: notification.desktopEntry || "",
        timeStr: Qt.formatDateTime(new Date(), "hh:mm A"),
        createdAt: Date.now()
      }

      // Record into history
      historyModel.insert(0, normalItemData)
      if (historyModel.count > maxHistory) {
        historyModel.remove(maxHistory)
      }

      // If not muted, show active toast
      if (!store.dnd) {
        while (activeModel.count >= store.maxVisible) {
          store.dismissActiveAt(0, true)
        }
        activeModel.append(normalItemData)
        dismissTimer.restart()
      }
    }
  }

  function dismissActiveAt(i, expired) {
    if (i < 0 || i >= activeModel.count) return
    var item = activeModel.get(i)
    if (item && item.notification) {
      if (expired) {
        item.notification.expire()
      } else {
        item.notification.dismiss()
      }
    }
    activeModel.remove(i)
    if (store.hoveredIndex === i) {
      store.hoveredIndex = -1
    } else if (store.hoveredIndex > i) {
      store.hoveredIndex--
    }
  }

  function removeHistoryAt(i) {
    if (i >= 0 && i < historyModel.count) {
      historyModel.remove(i)
    }
  }

  function clearHistory() {
    historyModel.clear()
  }

  function toggleDnd() {
    store.dnd = !store.dnd
  }

  Timer {
    id: dismissTimer
    interval: 1000
    repeat: true
    running: activeModel.count > 0
    onTriggered: {
      var now = Date.now()
      for (var i = activeModel.count - 1; i >= 0; i--) {
        var item = activeModel.get(i)
        if (!item || !item.createdAt) continue

        // Urgency-aware and client-requested timeout.
        // Quickshell's `Notification.expireTimeout` is already in milliseconds
        // (raw freedesktop `expire_timeout`), so it must not be scaled again.
        var itemTimeout = store.timeoutMs
        if (item.notification && item.notification.expireTimeout > 0) {
          itemTimeout = item.notification.expireTimeout
        } else if (item.urgency === 0 && Config.notifTimeoutLowMs > 0) {
          itemTimeout = Config.notifTimeoutLowMs
        } else if (item.urgency === 2) {
          if (Config.notifTimeoutCriticalMs > 0) {
            itemTimeout = Config.notifTimeoutCriticalMs
          } else {
            continue // Critical urgency notifications are persistent
          }
        }

        if (now - item.createdAt >= itemTimeout) {
          if (store.hoveredIndex !== i) {
            store.dismissActiveAt(i, true)
          }
        }
      }
    }
  }

  function invokeActionOrFocus(item, fromActiveIndex) {
    if (item) {
      Utils.goToSource(item, Quickshell, typeof ToplevelManager !== "undefined" ? ToplevelManager : null)
    }

    if (fromActiveIndex !== undefined && fromActiveIndex >= 0) {
      dismissActiveAt(fromActiveIndex, false)
    }
  }

  function focusSender(appName, desktopEntry, appIcon) {
    Utils.goToSource({ appName: appName, desktopEntry: desktopEntry, appIcon: appIcon }, Quickshell, typeof ToplevelManager !== "undefined" ? ToplevelManager : null)
  }
}
