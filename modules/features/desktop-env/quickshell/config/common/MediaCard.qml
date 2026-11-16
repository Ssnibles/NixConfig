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
  // Padding between the card edge and its content. The bento board matches it to
  // the padding of the card that holds it.
  property int contentPadding: Config.spaceLg
  // Fill the card with the artwork and lay the content over it. The bento board
  // uses this, where the card is roughly square.
  property bool coverCard: false

  readonly property bool hasPlayer: MediaService.hasPlayer

  visible: root.showWhenIdle || root.hasPlayer
  implicitHeight: contentCol.implicitHeight + root.contentPadding * 2

  // Full-bleed artwork, masked the same way as the artwork tile. Inset by the
  // border so the card edge stays visible. The size is rounded so a cached
  // decode is reused across openings instead of re-decoding on every layout
  // pass.
  RoundedImage {
    id: coverCardArt
    anchors.fill: parent
    anchors.margins: Config.borderWidth
    visible: root.coverCard && root.hasPlayer && source !== ""
    source: MediaService.artSource
    sourceSize: Qt.size(
      Math.max(256, Math.ceil(root.width / 64) * 64),
      Math.max(256, Math.ceil(root.height / 64) * 64)
    )
    radius: root.cardRadius
  }

  // Dims the bottom of the artwork so the text and controls stay readable over
  // a bright cover.
  Rectangle {
    anchors.fill: coverCardArt
    visible: coverCardArt.visible
    radius: root.cardRadius
    gradient: Gradient {
      GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.25) }
      GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0.5) }
      GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.7) }
    }
  }

  // Keep the position tick alive while the cursor is over the card (covers the
  // bar popover, where the widget's own hover has already ended).
  HoverHandler {
    onHoveredChanged: MediaService.setConsumer("mediaCard-" + String(root), hovered)
  }
  Component.onDestruction: MediaService.setConsumer("mediaCard-" + String(root), false)

  // Card-wide click focuses the player. In cover mode the whole artwork is the
  // target, since the artwork tile is hidden.
  MouseArea {
    anchors.fill: parent
    enabled: root.interactive
    acceptedButtons: root.coverCard ? (Qt.LeftButton | Qt.RightButton) : Qt.RightButton
    cursorShape: root.hasPlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: function(mouse) {
      if (!root.hasPlayer) return
      if (mouse.button === Qt.RightButton || root.coverCard) MediaService.focusSource()
    }
  }

  component ArtTile: CoverArt {
    artSize: root.artSize
    source: root.hasPlayer ? MediaService.artSource : ""

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
    property color titleColour: Colours.fg
    property color detailColour: Colours.fgMid

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
        color: root.hasPlayer ? details.titleColour : Colours.fgDim
        font.bold: true
        font.pixelSize: root.titleSize
        font.family: Session.sansFont
        elide: Text.ElideRight
      }

      Text {
        width: parent.width
        horizontalAlignment: details.centred ? Text.AlignHCenter : Text.AlignLeft
        text: root.hasPlayer ? (MediaService.trackArtist || "Unknown Artist") : "No artist"
        color: details.detailColour
        font.pixelSize: root.detailSize
        font.family: Session.sansFont
        elide: Text.ElideRight
      }

      // Player source badge / multi-player switcher. On a cover card it moves to
      // the top corner of the card instead.
      PlayerBadge {
        x: details.centred ? (parent.width - width) / 2 : 0
      }
    }
  }

  // Player source badge and multi-player switcher. `cover` switches it to the
  // artwork palette and the corner placement.
  component PlayerBadge: Pill {
    id: badge

    property bool cover: false
    readonly property bool canSwitch: root.interactive && Config.mediaAllowPlayerSwitch && MediaService.playerCount > 1
    readonly property color textColour: badge.cover ? MediaColours.palette.detail : Colours.fgDim
    readonly property color hoverTextColour: badge.cover ? MediaColours.palette.text : Colours.fg

    visible: root.coverCard === badge.cover && Config.mediaShowPlayerBadge
      && root.hasPlayer && MediaService.playerName !== ""
    pillHeight: Config.spaceLg + Config.space2xs
    padding: Config.pillPaddingHorizontal
    radius: Config.itemRadiusSm
    baseColour: badge.cover ? MediaColours.palette.pill : Colours.bgSubtle
    hoverColour: badge.cover ? MediaColours.palette.pillStrong : Colours.bgRaised
    borderColour: badge.cover ? MediaColours.palette.pillStrong : Colours.border
    hoverHighlight: badge.canSwitch
    clickable: badge.canSwitch
    onClicked: MediaService.cyclePlayer(1)
    onWheel: function(wheel) {
      if (badge.canSwitch) MediaService.cyclePlayer(wheel.angleDelta.y > 0 ? -1 : 1)
    }

    Row {
      anchors.centerIn: parent
      spacing: Config.spaceSm

      Text {
        text: MediaService.playerGlyph
        color: badge.hovered && badge.canSwitch ? badge.hoverTextColour : badge.textColour
        font.family: Session.monoFont
        font.pixelSize: Config.fontSizeXs
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: (Config.mediaAllowPlayerSwitch && MediaService.playerCount > 1)
          ? (MediaService.playerName + " · " + (MediaService.playerIndex + 1) + "/" + MediaService.playerCount + " 󰁔")
          : MediaService.playerName
        color: badge.hovered && badge.canSwitch ? badge.hoverTextColour : badge.textColour
        font.family: Session.sansFont
        font.pixelSize: Config.fontSizeXs
        anchors.verticalCenter: parent.verticalCenter
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
    anchors.margins: root.contentPadding
    // A cover card anchors its controls to the foot of the card, leaving the
    // artwork the upper part. Other layouts centre them.
    y: root.coverCard
      ? parent.height - height - root.contentPadding
      : (parent.height - height) / 2
    spacing: root.coverCard ? Config.spaceXl : Config.spaceMd

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
      // The details and the transport controls get their own blocks on a cover
      // card instead of sitting directly on top of each other.
      spacing: root.coverCard ? Config.space2xl : Config.spaceLg

      ArtTile {
        visible: !root.coverCard
        anchors.horizontalCenter: parent.horizontalCenter
      }

      TrackDetails {
        width: parent.width
        centred: true
        titleColour: root.coverCard ? MediaColours.palette.text : Colours.fg
        detailColour: root.coverCard ? MediaColours.palette.detail : Colours.fgMid
      }

      Controls {
        visible: root.interactive
        anchors.horizontalCenter: parent.horizontalCenter
        buttonScale: root.coverCard ? 1.5 : 1
        accentColour: root.coverCard ? MediaColours.palette.accent : "transparent"
        onAccentColour: root.coverCard ? MediaColours.palette.onAccent : Colours.bg
        sideIconColour: root.coverCard ? MediaColours.palette.text : Colours.fg
        sideHoverColour: root.coverCard ? MediaColours.palette.pillStrong : Colours.bgSubtle
        sideHoverIconColour: root.coverCard ? MediaColours.palette.accent : Colours.accent
      }
    }

    MediaProgressRow {
      width: parent.width
      // Always present while the card is: hiding it between tracks collapsed
      // the layout, since a new track reports its length a moment later.
      visible: root.hasPlayer || root.showWhenIdle
      live: MediaService.isLive
      playing: MediaService.isPlaying
      fillColour: root.coverCard ? MediaColours.palette.accent : Colours.accent
      trackColour: root.coverCard ? MediaColours.palette.track : Colours.bgSubtle
      labelColour: root.coverCard ? MediaColours.palette.detail : Colours.fgDim
      position: MediaService.estimatedPosition
      length: MediaService.lastLength
      progress: MediaService.progress
      seekable: root.seekable && MediaService.canSeek
      onSeekRequested: function(v) { MediaService.seek(v) }
    }
  }

  // Source badge in the top corner when the artwork fills the card. Declared
  // last so it sits above the card-wide click target.
  PlayerBadge {
    cover: true
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.margins: root.contentPadding
  }
}
