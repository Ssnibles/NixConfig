pragma ComponentBehavior: Bound
import QtQuick
import ".."

// Volume badge shared by the clustered and split lock screen status layouts.
StatusPill {
  interactive: false
  baseColour: Colours.bgRaised
  border.color: AudioService.muted ? Colours.red : Colours.border
  icon: AudioService.volumeIcon
  iconColour: AudioService.muted ? Colours.red : Colours.accent
  label: AudioService.muted ? "Muted" : (AudioService.volumePercent + "%")
  labelColour: AudioService.muted ? Colours.red : Colours.fg
  labelBold: true
  tooltipEnabled: false
}
