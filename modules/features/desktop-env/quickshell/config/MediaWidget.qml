import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "Utils.js" as Utils

Item {
  id: root

  property PanelWindow sharedWindow: null
  property string uiFont: Config.monoFont
  property bool horizontal: false

  visible: root.hasMedia
  width: root.horizontal ? horizontalMediaRow.implicitWidth + 12 : ((parent && !horizontal) ? parent.width : 38)
  height: root.horizontal ? 24 : mediaLayout.implicitHeight + 8
  anchors.horizontalCenter: (parent && !horizontal) ? parent.horizontalCenter : undefined

  Rectangle {
    id: mediaBg
    anchors.fill: parent
    radius: 4
    color: mediaTooltip.hovered ? Colors.bgRaised : "transparent"
    Behavior on color { ColorAnimation { duration: 100 } }
  }

  // --- Centralized MPRIS State from MediaService ---
  readonly property var mediaPlayer: MediaService.player
  readonly property string mediaText: MediaService.mediaText
  readonly property bool hasMedia: MediaService.hasMedia

  function focusMediaPlayer() {
    MediaService.focusSource()
  }

  // --- UI Layout (Vertical for Sidebar) ---
  Column {
    id: mediaLayout
    visible: !root.horizontal
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
        font.pixelSize: 15
        font.bold: true
        font.family: root.uiFont
      }

      NumberAnimation on rotation {
        loops: Animation.Infinite
        from: 0
        to: 360
        duration: Config.mediaRotationDuration
        running: Config.animateMediaIcon && root.visible && root.mediaPlayer && root.mediaPlayer.isPlaying
      }

    }

    // Position indicator (elapsed / total stacked vertically)
    Column {
      id: positionCol
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 1

      Text {
        id: elapsedLabel
        anchors.horizontalCenter: parent.horizontalCenter
        text: Utils.formatTime(Math.round(MediaService.estimatedPosition))
        color: Colors.fgMid
        font.family: root.uiFont
        font.pixelSize: 11
        horizontalAlignment: Text.AlignHCenter
      }

      Text {
        id: totalLabel
        visible: root.mediaPlayer && MediaService.lastLength > 0
        anchors.horizontalCenter: parent.horizontalCenter
        text: Utils.formatTime(Math.round(MediaService.lastLength))
        color: Colors.fgDim
        font.family: root.uiFont
        font.pixelSize: 11
        horizontalAlignment: Text.AlignHCenter
      }
    }
  }

  // --- UI Layout (Horizontal for Topbar) ---
  Row {
    id: horizontalMediaRow
    visible: root.horizontal
    anchors.centerIn: parent
    spacing: 6

    Item {
      width: 14
      height: 14
      anchors.verticalCenter: parent.verticalCenter

      Text {
        anchors.centerIn: parent
        text: root.mediaPlayer && root.mediaPlayer.isPlaying ? "󰎈" : "󰎆"
        color: root.mediaPlayer && root.mediaPlayer.isPlaying ? Colors.accent : Colors.fgDim
        font.pixelSize: 13
        font.bold: true
        font.family: root.uiFont
      }

      NumberAnimation on rotation {
        loops: Animation.Infinite
        from: 0
        to: 360
        duration: Config.mediaRotationDuration
        running: Config.animateMediaIcon && root.visible && root.mediaPlayer && root.mediaPlayer.isPlaying
      }
    }

    Text {
      text: root.mediaText
      color: Colors.fg
      font.family: Config.sansFont
      font.pixelSize: 12
      elide: Text.ElideRight
      maximumLineCount: 1
      width: Math.min(implicitWidth, 200)
      anchors.verticalCenter: parent.verticalCenter
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
    onHoveredChanged: {
      if (mediaTooltip.hovered) {
        MediaService.barHoverCount++
      } else {
        MediaService.barHoverCount = Math.max(0, MediaService.barHoverCount - 1)
      }
    }
  }

  Component {
    id: mediaPopoverComponent

    Rectangle {
      id: popoverCard
      width: 280
      height: popoverContent.implicitHeight + 24
      radius: Config.popupRadius
      color: Colors.bg
      border.color: Colors.border
      border.width: 1

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        cursorShape: root.mediaPlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: function(mouse) {
          if (mouse.button === Qt.RightButton) {
            root.focusMediaPlayer()
          }
        }
      }

      Column {
        id: popoverContent
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 8

        // Top row: Album Art + Track Details + Playback Buttons (matches CommandCenter)
        RowLayout {
          width: parent.width
          spacing: 12

          // Album Art
          Rectangle {
            width: 48
            height: 48
            radius: 8
            color: Colors.bgSubtle
            border.color: Colors.border
            border.width: 1

            Text {
              visible: !popoverCover.ready
              text: "󰎆"
              color: Colors.fgDim
              font.family: root.uiFont
              font.pixelSize: 22
              font.bold: true
              anchors.centerIn: parent
            }

            RoundedImage {
              id: popoverCover
              anchors.fill: parent
              sourceSize: Qt.size(96, 96)
              radius: 8
              source: (root.mediaPlayer && (root.mediaPlayer.trackTitle || root.mediaPlayer.trackArtUrl)) ? NotificationStore.getCoverArt(
                root.mediaPlayer.trackTitle || "",
                root.mediaPlayer.trackArtist || "",
                root.mediaPlayer.trackArtUrl || ""
              ) : ""
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: root.mediaPlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              onClicked: root.focusMediaPlayer()
            }
          }

          // Track Details
          Item {
            Layout.fillWidth: true
            implicitHeight: trackDetailsCol.implicitHeight

            Column {
              id: trackDetailsCol
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              spacing: 2

              Text {
                width: parent.width
                text: root.mediaPlayer ? root.mediaPlayer.trackTitle : "No Media"
                color: Colors.fg
                font.bold: true
                font.pixelSize: 15
                font.family: Config.sansFont
                elide: Text.ElideRight
              }

              Text {
                width: parent.width
                text: root.mediaPlayer ? (root.mediaPlayer.trackArtist || "Unknown Artist") : ""
                color: Colors.fgMid
                font.pixelSize: 13
                font.family: Config.sansFont
                elide: Text.ElideRight
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: root.mediaPlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              onClicked: root.focusMediaPlayer()
            }
          }

          // Playback Buttons
          PlaybackControls {
            Layout.alignment: Qt.AlignVCenter
            uiFont: root.uiFont
            canPrevious: !!(root.mediaPlayer && root.mediaPlayer.canGoPrevious)
            canNext: !!(root.mediaPlayer && root.mediaPlayer.canGoNext)
            isPlaying: !!(root.mediaPlayer && root.mediaPlayer.isPlaying)
            onPreviousClicked: root.mediaPlayer.previous()
            onPlayPauseClicked: { if (root.mediaPlayer) root.mediaPlayer.isPlaying = !root.mediaPlayer.isPlaying }
            onNextClicked: root.mediaPlayer.next()
          }

          Item { Layout.fillWidth: true }
        }

        // Seekable progress row
        MediaProgressRow {
          width: parent.width
          visible: root.mediaPlayer && MediaService.lastLength > 0
          position: MediaService.estimatedPosition
          length: MediaService.lastLength
          progress: MediaService.progress
          onSeekRequested: function(v) { MediaService.seek(v) }
        }
      }
    }
  }
}
