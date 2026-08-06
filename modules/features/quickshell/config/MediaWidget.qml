import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "Utils.js" as Utils

Pill {
  id: root

  property PanelWindow sharedWindow: null
  property string uiFont: "JetBrainsMono Nerd Font"

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

  // --- Position & Progress Estimation ---
  property int mediaTick: 0
  property real mediaLastPosition: 0
  property real mediaLastLength: 0
  property int mediaResetToken: 0
  property real mediaWallClock: 0

  function resetMediaTiming(pos, len) {
    root.mediaLastPosition = Math.max(0, pos || 0)
    root.mediaLastLength = Math.max(0, len || 0)
    root.mediaWallClock = Date.now() / 1000
    root.mediaTick = 0
    root.mediaResetToken++
  }

  function updateMediaPosition(pos, len) {
    var p = Math.max(0, pos || 0)
    var l = Math.max(0, len || 0)
    if (p + 0.5 < root.mediaLastPosition) {
      root.resetMediaTiming(p, l)
      return
    }
    root.mediaLastPosition = p
    root.mediaLastLength = l
    root.mediaWallClock = Date.now() / 1000
  }

  property real mediaEstimatedPosition: {
    var _ = root.mediaTick
    var __ = root.mediaResetToken
    if (!root.mediaPlayer) return root.mediaLastPosition
    var elapsed = Date.now() / 1000 - root.mediaWallClock
    return root.mediaLastPosition + (root.mediaPlayer.isPlaying ? elapsed : 0)
  }

  property real mediaProgress: {
    var _ = root.mediaTick
    var __ = root.mediaResetToken
    if (!root.mediaPlayer || root.mediaLastLength <= 0) return 0
    return Math.min(1, Math.max(0, root.mediaEstimatedPosition / root.mediaLastLength))
  }

  onMediaPlayerChanged: {
    if (!root.mediaPlayer) {
      root.resetMediaTiming(0, 0)
      return
    }
    root.resetMediaTiming(root.mediaPlayer.position, root.mediaPlayer.length)
  }

  Connections {
    target: root.mediaPlayer
    ignoreUnknownSignals: true
    function onPositionChanged() {
      if (!root.mediaPlayer) return
      root.updateMediaPosition(root.mediaPlayer.position, root.mediaPlayer.length)
    }
    function onLengthChanged() {
      if (!root.mediaPlayer) return
      root.mediaLastLength = Math.max(0, root.mediaPlayer.length || 0)
    }
    function onTrackChanged() {
      if (!root.mediaPlayer) return
      root.resetMediaTiming(root.mediaPlayer.position, root.mediaPlayer.length)
    }
  }

  Timer {
    id: tickTimer
    interval: 300
    running: root.mediaPlayer && root.mediaPlayer.isPlaying
    repeat: true
    onTriggered: {
      if (root.mediaPlayer) {
        root.updateMediaPosition(root.mediaPlayer.position, root.mediaPlayer.length)
      }
      root.mediaTick++
    }
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
          height: parent.height * root.mediaProgress
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
        var p = Math.round(root.mediaEstimatedPosition)
        var l = Math.round(root.mediaLastLength)
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
