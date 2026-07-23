import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Scope {
  id: root

  property string currentTime: ""

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      anchors.top: true
      anchors.left: true
      anchors.right: true

      implicitHeight: 32
      color: "#141415"

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        Text {
          text: root.currentTime
          color: "#cdcdcd"
          font.pixelSize: 13
          font.family: "Inter"
          verticalAlignment: Text.AlignVCenter
          Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        Row {
          spacing: 6
          Layout.alignment: Qt.AlignCenter

          Repeater {
            model: 10

            Rectangle {
              width: 28
              height: 24
              radius: 6
              color: {
                var wsId = index + 1;
                if (Hyprland.focusedWorkspace?.id === wsId)
                  return "#6e94b2";
                var exists = false;
                for (var i = 0; i < Hyprland.workspaces.values.length; i++) {
                  if (Hyprland.workspaces.values[i].id === wsId) {
                    exists = true;
                    break;
                  }
                }
                return exists ? "#606079" : "#252530";
              }

              Text {
                anchors.centerIn: parent
                text: index + 1
                color: "#cdcdcd"
                font.pixelSize: 11
                font.family: "Inter"
              }

              MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("workspace " + (index + 1))
              }
            }
          }
        }

        Item { Layout.fillWidth: true }
      }
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.currentTime = Qt.formatDateTime(new Date(), "HH:mm:ss")
  }

  Component.onCompleted: root.currentTime = Qt.formatDateTime(new Date(), "HH:mm:ss")
}
