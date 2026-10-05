pragma ComponentBehavior: Bound
import QtQuick

Pill {
  id: root

  property bool horizontal: false
  property var screen: null
  padding: 4
  anchors.horizontalCenter: (parent && !horizontal) ? parent.horizontalCenter : undefined
  pillColour: (hoverArea.containsMouse || Config.commandCentreVisible) ? Colours.bgSubtle : Colours.bgRaised

  Text {
    text: "󰘳" // Dashboard/Control Centre icon
    color: (hoverArea.containsMouse || Config.commandCentreVisible) ? Colours.accent : Colours.fg
    font.family: Config.monoFont
    font.pixelSize: 16
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenter: parent.horizontalCenter
  }

  MouseArea {
    id: hoverArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
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
  }
}
