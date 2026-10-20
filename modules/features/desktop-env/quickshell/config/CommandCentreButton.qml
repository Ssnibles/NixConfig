pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

Pill {
  id: root

  property var screen: null
  property PanelWindow sharedWindow: null

  horizontal: false
  padding: 4
  clickable: true
  pillColour: (root.hovered || Config.commandCentreVisible) ? Colours.bgSubtle : Colours.bgRaised

  onClicked: {
    if (Config.commandCentreVisible) {
      Config.commandCentreVisible = false
    } else {
      if (root.screen) {
        Config.targetScreen = root.screen
        Config.lastActiveScreen = root.screen
      }
      Config.commandCentreVisible = true
    }
  }

  Text {
    text: "󰘳" // Dashboard/Control Centre icon
    color: (root.hovered || Config.commandCentreVisible) ? Colours.accent : Colours.fg
    font.family: Config.monoFont
    font.pixelSize: Config.iconSizeMd
    anchors.centerIn: parent
  }

  Tooltip {
    sharedWindow: root.sharedWindow
    icon: "󰘳"
    iconColour: Colours.accent
    title: "Command Centre"
    details: [Config.commandCentreVisible ? "Left click · Close" : "Left click · Open"]
  }
}
