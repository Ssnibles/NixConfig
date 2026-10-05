pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "Utils.js" as Utils

// Shared MPRIS media card used by the Command Centre, the bar media popover and
// the lock screen. All three previously duplicated this markup and had begun to
// drift; they now differ only through the properties below.
Rectangle {
  id: root

  // Show the card (with "Nothing is playing" placeholders) even with no player.
  property bool showWhenIdle: false
  // Whether the progress row is an interactive seek bar.
  property bool seekable: true
  // Click-to-focus / right-click-to-focus behaviour.
  property bool interactive: true
  // Card chrome (the popover uses a slightly different surface).
  property color cardColour: Colours.bgRaised
  property real cardRadius: Config.commandCentreCardRadius

  readonly property var player: MediaService.player
  readonly property bool hasPlayer: MediaService.hasPlayer

  color: root.cardColour
  border.color: Colours.border
  border.width: 1
  radius: root.cardRadius
  visible: root.showWhenIdle || root.hasPlayer
  implicitHeight: contentCol.implicitHeight + 24

  // Keep the position tick alive while the cursor is over the card (covers the
  // bar popover, where the widget's own hover has already ended).
  HoverHandler {
    id: cardHover
    onHoveredChanged: MediaService.setConsumer("mediaCard", hovered)
  }
  Component.onDestruction: MediaService.setConsumer("mediaCard", false)

  // Card-wide right-click focuses the player.
  MouseArea {
    anchors.fill: parent
    enabled: root.interactive
    acceptedButtons: Qt.RightButton
    cursorShape: root.hasPlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: function(mouse) {
      if (mouse.button === Qt.RightButton) MediaService.focusSource()
    }
  }

  Column {
    id: contentCol
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: 12
    spacing: 8

    RowLayout {
      width: parent.width
      spacing: 12

      // Album cover art
      Rectangle {
        width: 48
        height: 48
        radius: 8
        color: Colours.bgSubtle
        border.color: Colours.border
        border.width: 1

        Text {
          visible: !coverArt.ready
          text: "󰎇"
          color: Colours.fgDim
          font.family: Config.monoFont
          font.pixelSize: 22
          font.bold: true
          anchors.centerIn: parent
        }

        RoundedImage {
          id: coverArt
          anchors.fill: parent
          sourceSize: Qt.size(96, 96)
          radius: 8
          source: (root.hasPlayer && (root.player.trackTitle || root.player.trackArtUrl)) ? NotificationStore.getCoverArt(
            root.player.trackTitle || "",
            root.player.trackArtist || "",
            root.player.trackArtUrl || ""
          ) : ""
        }

        MouseArea {
          anchors.fill: parent
          enabled: root.interactive
          cursorShape: root.hasPlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onClicked: if (root.player) MediaService.focusSource()
        }
      }

      // Track details
      Item {
        Layout.fillWidth: true
        implicitHeight: trackCol.implicitHeight

        Column {
          id: trackCol
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: 2

          Text {
            width: parent.width
            text: root.hasPlayer ? Utils.cleanTrackTitle(root.player.trackTitle) : "Nothing is playing"
            color: root.hasPlayer ? Colours.fg : Colours.fgDim
            font.bold: true
            font.pixelSize: 15
            font.family: Config.sansFont
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            text: root.hasPlayer ? (root.player.trackArtist || "Unknown Artist") : "No artist"
            color: Colours.fgMid
            font.pixelSize: 13
            font.family: Config.sansFont
            elide: Text.ElideRight
          }
        }

        MouseArea {
          anchors.fill: parent
          enabled: root.interactive
          cursorShape: root.hasPlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onClicked: if (root.player) MediaService.focusSource()
        }
      }

      // Playback controls
      PlaybackControls {
        Layout.alignment: Qt.AlignVCenter
        canPrevious: !!(root.player && root.player.canGoPrevious)
        canNext: !!(root.player && root.player.canGoNext)
        isPlaying: !!(root.player && root.player.isPlaying)
        onPreviousClicked: if (root.player) root.player.previous()
        onPlayPauseClicked: { if (root.player) root.player.isPlaying = !root.player.isPlaying }
        onNextClicked: if (root.player) root.player.next()
      }
    }

    MediaProgressRow {
      width: parent.width
      visible: root.hasPlayer ? (MediaService.lastLength > 0 || MediaService.isLive) : root.showWhenIdle
      live: MediaService.isLive
      position: MediaService.estimatedPosition
      length: MediaService.lastLength
      progress: MediaService.progress
      seekable: root.seekable && MediaService.canSeek
      onSeekRequested: function(v) { MediaService.seek(v) }
    }
  }
}
