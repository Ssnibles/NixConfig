pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import ".."

StatusPill {
  id: root

  readonly property bool batPresent: BatteryService.batPresent

  visible: root.batPresent
  horizontal: false
  icon: BatteryService.batIcon
  iconColour: BatteryService.batColour
  iconSize: root.horizontal ? 14 : Config.iconSizeLg
  label: BatteryService.batPct + "%"
  labelColour: BatteryService.batColour
  labelBold: true
  tooltipTitle: BatteryService.batTitle
  tooltipDetails: BatteryService.batDetails
}
