pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

// Shared row of system power actions used by the Command Centre and the lock
// screen. Emits `activated` after launching the command so callers can react
// (e.g. hide the Command Centre).
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
      m.push({ icon: "󰌾", label: "Lock", cmd: Config.cmdLock, hoverColour: Colours.accent })
    }
    m.push({ icon: "󰤄", label: "Sleep", cmd: Config.cmdSleep, hoverColour: Colours.accent })
    m.push({ icon: "󰜉", label: "Reboot", cmd: Config.cmdReboot, hoverColour: Colours.orange })
    m.push({ icon: "󰐥", label: "Power", cmd: Config.cmdPoweroff, hoverColour: Colours.red })
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
      color: hoverArea.containsMouse ? Colours.bgSubtle : Colours.bgRaised
      border.color: hoverArea.containsMouse ? buttonDelegate.modelData.hoverColour : Colours.border
      border.width: 1
      scale: hoverArea.containsMouse ? 0.94 : 1.0

      Behavior on scale { NumberAnimation { duration: Config.animFastMs } }
      Behavior on color { ColorAnimation { duration: Config.animFastMs } }
      Behavior on border.color { ColorAnimation { duration: Config.animFastMs } }

      MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
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
          color: hoverArea.containsMouse ? buttonDelegate.modelData.hoverColour : Colours.fg
          font.family: Session.monoFont
          font.pixelSize: 18
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: buttonDelegate.modelData.label
          color: hoverArea.containsMouse ? Colours.fg : Colours.fgMid
          font.family: Session.sansFont
          font.pixelSize: 13
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }
}
