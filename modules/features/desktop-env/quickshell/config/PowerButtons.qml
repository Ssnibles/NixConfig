pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell

// Shared row of system power actions used by the Command Center and the lock
// screen. Emits `activated` after launching the command so callers can react
// (e.g. hide the Command Center).
RowLayout {
  id: root

  // The lock screen omits the Lock action (it is already locked).
  property bool showLock: true
  property real buttonRadius: 10
  signal activated()

  spacing: 10

  readonly property var buttonModel: {
    var m = []
    if (root.showLock) {
      m.push({ icon: "󰌾", label: "Lock", cmd: Config.cmdLock, hoverCol: Colors.accent })
    }
    m.push({ icon: "󰤄", label: "Sleep", cmd: Config.cmdSleep, hoverCol: Colors.accent })
    m.push({ icon: "󰜉", label: "Reboot", cmd: Config.cmdReboot, hoverCol: Colors.orange })
    m.push({ icon: "󰐥", label: "Power", cmd: Config.cmdPoweroff, hoverCol: Colors.red })
    return m
  }

  Repeater {
    model: root.buttonModel

    delegate: Rectangle {
      id: buttonDelegate
      required property var modelData
      Layout.fillWidth: true
      Layout.preferredWidth: 1
      height: 48
      radius: root.buttonRadius
      color: hoverArea.containsMouse ? Colors.bgSubtle : Colors.bgRaised
      border.color: hoverArea.containsMouse ? modelData.hoverCol : Colors.border
      border.width: 1
      Behavior on scale { NumberAnimation { duration: 100 } }

      MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: parent.scale = 0.94
        onExited: parent.scale = 1.0
        onClicked: {
          Quickshell.execDetached(buttonDelegate.modelData.cmd)
          root.activated()
        }
      }

      Row {
        anchors.centerIn: parent
        spacing: 6

        Text {
          text: buttonDelegate.modelData.icon
          color: hoverArea.containsMouse ? buttonDelegate.modelData.hoverCol : Colors.fg
          font.family: Config.monoFont
          font.pixelSize: 18
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: buttonDelegate.modelData.label
          color: hoverArea.containsMouse ? Colors.fg : Colors.fgMid
          font.family: Config.sansFont
          font.pixelSize: 13
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }
}
