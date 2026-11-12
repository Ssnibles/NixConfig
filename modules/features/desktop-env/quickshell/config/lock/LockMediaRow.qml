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

    Rectangle {
      Layout.preferredWidth: 40
      Layout.preferredHeight: 40
      Layout.alignment: Qt.AlignVCenter
      radius: Config.itemRadiusSm
      color: Colours.bgSubtle
      border.color: Colours.border
      border.width: Config.borderWidth

      Text {
        visible: !coverArt.ready
        text: "󰎇"
        color: Colours.fgDim
        font.family: Session.monoFont
        font.pixelSize: 18
        font.bold: true
        anchors.centerIn: parent
      }

      RoundedImage {
        id: coverArt
        anchors.fill: parent
        sourceSize: Qt.size(80, 80)
        radius: Config.itemRadiusSm
        source: MediaService.trackArtUrl
      }
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
        font.pixelSize: Config.fontSizeSm
        font.bold: true
        elide: Text.ElideRight
        maximumLineCount: 1
      }

      Text {
        Layout.fillWidth: true
        text: MediaService.trackArtist || "Unknown Artist"
        color: Colours.fgMid
        font.family: Session.sansFont
        font.pixelSize: Config.fontSizeXs
        elide: Text.ElideRight
        maximumLineCount: 1
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
