pragma ComponentBehavior: Bound
import QtQuick
import ".."

// Volume badge shared by the clustered and split lock screen status layouts.
Pill {
  horizontal: true
  clickable: false
  baseColour: Colours.bgRaised
  border.color: AudioService.muted ? Colours.red : Colours.border

  Row {
    anchors.centerIn: parent
    spacing: 6

    Text {
      text: AudioService.volumeIcon
      color: AudioService.muted ? Colours.red : Colours.accent
      font.family: Config.monoFont
      font.pixelSize: Config.iconSizeSm
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: AudioService.muted ? "Muted" : (AudioService.volumePercent + "%")
      color: AudioService.muted ? Colours.red : Colours.fgMid
      font.family: Config.sansFont
      font.pixelSize: Config.fontSizeSm
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}
