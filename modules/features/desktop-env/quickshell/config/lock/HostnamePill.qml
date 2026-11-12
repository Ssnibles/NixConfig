pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import ".."

// Hostname badge shared by the clustered and split lock screen status layouts.
Pill {
  horizontal: true
  clickable: false
  baseColour: Colours.bgRaised
  border.color: Colours.border

  Row {
    anchors.centerIn: parent
    spacing: 6

    Text {
      text: "󰌾"
      color: Colours.accent
      font.family: Config.monoFont
      font.pixelSize: Config.iconSizeSm
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: Quickshell.env("HOSTNAME") || Quickshell.env("HOST") || "NixOS"
      color: Colours.fgMid
      font.family: Config.sansFont
      font.pixelSize: Config.fontSizeSm
      font.bold: true
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}
