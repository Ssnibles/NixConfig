pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."

// Compact now-playing row for the lock screen. It shows enough to identify the
// track and control playback without adding another large card.
Item {
  id: root

  readonly property bool hasMedia: MediaService.hasPlayer
    && (MediaService.isPlaying || MediaService.trackTitle !== "")

  implicitHeight: content.implicitHeight

  RowLayout {
    id: content
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    spacing: Config.spaceMd

    CoverArt {
      Layout.alignment: Qt.AlignVCenter
      artSize: Config.space2xl
      glyphSize: Config.iconSizeLg
      source: MediaService.trackArtUrl
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      spacing: Config.space2xs

      Text {
        Layout.fillWidth: true
        text: MediaService.trackTitle || "Unknown Track"
        color: Colours.fg
        font.family: Session.sansFont
        font.pixelSize: Config.fontSizeMd
        font.bold: true
        elide: Text.ElideRight
        maximumLineCount: 1
      }

      Text {
        Layout.fillWidth: true
        text: MediaService.trackArtist || "Unknown Artist"
        color: Colours.fgMid
        font.family: Session.sansFont
        font.pixelSize: Config.fontSizeSm
        elide: Text.ElideRight
        maximumLineCount: 1
      }

      Item {
        Layout.fillWidth: true
        Layout.preferredHeight: Config.space2xs
        visible: MediaService.lastLength > 0 && !MediaService.isLive

        Rectangle {
          anchors.fill: parent
          radius: height / 2
          color: Colours.bgSubtle
        }

        Rectangle {
          width: parent.width * Math.max(0, Math.min(1, MediaService.progress))
          height: parent.height
          radius: height / 2
          color: Colours.accent
        }
      }
    }

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
}
