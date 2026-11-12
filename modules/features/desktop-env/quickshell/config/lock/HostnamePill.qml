pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import ".."

// Hostname badge shared by the clustered and split lock screen status layouts.
StatusPill {
  interactive: false
  rowSpacing: 6
  baseColour: Colours.bgRaised
  icon: "󰌾"
  iconColour: Colours.accent
  label: Session.hostname
  labelColour: Colours.fgMid
  labelBold: true
  tooltipEnabled: false
}
