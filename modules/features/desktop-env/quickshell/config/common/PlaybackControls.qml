pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."

// Reusable prev / play-pause / next button cluster with hover scaling.
// Used in CommandCentre media card and MediaWidget popover.
RowLayout {
  id: root
  spacing: Config.spaceSm

  property bool canPrevious: false
  property bool canNext: false
  property bool isPlaying: false
  property string uiFont: Session.monoFont

  signal previousClicked()
  signal playPauseClicked()
  signal nextClicked()

  IconButton {
    Layout.alignment: Qt.AlignVCenter
    buttonSize: Config.spaceXl + Config.space2xs
    radius: width / 2
    icon: "󰒮"
    uiFont: root.uiFont
    enabled: root.canPrevious
    hoverScale: 1.08
    onClicked: root.previousClicked()
  }

  IconButton {
    Layout.alignment: Qt.AlignVCenter
    buttonSize: Config.spaceXl + Config.spaceSm
    radius: width / 2
    icon: root.isPlaying ? "󰏤" : "󰐊"
    iconSize: Config.iconSizeLg
    uiFont: root.uiFont
    baseColour: Colours.bgSubtle
    hoverColour: Colours.accent
    borderColour: Colours.border
    hoverBorderColour: Colours.accent
    iconColour: Colours.fg
    hoverIconColour: Colours.bg
    hoverScale: 1.08
    onClicked: root.playPauseClicked()
  }

  IconButton {
    Layout.alignment: Qt.AlignVCenter
    buttonSize: Config.spaceXl + Config.space2xs
    radius: width / 2
    icon: "󰒭"
    uiFont: root.uiFont
    enabled: root.canNext
    hoverScale: 1.08
    onClicked: root.nextClicked()
  }
}
