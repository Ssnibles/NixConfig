pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Services.Mpris
import QtQuick
import "Utils.js" as Utils

Singleton {
  id: store

  property bool dnd: false
  property int maxVisible: Config.notifMaxVisible
  property int timeoutMs: Config.notifTimeoutMs
  property int maxHistory: 50
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
  property var mediaPlayers: Mpris.players.values
  property var mediaPlayer: {
    var playing = Utils.findFirst(store.mediaPlayers, function(p) { return p && p.isPlaying })
    return playing ? playing : Utils.findFirst(store.mediaPlayers, function(p) {
      return p && p.playbackState === MprisPlaybackState.Paused
    })
  }

  property string currentTrackKey: ""
  property string latestMediaImage: ""

  Connections {
    target: store.mediaPlayer
    function onTrackTitleChanged() { store.updateTrackKey() }
    function onTrackArtistChanged() { store.updateTrackKey() }
    function onTrackArtUrlChanged() { store.updateTrackArtUrl() }
    function onIsPlayingChanged() { store.updateTrackKey() }
  }

  onMediaPlayerChanged: {
    updateTrackKey()
    updateTrackArtUrl()
  }

  function updateTrackKey() {
    if (!mediaPlayer) {
      currentTrackKey = ""
    } else {
      var cleanT = Utils.cleanTrackTitle(mediaPlayer.trackTitle || "")
      var cleanA = mediaPlayer.trackArtist || ""
      currentTrackKey = cleanT + " — " + cleanA
    }
    updateTrackArtUrl()
  }

  function updateTrackArtUrl() {
    var artUrl = mediaPlayer ? (mediaPlayer.trackArtUrl || "") : ""
    if (artUrl) {
      var strUrl = String(artUrl).trim()
      if (strUrl.charAt(0) === '"' && strUrl.charAt(strUrl.length - 1) === '"') {
        strUrl = strUrl.slice(1, -1)
      }
      if (strUrl !== "") store.latestMediaImage = strUrl
    }
    if (!store.latestMediaImage) return

    for (var i = 0; i < activeModel.count; i++) {
      var item = activeModel.get(i)
      if (item && item.isMedia && (!item.image || item.image === "")) {
        activeModel.setProperty(i, "image", store.latestMediaImage)
      }
    }

    for (var j = 0; j < historyModel.count; j++) {
      var hItem = historyModel.get(j)
      if (hItem && hItem.isMedia && (!hItem.image || hItem.image === "")) {
        historyModel.setProperty(j, "image", store.latestMediaImage)
      }
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

  onCurrentTrackKeyChanged: {
    if (!store._startupFinished) return
    if (currentTrackKey !== "" && mediaPlayer && mediaPlayer.isPlaying) {
      var artUrl = mediaPlayer.trackArtUrl || ""
      if (artUrl) {
        artUrl = String(artUrl).trim()
        if (artUrl.charAt(0) === '"' && artUrl.charAt(artUrl.length - 1) === '"') {
          artUrl = artUrl.slice(1, -1)
        }
        if (artUrl !== "") store.latestMediaImage = artUrl
      }

      var rawTitle = mediaPlayer.trackTitle || ""
      var cleanT = Utils.cleanTrackTitle(rawTitle)
      var cleanA = mediaPlayer.trackArtist || "Unknown Artist"

      var itemData = {
        notification: null,
        summary: "Now Playing",
        body: "",
        trackTitle: cleanT,
        trackArtist: cleanA,
        appIcon: mediaPlayer.desktopEntry || mediaPlayer.name || "",
        image: artUrl || store.latestMediaImage || "",
        urgency: 0,
        isMedia: true,
        appName: mediaPlayer.name || "",
        desktopEntry: mediaPlayer.desktopEntry || "",
        timeStr: Qt.formatDateTime(new Date(), "hh:mm A")
      }

      // Deduplicate in activeModel by clean title
      var alreadyActive = false
      for (var a = 0; a < activeModel.count; a++) {
        var actItem = activeModel.get(a)
        if (actItem && actItem.isMedia) {
          var actCleanTitle = Utils.cleanTrackTitle(actItem.trackTitle)
          if (actCleanTitle === cleanT && cleanT !== "") {
            alreadyActive = true
            if (actItem.trackArtist === "Unknown Artist" && cleanA !== "Unknown Artist") {
              activeModel.setProperty(a, "trackArtist", cleanA)
            }
            if ((artUrl || store.latestMediaImage) && (!actItem.image || actItem.image === "")) {
              activeModel.setProperty(a, "image", artUrl || store.latestMediaImage)
            }
            break
          }
        }
      }

      // Also update matching items in historyModel
      for (var h = 0; h < historyModel.count; h++) {
        var histItem = historyModel.get(h)
        if (histItem && histItem.isMedia) {
          var histCleanTitle = Utils.cleanTrackTitle(histItem.trackTitle)
          if (histCleanTitle === cleanT && cleanT !== "") {
            if (histItem.trackArtist === "Unknown Artist" && cleanA !== "Unknown Artist") {
              historyModel.setProperty(h, "trackArtist", cleanA)
            }
            if ((artUrl || store.latestMediaImage) && (!histItem.image || histItem.image === "")) {
              historyModel.setProperty(h, "image", artUrl || store.latestMediaImage)
            }
          }
        }
      }

      if (!alreadyActive) {
        // Record into history
        historyModel.insert(0, itemData)
        if (historyModel.count > maxHistory) {
          historyModel.remove(maxHistory)
        }

        // If not muted, show active toast
        if (!store.dnd) {
          while (activeModel.count >= store.maxVisible) {
            store.dismissActiveAt(0, true)
          }
          activeModel.append(itemData)
          dismissTimer.restart()
        }
      }
    }
  }

  NotificationServer {
    id: notificationServer
    bodySupported: true

    onNotification: function (notification) {
      var appNameLower = (notification.appName || "").toLowerCase()
      var deLower = (notification.desktopEntry || "").toLowerCase()
      var summaryStr = notification.summary || ""
      var bodyStr = notification.body || ""
      var summaryLower = summaryStr.toLowerCase()
      var bodyLower = bodyStr.toLowerCase()

      var isSpotify = appNameLower.indexOf("spotify") !== -1 || deLower.indexOf("spotify") !== -1
      var isBrowserOrPlayer = isSpotify ||
        appNameLower.indexOf("zen") !== -1 || deLower.indexOf("zen") !== -1 ||
        appNameLower.indexOf("qutebrowser") !== -1 || deLower.indexOf("qutebrowser") !== -1 ||
        appNameLower.indexOf("firefox") !== -1 || deLower.indexOf("firefox") !== -1 ||
        appNameLower.indexOf("chrome") !== -1 || deLower.indexOf("chrome") !== -1 ||
        appNameLower.indexOf("chromium") !== -1 || deLower.indexOf("chromium") !== -1 ||
        appNameLower.indexOf("brave") !== -1 || deLower.indexOf("brave") !== -1 ||
        appNameLower.indexOf("vivaldi") !== -1 || deLower.indexOf("vivaldi") !== -1 ||
        appNameLower.indexOf("librewolf") !== -1 || deLower.indexOf("librewolf") !== -1 ||
        appNameLower.indexOf("vlc") !== -1 || deLower.indexOf("mpv") !== -1

      var notifImage = notification.image || notification.appIcon || ""
      if (notifImage) {
        notifImage = String(notifImage).trim()
        if (notifImage.charAt(0) === '"' && notifImage.charAt(notifImage.length - 1) === '"') {
          notifImage = notifImage.slice(1, -1)
        }
      }

      var isMediaNotification = isSpotify
      if (!isMediaNotification && isBrowserOrPlayer) {
        if (appNameLower.indexOf("zen") !== -1 || appNameLower.indexOf("qutebrowser") !== -1 ||
            appNameLower.indexOf("firefox") !== -1 || notification.category === "x-freedesktop.notification.media") {
          isMediaNotification = true
        } else if (store.mediaPlayer && store.mediaPlayer.trackTitle) {
          var cTitleLower = Utils.cleanTrackTitle(store.mediaPlayer.trackTitle).toLowerCase()
          if (cTitleLower !== "" && (summaryLower.indexOf(cTitleLower) !== -1 || bodyLower.indexOf(cTitleLower) !== -1)) {
            isMediaNotification = true
          }
        }
      }

      if (isMediaNotification) {
        if (notifImage && notifImage !== "") {
          store.latestMediaImage = notifImage
        }

        var cleanT = Utils.cleanTrackTitle(notification.summary || (store.mediaPlayer ? store.mediaPlayer.trackTitle : ""))
        var cleanA = notification.body || (store.mediaPlayer ? store.mediaPlayer.trackArtist : "Unknown Artist")
        var mediaImage = notifImage || store.latestMediaImage || (store.mediaPlayer ? store.mediaPlayer.trackArtUrl || "" : "")

        var mediaItemData = {
          notification: notification,
          summary: "Now Playing",
          body: "",
          trackTitle: cleanT,
          trackArtist: cleanA,
          appIcon: notification.appIcon || (store.mediaPlayer ? store.mediaPlayer.desktopEntry || store.mediaPlayer.name : ""),
          image: mediaImage,
          urgency: 0,
          isMedia: true,
          appName: notification.appName || "",
          desktopEntry: notification.desktopEntry || "",
          timeStr: Qt.formatDateTime(new Date(), "hh:mm A")
        }

        // Deduplicate in activeModel by clean title
        var alreadyActive = false
        for (var a = 0; a < activeModel.count; a++) {
          var actItem = activeModel.get(a)
          if (actItem && actItem.isMedia) {
            var actCleanTitle = Utils.cleanTrackTitle(actItem.trackTitle)
            if (actCleanTitle === cleanT && cleanT !== "") {
              alreadyActive = true
              if (cleanA && cleanA !== "Unknown Artist") {
                activeModel.setProperty(a, "trackArtist", cleanA)
              }
              if (mediaImage && mediaImage !== "") {
                activeModel.setProperty(a, "image", mediaImage)
              }
              break
            }
          }
        }

        // Also update matching items in historyModel
        for (var h = 0; h < historyModel.count; h++) {
          var histItem = historyModel.get(h)
          if (histItem && histItem.isMedia) {
            var histCleanTitle = Utils.cleanTrackTitle(histItem.trackTitle)
            if (histCleanTitle === cleanT && cleanT !== "") {
              if (cleanA && cleanA !== "Unknown Artist") {
                historyModel.setProperty(h, "trackArtist", cleanA)
              }
              if (mediaImage && mediaImage !== "") {
                historyModel.setProperty(h, "image", mediaImage)
              }
            }
          }
        }

        if (!alreadyActive && cleanT !== "") {
          historyModel.insert(0, mediaItemData)
          if (historyModel.count > maxHistory) {
            historyModel.remove(maxHistory)
          }
          if (!store.dnd) {
            while (activeModel.count >= store.maxVisible) {
              store.dismissActiveAt(0, true)
            }
            activeModel.append(mediaItemData)
            dismissTimer.restart()
          }
        }
        return
      }

      var normalItemData = {
        notification: notification,
        summary: notification.summary,
        body: notification.body,
        trackTitle: "",
        trackArtist: "",
        appIcon: notification.appIcon || "",
        image: notifImage,
        urgency: notification.urgency !== undefined ? notification.urgency : 1,
        isMedia: false,
        appName: notification.appName || "",
        desktopEntry: notification.desktopEntry || "",
        timeStr: Qt.formatDateTime(new Date(), "hh:mm A")
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
    interval: store.timeoutMs
    onTriggered: {
      var indexToDismiss = -1
      var startIndex = (store.hoveredIndex !== -1) ? store.hoveredIndex + 1 : 0
      for (var i = startIndex; i < activeModel.count; i++) {
        var item = activeModel.get(i)
        if (item && item.urgency !== 2) { // 2 = Critical
          indexToDismiss = i
          break
        }
      }
      if (indexToDismiss !== -1) {
        store.dismissActiveAt(indexToDismiss, true)
      }
      if (activeModel.count > 0) restart()
    }
  }

  function invokeActionOrFocus(item, fromActiveIndex) {
    var defaultAction = null
    if (item && item.notification && item.notification.actions) {
      for (var a = 0; a < item.notification.actions.length; a++) {
        if (item.notification.actions[a].identifier === "default") {
          defaultAction = item.notification.actions[a]
          break
        }
      }
    }

    if (defaultAction) {
      defaultAction.invoke()
    } else if (item) {
      focusSender(item.appName, item.desktopEntry, item.appIcon)
    }

    if (fromActiveIndex !== undefined && fromActiveIndex >= 0) {
      dismissActiveAt(fromActiveIndex, false)
    }
  }

  function focusSender(appName, desktopEntry, appIcon) {
    var iconName = appIcon || ""
    if (iconName) {
      var slashIdx = iconName.lastIndexOf("/")
      if (slashIdx !== -1) {
        iconName = iconName.substring(slashIdx + 1)
      }
      var dotIdx = iconName.lastIndexOf(".")
      if (dotIdx !== -1) {
        iconName = iconName.substring(0, dotIdx)
      }
    }

    var patterns = []
    if (appName) patterns.push(appName)
    if (desktopEntry) patterns.push(desktopEntry)
    if (iconName) patterns.push(iconName)

    Utils.focusWindow(patterns)
  }
}
