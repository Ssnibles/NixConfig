import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "Utils.js" as Utils

Pill {
  id: root

  property PanelWindow sharedWindow: null
  property string uiFont: Config.monoFont

  visible: root.hasMedia
  padding: 4
  anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
  height: mediaLayout.implicitHeight + 12
  radius: width / 2

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

  // --- Position & Progress Estimation (reusable helper) ---
  MediaProgress {
    id: mediaTracker
    player: root.mediaPlayer
  }

  function focusMediaPlayer() {
    if (!root.mediaPlayer) return
    var entry = root.mediaPlayer.desktopEntry || root.mediaPlayer.name || ""
    if (!entry) return
    var cmd = "niri msg --json windows | jq -r '.[] | select((.app_id | ascii_downcase) == \"" + entry.toLowerCase() + "\") | .id' | head -n1"
    var fullCmd = "id=$(" + cmd + "); if [ -n \"$id\" ]; then niri msg action focus-window --id \"$id\"; fi"
    Quickshell.execDetached(["sh", "-c", fullCmd])
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
      width: 6
      height: 36
      anchors.horizontalCenter: parent.horizontalCenter

      Rectangle {
        anchors.fill: parent
        radius: 3
        color: Colors.bgSubtle

        Rectangle {
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.right: parent.right
          height: parent.height * mediaTracker.progress
          radius: 3
          color: Colors.accent
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function(mouse) {
      if (!root.mediaPlayer) return
      if (mouse.button === Qt.RightButton) {
        root.focusMediaPlayer()
      } else {
        root.mediaPlayer.playPause()
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
    target: root
    sharedWindow: root.sharedWindow
    icon: root.mediaPlayer && root.mediaPlayer.isPlaying ? "󰎈" : "󰎆"
    iconColor: Colors.accent
    title: root.mediaPlayer ? root.mediaPlayer.identity : "Media Player"
    details: {
      var d = []
      if (root.mediaPlayer) {
        d.push(root.mediaText)
        var p = Math.round(mediaTracker.estimatedPosition)
        var l = Math.round(mediaTracker.lastLength)
        if (l > 0) {
          d.push(Utils.formatTime(p) + " / " + Utils.formatTime(l))
        }
      }
      d.push("Left click · Play/Pause")
      d.push("Right click · Focus app")
      d.push("Scroll · Next/Prev")
      return d
    }
  }
}
