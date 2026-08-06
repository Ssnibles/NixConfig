import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "Utils.js" as Utils

Item {
  id: root

  property PanelWindow sharedWindow: null
  property string uiFont: Config.monoFont

  visible: root.hasMedia
  width: parent ? parent.width : 38
  height: mediaLayout.implicitHeight + 8
  anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined

  Rectangle {
    id: mediaBg
    anchors.fill: parent
    radius: 4
    color: mediaTooltip.hovered ? Colors.bgRaised : "transparent"
    Behavior on color { ColorAnimation { duration: 100 } }
  }

  // --- MPRIS State ---
  property var mediaPlayers: Mpris.players.values
  property var mediaPlayer: {
    var playing = Utils.findFirst(root.mediaPlayers, function(p) { return p.isPlaying })
    return playing ? playing : Utils.findFirst(root.mediaPlayers, function(p) {
      return p.playbackState === MprisPlaybackState.Paused
    })
  }

  property string mediaText: root.mediaPlayer
    ? (root.mediaPlayer.trackArtist
      ? root.mediaPlayer.trackTitle + " — " + root.mediaPlayer.trackArtist
      : root.mediaPlayer.trackTitle)
    : ""
  property bool hasMedia: root.mediaText !== ""

  // --- Position & Progress Estimation ---
  MediaProgress {
    id: mediaTracker
    player: root.mediaPlayer
  }

  function focusMediaPlayer() {
    if (!root.mediaPlayer) return
    var entry = root.mediaPlayer.desktopEntry || root.mediaPlayer.name || ""
    if (!entry) return
    
    var nodeCode =
      "const { execSync } = require('child_process'); " +
      "const pattern = '" + entry.replace(/'/g, "\\'") + "'.toLowerCase(); " +
      "try { " +
      "  const stdout = execSync('niri msg --json windows', { encoding: 'utf8' }); " +
      "  const windows = JSON.parse(stdout); " +
      "  for (const win of windows) { " +
      "    const appId = (win.app_id || '').toLowerCase(); " +
      "    const title = (win.title || '').toLowerCase(); " +
      "    if (appId.includes(pattern) || title.includes(pattern)) { " +
      "      execSync('niri msg action focus-window --id ' + win.id); " +
      "      process.exit(0); " +
      "    } " +
      "  } " +
      "} catch (e) {}"

    Quickshell.execDetached(["node", "-e", nodeCode])
  }

  // --- UI Layout ---
  Column {
    id: mediaLayout
    spacing: 8
    anchors.top: parent.top
    anchors.topMargin: 6
    anchors.horizontalCenter: parent.horizontalCenter

    Item {
      id: spinningContainer
      width: 16
      height: 16
      anchors.horizontalCenter: parent.horizontalCenter

      Text {
        id: mediaIcon
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: root.mediaPlayer && root.mediaPlayer.isPlaying ? "󰎈" : "󰎆"
        color: root.mediaPlayer && root.mediaPlayer.isPlaying ? Colors.accent : Colors.fgDim
        font.pixelSize: 12
        font.family: root.uiFont
      }

      NumberAnimation on rotation {
        loops: Animation.Infinite
        from: 0
        to: 360
        duration: 4000
        running: root.mediaPlayer && root.mediaPlayer.isPlaying
      }
    }

    // Vertical progress bar
    Item {
      width: 12
      height: 36
      anchors.horizontalCenter: parent.horizontalCenter

      Rectangle {
        anchors.fill: parent
        radius: 4
        color: Colors.bgSubtle

        Rectangle {
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.right: parent.right
          height: parent.height * mediaTracker.progress
          radius: 4
          color: Colors.accent
        }
      }
    }

    // Compact elapsed time text
    Text {
      id: elapsedLabel
      anchors.horizontalCenter: parent.horizontalCenter
      text: Utils.formatTime(Math.round(mediaTracker.estimatedPosition))
      color: Colors.fgMid
      font.family: root.uiFont
      font.pixelSize: 8
      horizontalAlignment: Text.AlignHCenter
    }
  }

  // Fallback click on non-control areas to toggle/focus
  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function(mouse) {
      if (!root.mediaPlayer) return
      if (mouse.button === Qt.RightButton) {
        root.focusMediaPlayer()
      } else {
        root.mediaPlayer.isPlaying = !root.mediaPlayer.isPlaying
      }
    }
    onWheel: function(wheel) {
      if (!root.mediaPlayer) return
      if (wheel.angleDelta.y > 0) {
        if (root.mediaPlayer.canGoNext) root.mediaPlayer.next()
      } else if (wheel.angleDelta.y < 0) {
        if (root.mediaPlayer.canGoPrevious) root.mediaPlayer.previous()
      }
      wheel.accepted = true
    }
  }

  Tooltip {
    id: mediaTooltip
    target: root
    sharedWindow: root.sharedWindow
    contentComponent: mediaPopoverComponent
  }

  Component {
    id: mediaPopoverComponent

    Rectangle {
      id: popoverCard
      width: 220
      height: popoverContent.implicitHeight + 24
      radius: Config.popupRadius
      color: Colors.bg
      border.color: Colors.border
      border.width: 1

      Column {
        id: popoverContent
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 12

        // Top section: Album Art & Track Info
        RowLayout {
          width: parent.width
          spacing: 12

          // Album Art
          Rectangle {
            width: 40
            height: 40
            radius: 6
            color: Colors.bgSubtle
            border.color: Colors.border
            border.width: 1

            Text {
              visible: !popoverCover.visible
              text: "󰎆"
              color: Colors.fgDim
              font.family: root.uiFont
              font.pixelSize: 16
              anchors.centerIn: parent
            }

            // Mask for rounded corners
            Item {
              id: popoverCoverMask
              width: parent.width
              height: parent.height
              visible: false
              layer.enabled: true
              Rectangle {
                width: parent.width
                height: parent.height
                radius: 6
                color: "black"
              }
            }

            IconImage {
              id: popoverCover
              anchors.fill: parent
              visible: source !== ""
              source: {
                if (!root.mediaPlayer) return ""
                var url = root.mediaPlayer.trackArtUrl
                if (url) {
                  url = String(url).trim()
                  if (url.charAt(0) === '"' && url.charAt(url.length - 1) === '"') url = url.slice(1, -1)
                  return url
                }
                return ""
              }

              layer.enabled: true
              layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: popoverCoverMask
              }
            }
          }

          // Track Details
          Column {
            Layout.fillWidth: true
            spacing: 2

            Text {
              width: parent.width
              text: root.mediaPlayer ? root.mediaPlayer.trackTitle : "No Media"
              color: Colors.fg
              font.bold: true
              font.pixelSize: 12
              font.family: Config.sansFont
              elide: Text.ElideRight
            }

            Text {
              width: parent.width
              text: root.mediaPlayer ? (root.mediaPlayer.trackArtist || "Unknown Artist") : ""
              color: Colors.fgMid
              font.pixelSize: 10
              font.family: Config.sansFont
              elide: Text.ElideRight
            }
          }
        }

        // Progress Bar
        Column {
          width: parent.width
          spacing: 4

          Item {
            width: parent.width
            height: 12

            Rectangle {
              anchors.fill: parent
              radius: 4
              color: Colors.bgSubtle

              Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * mediaTracker.progress
                radius: 4
                color: Colors.accent
              }
            }
          }

          Item {
            width: parent.width
            height: elapsedLabel2.implicitHeight
            
            Text {
              id: elapsedLabel2
              anchors.left: parent.left
              text: Utils.formatTime(Math.round(mediaTracker.estimatedPosition))
              color: Colors.fgMid
              font.family: root.uiFont
              font.pixelSize: 9
            }

            Text {
              anchors.right: parent.right
              text: Utils.formatTime(Math.round(mediaTracker.lastLength))
              color: Colors.fgDim
              font.family: root.uiFont
              font.pixelSize: 9
            }
          }
        }

        // Divider
        Rectangle {
          width: parent.width
          height: 1
          color: Colors.border
        }

        // Playback Buttons
        RowLayout {
          width: parent.width
          
          Item { Layout.fillWidth: true }

          // Prev Button
          Rectangle {
            width: 28
            height: 28
            radius: 14
            color: prevHover.containsMouse ? Colors.bgSubtle : "transparent"

            Text {
              text: "󰒮"
              color: (root.mediaPlayer && root.mediaPlayer.canGoPrevious) ? (prevHover.containsMouse ? Colors.accent : Colors.fg) : Colors.fgDim
              font.family: root.uiFont
              font.pixelSize: 12
              anchors.centerIn: parent
            }

            MouseArea {
              id: prevHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: (root.mediaPlayer && root.mediaPlayer.canGoPrevious) ? Qt.PointingHandCursor : Qt.ArrowCursor
              onClicked: {
                if (root.mediaPlayer && root.mediaPlayer.canGoPrevious) {
                  root.mediaPlayer.previous()
                }
              }
            }
          }

          // Play/Pause Button
          Rectangle {
            width: 32
            height: 32
            radius: 16
            color: playHover.containsMouse ? Colors.accent : Colors.bgSubtle
            border.color: Colors.border
            border.width: 1

            Text {
              text: root.mediaPlayer && root.mediaPlayer.isPlaying ? "󰏤" : "󰐊"
              color: playHover.containsMouse ? Colors.bg : Colors.fg
              font.family: root.uiFont
              font.pixelSize: 14
              anchors.centerIn: parent
            }

            MouseArea {
              id: playHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (root.mediaPlayer) {
                  root.mediaPlayer.isPlaying = !root.mediaPlayer.isPlaying
                }
              }
            }
          }

          // Next Button
          Rectangle {
            width: 28
            height: 28
            radius: 14
            color: nextHover.containsMouse ? Colors.bgSubtle : "transparent"

            Text {
              text: "󰒭"
              color: (root.mediaPlayer && root.mediaPlayer.canGoNext) ? (nextHover.containsMouse ? Colors.accent : Colors.fg) : Colors.fgDim
              font.family: root.uiFont
              font.pixelSize: 12
              anchors.centerIn: parent
            }

            MouseArea {
              id: nextHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: (root.mediaPlayer && root.mediaPlayer.canGoNext) ? Qt.PointingHandCursor : Qt.ArrowCursor
              onClicked: {
                if (root.mediaPlayer && root.mediaPlayer.canGoNext) {
                  root.mediaPlayer.next()
                }
              }
            }
          }

          Item { Layout.fillWidth: true }
        }
      }
    }
  }
}
