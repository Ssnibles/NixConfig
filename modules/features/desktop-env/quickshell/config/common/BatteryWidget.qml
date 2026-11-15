pragma ComponentBehavior: Bound
import QtQuick
import ".."

StatusPill {
  id: root

  readonly property bool batPresent: BatteryService.batPresent

  visible: root.batPresent && root.shown
  horizontal: false
  icon: BatteryService.batIcon
  iconColour: BatteryService.batColour
  iconSize: root.horizontal ? Config.iconSizeSm : Config.iconSizeLg
  label: BatteryService.batPct + "%"
  labelColour: BatteryService.batColour
  labelBold: true
  tooltipTitle: BatteryService.batTitle
  tooltipDetails: BatteryService.batDetails
}
