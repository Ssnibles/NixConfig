pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

// Shared MPRIS media card used by the Command Centre, the bar media popover and
// the lock screen. Ingests centralised state and actions from MediaService.
Card {
  id: root

  // Show the card (with "Nothing is playing" placeholders) even with no player.
  property bool showWhenIdle: false
  // Whether the progress row is an interactive seek bar.
  property bool seekable: true
  // Click-to-focus / right-click-to-focus behaviour.
  property bool interactive: true

  readonly property bool hasPlayer: MediaService.hasPlayer

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
        width: 54
        height: 54
        radius: 8
        color: Colours.bgSubtle
        border.color: Colours.border
        border.width: 1
        Layout.alignment: Qt.AlignVCenter

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
          sourceSize: Qt.size(108, 108)
          radius: 8
          source: root.hasPlayer ? MediaService.trackArtUrl : ""
        }

        MouseArea {
          anchors.fill: parent
          enabled: root.interactive
          cursorShape: root.hasPlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onClicked: if (root.hasPlayer) MediaService.focusSource()
        }
      }

      // Track details
      Item {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        implicitHeight: trackCol.implicitHeight

        MouseArea {
          anchors.fill: parent
          enabled: root.interactive
          cursorShape: root.hasPlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onClicked: if (root.hasPlayer) MediaService.focusSource()
        }

        Column {
          id: trackCol
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: 2

          Text {
            width: parent.width
            text: root.hasPlayer ? (MediaService.trackTitle || "Unknown Track") : "Nothing is playing"
            color: root.hasPlayer ? Colours.fg : Colours.fgDim
            font.bold: true
            font.pixelSize: 15
            font.family: Config.sansFont
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            text: root.hasPlayer ? (MediaService.trackArtist || "Unknown Artist") : "No artist"
            color: Colours.fgMid
            font.pixelSize: 13
            font.family: Config.sansFont
            elide: Text.ElideRight
          }

          // Player source badge / multi-player switcher pill on its own row below artist
          Pill {
            id: playerSwitchPill
            readonly property bool canSwitch: root.interactive && Config.mediaAllowPlayerSwitch && MediaService.playerCount > 1
            visible: Config.mediaShowPlayerBadge && root.hasPlayer && MediaService.playerName !== ""
            pillHeight: 17
            padding: 6
            radius: 5
            baseColour: Colours.bgSubtle
            hoverColour: Colours.bgRaised
            hoverHighlight: playerSwitchPill.canSwitch
            clickable: playerSwitchPill.canSwitch
            onClicked: MediaService.cyclePlayer(1)
            onWheel: function(wheel) {
              if (playerSwitchPill.canSwitch) {
                MediaService.cyclePlayer(wheel.angleDelta.y > 0 ? -1 : 1)
              }
            }

            Row {
              anchors.centerIn: parent
              spacing: 4

              Text {
                text: MediaService.playerGlyph
                color: playerSwitchPill.hovered && playerSwitchPill.canSwitch ? Colours.accent : Colours.fgDim
                font.family: Config.monoFont
                font.pixelSize: 10
                anchors.verticalCenter: parent.verticalCenter
              }

              Text {
                text: (Config.mediaAllowPlayerSwitch && MediaService.playerCount > 1)
                  ? (MediaService.playerName + " · " + (MediaService.playerIndex + 1) + "/" + MediaService.playerCount + " 󰁔")
                  : MediaService.playerName
                color: playerSwitchPill.hovered && playerSwitchPill.canSwitch ? Colours.fg : Colours.fgDim
                font.family: Config.sansFont
                font.pixelSize: Config.fontSizeXs
                anchors.verticalCenter: parent.verticalCenter
              }
            }
          }
        }
      }

      // Playback controls
      PlaybackControls {
        Layout.alignment: Qt.AlignVCenter
        canPrevious: MediaService.canGoPrevious
        canNext: MediaService.canGoNext
        isPlaying: MediaService.isPlaying
        onPreviousClicked: MediaService.previous()
        onPlayPauseClicked: MediaService.playPause()
        onNextClicked: MediaService.next()
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
