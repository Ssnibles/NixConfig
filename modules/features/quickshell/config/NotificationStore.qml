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
    var playing = Utils.findFirst(store.mediaPlayers, function(p) { return p.isPlaying })
    return playing ? playing : Utils.findFirst(store.mediaPlayers, function(p) {
      return p.playbackState === MprisPlaybackState.Paused
    })
  }

  property string currentTrackKey: ""

  Connections {
    target: store.mediaPlayer
    function onTrackTitleChanged() { store.updateTrackKey() }
    function onTrackArtistChanged() { store.updateTrackKey() }
    function onIsPlayingChanged() { store.updateTrackKey() }
  }

  onMediaPlayerChanged: updateTrackKey()

  function updateTrackKey() {
    if (!mediaPlayer) {
      currentTrackKey = ""
    } else {
      currentTrackKey = (mediaPlayer.trackTitle || "") + " — " + (mediaPlayer.trackArtist || "")
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
      var itemData = {
        notification: null,
        summary: "Now Playing",
        body: "",
        trackTitle: mediaPlayer.trackTitle || "",
        trackArtist: mediaPlayer.trackArtist || "Unknown Artist",
        appIcon: mediaPlayer.desktopEntry || mediaPlayer.name || "",
        image: mediaPlayer.trackArtUrl || "",
        urgency: 0,
        isMedia: true,
        appName: mediaPlayer.name || "",
        desktopEntry: mediaPlayer.desktopEntry || "",
        timeStr: Qt.formatDateTime(new Date(), "hh:mm A")
      }

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

  NotificationServer {
    id: notificationServer
    bodySupported: true

    onNotification: function (notification) {
      var isSpotify = notification.appName === "Spotify"

      var itemData = {
        notification: notification,
        summary: isSpotify ? "Now Playing" : notification.summary,
        body: isSpotify ? "" : notification.body,
        trackTitle: isSpotify ? notification.summary : "",
        trackArtist: isSpotify ? notification.body : "",
        appIcon: notification.appIcon || "",
        image: notification.image || "",
        urgency: notification.urgency !== undefined ? notification.urgency : 1,
        isMedia: isSpotify,
        appName: notification.appName || "",
        desktopEntry: notification.desktopEntry || "",
        timeStr: Qt.formatDateTime(new Date(), "hh:mm A")
      }

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

    var uniquePatterns = []
    for (var i = 0; i < patterns.length; i++) {
      var p = patterns[i].trim()
      if (p && uniquePatterns.indexOf(p) === -1) {
        uniquePatterns.push(p)
      }
    }

    if (uniquePatterns.length === 0) return

    var escPatterns = []
    for (var j = 0; j < uniquePatterns.length; j++) {
      escPatterns.push("'" + uniquePatterns[j].replace(/'/g, "\\'") + "'")
    }

    var nodeCode =
      "const { execSync } = require('child_process'); " +
      "const patterns = [" + escPatterns.join(", ") + "].map(p => p.toLowerCase()); " +
      "try { " +
      "  const stdout = execSync('niri msg --json windows', { encoding: 'utf8' }); " +
      "  const windows = JSON.parse(stdout); " +
      "  for (const win of windows) { " +
      "    const appId = (win.app_id || '').toLowerCase(); " +
      "    const title = (win.title || '').toLowerCase(); " +
      "    if (patterns.some(p => appId.includes(p) || title.includes(p))) { " +
      "      execSync('niri msg action focus-window --id ' + win.id); " +
      "      process.exit(0); " +
      "    } " +
      "  } " +
      "} catch (e) {}"

    var cmd = [
      "node", "-e", nodeCode
    ]
    Quickshell.execDetached(cmd)
  }
}
