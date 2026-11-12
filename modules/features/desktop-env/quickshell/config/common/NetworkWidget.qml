pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import ".."

StatusPill {
  id: root

  property int maxTextWidth: Config.wifiMaxTextLength

  horizontal: false
  acceptedButtons: Qt.LeftButton | Qt.RightButton
  onClicked: NetworkService.openNetworkManager()

  icon: NetworkService.netIcon
  iconColour: NetworkService.netColour
  iconSize: Config.fontSizeSm
  rowRotation: root.horizontal ? 0 : 270
  label: NetworkService.netText
  labelMaxWidth: root.maxTextWidth
  tooltipTitle: NetworkService.netTitle
  tooltipDetails: NetworkService.netDetails
}
