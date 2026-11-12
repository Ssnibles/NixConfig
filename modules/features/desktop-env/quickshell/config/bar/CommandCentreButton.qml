pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import ".."

Pill {
  id: root

  property var screen: null
  property PanelWindow sharedWindow: null

  padding: 4
  clickable: true
  pillColour: (root.hovered || UiState.commandCentreVisible) ? Colours.bgSubtle : Colours.bgRaised

  onClicked: {
    if (UiState.commandCentreVisible) {
      UiState.commandCentreVisible = false
    } else {
      if (root.screen) {
        UiState.targetScreen = root.screen
        UiState.lastActiveScreen = root.screen
      }
      UiState.commandCentreVisible = true
    }
  }

  Text {
    text: "󰘳" // Dashboard/Control Centre icon
    color: (root.hovered || UiState.commandCentreVisible) ? Colours.accent : Colours.fg
    font.family: Session.monoFont
    font.pixelSize: Config.iconSizeMd
    anchors.centerIn: parent
  }

  Tooltip {
    target: root
    sharedWindow: root.sharedWindow
    icon: "󰘳"
    iconColour: Colours.accent
    title: "Command Centre"
    details: [UiState.commandCentreVisible ? "Left click · Close" : "Left click · Open"]
  }
}
