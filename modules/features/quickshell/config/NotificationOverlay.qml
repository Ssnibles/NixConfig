import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import Quickshell.Services.Mpris
import QtQuick
import "Utils.js" as Utils

Scope {
  id: root

  property string position: Config.notifPosition
  property int timeoutMs: Config.notifTimeoutMs
  property int maxVisible: Config.notifMaxVisible
  property int hoveredIndex: -1

  ListModel {
    id: notifModel
    dynamicRoles: true
  }

  // --- MPRIS Track Change Listener ---
  property var mediaPlayers: Mpris.players.values
  property var mediaPlayer: {
    var playing = Utils.findFirst(root.mediaPlayers, function(p) { return p.isPlaying })
    return playing ? playing : Utils.findFirst(root.mediaPlayers, function(p) {
      return p.playbackState === MprisPlaybackState.Paused
    })
  }

  property string currentTrackKey: {
    if (!mediaPlayer) return ""
    return mediaPlayer.trackTitle + " — " + mediaPlayer.trackArtist
  }

  // Prevent firing on startup
  property bool _startupFinished: false
  Timer {
    id: startupTimer
    interval: 1500
    running: true
    repeat: false
    onTriggered: root._startupFinished = true
  }

  onCurrentTrackKeyChanged: {
    if (!root._startupFinished) return
    if (currentTrackKey !== "" && mediaPlayer && mediaPlayer.isPlaying) {
      while (notifModel.count >= root.maxVisible) {
        root.dismissAt(0, true)
      }

      notifModel.append({
        notification: null,
        summary: "Now Playing",
        body: "",
        trackTitle: mediaPlayer.trackTitle,
        trackArtist: mediaPlayer.trackArtist || "Unknown Artist",
        appIcon: mediaPlayer.desktopEntry || mediaPlayer.name || "",
        image: mediaPlayer.trackArtUrl || "",
        urgency: 0, // Low urgency for media so it auto-dismisses
        isMedia: true,
        appName: mediaPlayer.name || "",
        desktopEntry: mediaPlayer.desktopEntry || ""
      })
      dismissTimer.restart()
    }
  }

  NotificationServer {
    id: notificationServer
    bodySupported: true

    onNotification: function (notification) {
      var isSpotify = notification.appName === "Spotify"
      
      while (notifModel.count >= root.maxVisible) {
        root.dismissAt(0, true)
      }

      notifModel.append({
        notification: notification,
        summary: isSpotify ? "Now Playing" : notification.summary,
        body: isSpotify ? "" : notification.body,
        trackTitle: isSpotify ? notification.summary : "",
        trackArtist: isSpotify ? notification.body : "",
        appIcon: notification.appIcon || "",
        image: notification.image || "",
        urgency: notification.urgency,
        isMedia: isSpotify,
        appName: notification.appName || "",
        desktopEntry: notification.desktopEntry || ""
      })
      dismissTimer.restart()
    }
  }

  function dismissAt(i, expired) {
    if (i < 0 || i >= notifModel.count) return
    var item = notifModel.get(i)
    if (item && item.notification) {
      if (expired) {
        item.notification.expire()
      } else {
        item.notification.dismiss()
      }
    }
    notifModel.remove(i)
    if (root.hoveredIndex === i) {
      root.hoveredIndex = -1
    } else if (root.hoveredIndex > i) {
      root.hoveredIndex--
    }
  }

  Timer {
    id: dismissTimer
    interval: root.timeoutMs
    onTriggered: {
      var indexToDismiss = -1
      // If a card is hovered, only auto-dismiss items *after* the hovered index (i > root.hoveredIndex).
      // Dismissing items before the hovered index would shift the hovered card's Y position in the list.
      var startIndex = (root.hoveredIndex !== -1) ? root.hoveredIndex + 1 : 0
      for (var i = startIndex; i < notifModel.count; i++) {
        var item = notifModel.get(i)
        if (item && item.urgency !== 2) { // 2 = Critical
          indexToDismiss = i
          break
        }
      }
      if (indexToDismiss !== -1) {
        root.dismissAt(indexToDismiss, true)
      }
      if (notifModel.count > 0) restart()
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

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel
      required property var modelData
      screen: modelData

      readonly property bool onTop: root.position.indexOf("top") !== -1
      readonly property bool onLeft: root.position.indexOf("left") !== -1

      anchors.top: onTop
      anchors.bottom: onTop ? false : true
      anchors.left: onLeft
      anchors.right: onLeft ? false : true

      implicitWidth: Config.notifWidth + Config.notifCardMargins * 2
      implicitHeight: notifList.contentHeight + Config.notifCardMargins * 2
      color: "transparent"

      ListView {
        id: notifList
        width: parent.width - Config.notifCardMargins * 2
        height: contentHeight
        spacing: Config.notifSpacing
        interactive: false
        model: notifModel

        anchors.margins: Config.notifCardMargins
        anchors.top: panel.onTop ? parent.top : undefined
        anchors.bottom: panel.onTop ? undefined : parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        add: Transition {
          NumberAnimation { property: "opacity"; from: 0; duration: 250; easing.type: Easing.OutCubic }
          NumberAnimation { property: "scale"; from: 0.8; to: 1.0; duration: 250; easing.type: Easing.OutBack }
        }

        remove: Transition {
          NumberAnimation { property: "opacity"; to: 0; duration: 200; easing.type: Easing.OutCubic }
          NumberAnimation { property: "scale"; to: 0.8; duration: 200; easing.type: Easing.OutCubic }
        }

        displaced: Transition {
          NumberAnimation { properties: "y"; duration: 250; easing.type: Easing.OutCubic }
        }

        delegate: NotificationCard {
          id: card
          notification: model.notification
          appName: model.appName || ""
          desktopEntry: model.desktopEntry || ""
          summary: model.summary || ""
          body: model.body || ""
          appIcon: model.appIcon || ""
          image: model.image || ""
          urgency: model.urgency !== undefined ? model.urgency : 1
          trackTitle: model.trackTitle || ""
          trackArtist: model.trackArtist || ""
          isMedia: model.isMedia !== undefined ? model.isMedia : false

          onIsHoveredChanged: {
            if (card.isHovered) {
              root.hoveredIndex = index
            } else if (root.hoveredIndex === index) {
              root.hoveredIndex = -1
            }
          }

          onDismissed: root.dismissAt(index, false)
          onActionTriggered: {
            var defaultAction = null
            if (model.notification && model.notification.actions) {
              for (var a = 0; a < model.notification.actions.length; a++) {
                if (model.notification.actions[a].identifier === "default") {
                  defaultAction = model.notification.actions[a]
                  break
                }
              }
            }
            
            if (defaultAction) {
              defaultAction.invoke()
            } else {
              root.focusSender(model.appName, model.desktopEntry, model.appIcon)
            }
            root.dismissAt(index, false)
          }
        }
      }
    }
  }
}