pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

// Reusable prev / play-pause / next button cluster with hover scaling.
// Used in CommandCentre media card and MediaWidget popover.
RowLayout {
  id: root
  spacing: 6

  property bool canPrevious: false
  property bool canNext: false
  property bool isPlaying: false
  property string uiFont: Config.monoFont

  signal previousClicked()
  signal playPauseClicked()
  signal nextClicked()

  IconButton {
    Layout.alignment: Qt.AlignVCenter
    buttonSize: 28
    radius: 14
    icon: "󰒮"
    uiFont: root.uiFont
    enabled: root.canPrevious
    hoverScale: 0.90
    onClicked: root.previousClicked()
  }

  IconButton {
    Layout.alignment: Qt.AlignVCenter
    buttonSize: 32
    radius: 16
    icon: root.isPlaying ? "󰏤" : "󰐊"
    iconSize: Config.iconSizeLg
    uiFont: root.uiFont
    baseColour: Colours.bgSubtle
    hoverColour: Colours.accent
    borderColour: Colours.border
    hoverBorderColour: Colours.accent
    iconColour: Colours.fg
    hoverIconColour: Colours.bg
    hoverScale: 0.90
    onClicked: root.playPauseClicked()
  }

  IconButton {
    Layout.alignment: Qt.AlignVCenter
    buttonSize: 28
    radius: 14
    icon: "󰒭"
    uiFont: root.uiFont
    enabled: root.canNext
    hoverScale: 0.90
    onClicked: root.nextClicked()
  }
}
