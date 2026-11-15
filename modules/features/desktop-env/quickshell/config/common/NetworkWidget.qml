pragma ComponentBehavior: Bound
import QtQuick
import ".."

StatusPill {
  id: root

  property int maxTextWidth: Config.wifiMaxTextLength

  horizontal: false
  acceptedButtons: Qt.LeftButton | Qt.RightButton
  onClicked: function(mouse) {
    if (mouse.button === Qt.RightButton) NetworkService.openNetworkManager()
    else UiState.openStatusMenu("network")
  }

  icon: NetworkService.netIcon
  iconColour: NetworkService.netColour
  iconSize: root.horizontal ? Config.iconSizeSm : Config.iconSizeLg
  rowRotation: root.horizontal ? 0 : 270
  label: NetworkService.netText
  labelMaxWidth: root.maxTextWidth
  tooltipTitle: NetworkService.netTitle
  tooltipDetails: root.interactive ? NetworkService.netDetails : []
}
