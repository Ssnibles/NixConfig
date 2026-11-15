pragma ComponentBehavior: Bound
import QtQuick
import ".."

StatusPill {
  id: root

  acceptedButtons: Qt.LeftButton | Qt.RightButton
  onClicked: function(mouse) {
    if (mouse.button === Qt.LeftButton) {
      UiState.openStatusMenu("bluetooth")
    } else {
      BluetoothService.openBluetoothManager()
    }
  }

  // Icon-only in the bar and bento header; the sidebar also shows the label.
  icon: BluetoothService.btIcon
  iconColour: BluetoothService.btColour
  iconSize: root.horizontal ? Config.iconSizeSm : Config.iconSizeLg
  label: BluetoothService.btStatusText
  tooltipEnabled: !root.showLabel
  tooltipTitle: BluetoothService.btTitle
  tooltipDetails: root.interactive ? BluetoothService.btDetails : []
}
