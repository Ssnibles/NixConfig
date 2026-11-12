pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import ".."

Pill {
  id: root

  property PanelWindow sharedWindow: null
  property string uiFont: Config.monoFont
  // Disable pointer interaction (used on the lock screen, where the pill is
  // purely informational).
  property bool interactive: true

  readonly property bool batPresent: BatteryService.batPresent

  visible: root.batPresent
  horizontal: false
  hoverHighlight: root.interactive
  clickable: root.interactive

  Tooltip {
    id: batTooltip
    target: root
    sharedWindow: root.sharedWindow
    icon: BatteryService.batIcon
    iconColour: BatteryService.batColour
    title: BatteryService.batTitle
    details: BatteryService.batDetails
  }

  Row {
    anchors.centerIn: parent
    spacing: 4

    Text {
      text: BatteryService.batIcon
      color: BatteryService.batColour
      font.family: root.uiFont
      font.pixelSize: root.horizontal ? 14 : Config.iconSizeLg
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      visible: root.horizontal
      text: root.horizontal ? (BatteryService.batPct + "%") : ""
      color: BatteryService.batColour
      font.family: Config.sansFont
      font.pixelSize: Config.fontSizeSm
      font.bold: true
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}
