pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import ".."

StatusPill {
  id: root

  acceptedButtons: Qt.LeftButton | Qt.RightButton
  onClicked: function(mouse) {
    if (mouse.button === Qt.LeftButton) {
      BluetoothService.toggleBluetooth()
    } else {
      BluetoothService.openBluetoothManager()
    }
  }

  // Icon-only in the bar, icon plus status label in the Command Centre.
  icon: BluetoothService.btIcon
  iconColour: BluetoothService.btColour
  iconSize: root.showLabel ? Config.fontSizeSm : Config.iconSizeLg
  label: BluetoothService.btStatusText
  tooltipEnabled: !root.showLabel
  tooltipTitle: BluetoothService.btTitle
  tooltipDetails: BluetoothService.btDetails
}
