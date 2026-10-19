pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

Pill {
  id: root

  property PanelWindow sharedWindow: null
  property string uiFont: Config.monoFont
  property int maxTextWidth: Config.wifiMaxTextLength
  // Disable pointer interaction (used on the lock screen, where the pill is
  // purely informational and must not launch nmtui).
  property bool interactive: true

  horizontal: false
  hoverHighlight: root.interactive
  clickable: root.interactive
  acceptedButtons: Qt.LeftButton | Qt.RightButton
  onClicked: SystemService.openNetworkManager()

  Row {
    id: labelRow
    anchors.centerIn: parent
    spacing: 4
    rotation: root.horizontal ? 0 : 270
    transformOrigin: Item.Center

    Text {
      text: SystemService.netIcon
      color: SystemService.netColour
      font.family: root.uiFont
      font.pixelSize: Config.fontSizeSm
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      visible: root.horizontal
      text: root.horizontal ? SystemService.netText : ""
      color: Colours.fg
      font.family: Config.sansFont
      font.pixelSize: Config.fontSizeSm
      elide: Text.ElideRight
      maximumLineCount: 1
      width: Math.min(implicitWidth, root.maxTextWidth)
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  Tooltip {
    id: netTooltip
    target: root
    sharedWindow: root.sharedWindow
    icon: SystemService.netIcon
    iconColour: SystemService.netColour
    title: SystemService.netTitle
    details: SystemService.netDetails
  }
}
