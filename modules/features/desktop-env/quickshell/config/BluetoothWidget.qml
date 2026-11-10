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
      BluetoothService.toggleBluetooth()
    } else {
      BluetoothService.openBluetoothManager()
    }
  }

  // Icon-only in the bar, icon plus status label in the Command Centre.
  Row {
    id: labelRow
    anchors.centerIn: parent
    spacing: 4

    Text {
      text: BluetoothService.btIcon
      color: BluetoothService.btColour
      font.family: root.uiFont
      font.pixelSize: root.showLabel ? Config.fontSizeSm : Config.iconSizeLg
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      visible: root.showLabel
      text: root.showLabel ? BluetoothService.btStatusText : ""
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
    icon: BluetoothService.btIcon
    iconColour: BluetoothService.btColour
    title: BluetoothService.btTitle
    details: BluetoothService.btDetails
  }
}
