pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."

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
  // Stack the artwork above the track details. The bento board has the height
  // for a hero card; the bar and sidebar layouts keep the horizontal row.
  property bool vertical: false
  // Art and text sizes. The bento board enlarges them for its hero card.
  property int artSize: Config.space3xl
  property int titleSize: Config.fontSizeLg
  property int detailSize: Config.fontSizeMd

  readonly property bool hasPlayer: MediaService.hasPlayer

  visible: root.showWhenIdle || root.hasPlayer
  implicitHeight: contentCol.implicitHeight + Config.spaceLg * 2

  // Keep the position tick alive while the cursor is over the card (covers the
  // bar popover, where the widget's own hover has already ended).
  HoverHandler {
    onHoveredChanged: MediaService.setConsumer("mediaCard-" + String(root), hovered)
  }
  Component.onDestruction: MediaService.setConsumer("mediaCard-" + String(root), false)

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

  component ArtTile: CoverArt {
    artSize: root.artSize
    source: root.hasPlayer ? MediaService.trackArtUrl : ""

    MouseArea {
      anchors.fill: parent
      enabled: root.interactive
      cursorShape: root.hasPlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onClicked: if (root.hasPlayer) MediaService.focusSource()
    }
  }

  component TrackDetails: Item {
    id: details

    property bool centred: false

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
      spacing: Config.space2xs

      Text {
        width: parent.width
        horizontalAlignment: details.centred ? Text.AlignHCenter : Text.AlignLeft
        text: root.hasPlayer ? (MediaService.trackTitle || "Unknown Track") : "Nothing is playing"
        color: root.hasPlayer ? Colours.fg : Colours.fgDim
        font.bold: true
        font.pixelSize: root.titleSize
        font.family: Session.sansFont
        elide: Text.ElideRight
      }

      Text {
        width: parent.width
        horizontalAlignment: details.centred ? Text.AlignHCenter : Text.AlignLeft
        text: root.hasPlayer ? (MediaService.trackArtist || "Unknown Artist") : "No artist"
        color: Colours.fgMid
        font.pixelSize: root.detailSize
        font.family: Session.sansFont
        elide: Text.ElideRight
      }

      // Player source badge / multi-player switcher pill on its own row below artist
      Pill {
        id: playerSwitchPill
        x: details.centred ? (parent.width - width) / 2 : 0
        readonly property bool canSwitch: root.interactive && Config.mediaAllowPlayerSwitch && MediaService.playerCount > 1
        visible: Config.mediaShowPlayerBadge && root.hasPlayer && MediaService.playerName !== ""
        pillHeight: Config.spaceLg + Config.space2xs
        padding: Config.pillPaddingHorizontal
        radius: Config.itemRadiusSm
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
          spacing: Config.spaceSm

          Text {
            text: MediaService.playerGlyph
            color: playerSwitchPill.hovered && playerSwitchPill.canSwitch ? Colours.accent : Colours.fgDim
            font.family: Session.monoFont
            font.pixelSize: Config.fontSizeXs
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            text: (Config.mediaAllowPlayerSwitch && MediaService.playerCount > 1)
              ? (MediaService.playerName + " · " + (MediaService.playerIndex + 1) + "/" + MediaService.playerCount + " 󰁔")
              : MediaService.playerName
            color: playerSwitchPill.hovered && playerSwitchPill.canSwitch ? Colours.fg : Colours.fgDim
            font.family: Session.sansFont
            font.pixelSize: Config.fontSizeXs
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }
    }
  }

  component Controls: PlaybackControls {
    canPrevious: MediaService.canGoPrevious
    canNext: MediaService.canGoNext
    isPlaying: MediaService.isPlaying
    onPreviousClicked: MediaService.previous()
    onPlayPauseClicked: MediaService.playPause()
    onNextClicked: MediaService.next()
  }

  Column {
    id: contentCol
    anchors.left: parent.left
    anchors.right: parent.right
    // Centred so a taller card keeps the content in the middle instead of
    // leaving the space below it.
    anchors.verticalCenter: parent.verticalCenter
    anchors.margins: Config.spaceLg
    spacing: Config.spaceMd

    RowLayout {
      visible: !root.vertical
      width: parent.width
      spacing: Config.spaceMd

      ArtTile {
        Layout.alignment: Qt.AlignVCenter
      }

      TrackDetails {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
      }

      Controls {
        visible: root.interactive
        Layout.alignment: Qt.AlignVCenter
      }
    }

    Column {
      visible: root.vertical
      width: parent.width
      spacing: Config.spaceLg

      ArtTile {
        anchors.horizontalCenter: parent.horizontalCenter
      }

      TrackDetails {
        width: parent.width
        centred: true
      }

      Controls {
        visible: root.interactive
        anchors.horizontalCenter: parent.horizontalCenter
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
