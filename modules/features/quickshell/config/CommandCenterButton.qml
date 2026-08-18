import QtQuick
import Quickshell

Pill {
  id: root

  property bool horizontal: false
  padding: 4
  anchors.horizontalCenter: (parent && !horizontal && parent.toString().indexOf("Row") === -1) ? parent.horizontalCenter : undefined
  pillColor: (hoverArea.containsMouse || Config.commandCenterVisible) ? Colors.bgSubtle : Colors.bgRaised

  Text {
    text: "󰘳" // Dashboard/Control Center icon
    color: (hoverArea.containsMouse || Config.commandCenterVisible) ? Colors.accent : Colors.fg
    font.family: Config.monoFont
    font.pixelSize: 16
    anchors.verticalCenter: parent.verticalCenter
  }

  MouseArea {
    id: hoverArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      Config.commandCenterVisible = !Config.commandCenterVisible
    }
  }
}
