pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

Pill {
  id: root

  property PanelWindow sharedWindow: null
  property string uiFont: Config.monoFont
  property bool showLabel: false

  horizontal: root.showLabel
  hoverHighlight: true
  clickable: true
  acceptedButtons: Qt.LeftButton | Qt.RightButton
  onClicked: function(mouse) {
    if (mouse.button === Qt.LeftButton) {
      SystemService.toggleBluetooth()
    } else {
      SystemService.openBluetoothManager()
    }
  }

  // Bar mode content (centred icon, pixelSize 18)
  Text {
    visible: !root.showLabel
    anchors.centerIn: parent
    text: SystemService.btIcon
    color: SystemService.btColour
    font.family: root.uiFont
    font.pixelSize: Config.iconSizeLg
  }

  // Pill / CommandCentre mode content (icon + text row, matching Wi-Fi & Battery layout)
  Row {
    id: labelRow
    visible: root.showLabel
    anchors.centerIn: parent
    spacing: 4

    Text {
      text: SystemService.btIcon
      color: SystemService.btColour
      font.family: root.uiFont
      font.pixelSize: Config.fontSizeSm
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: root.showLabel ? SystemService.btStatusText : ""
      color: Colours.fg
      font.family: Config.sansFont
      font.pixelSize: Config.fontSizeSm
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  Tooltip {
    id: btTooltip
    visible: !root.showLabel
    target: root
    sharedWindow: root.sharedWindow
    icon: SystemService.btIcon
    iconColour: SystemService.btColour
    title: SystemService.btTitle
    details: SystemService.btDetails
  }
}
