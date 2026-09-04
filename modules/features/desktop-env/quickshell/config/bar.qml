import Quickshell
import Quickshell.Wayland
import QtQuick

Scope {
  id: root

  // Unified Window Manager Service
  WmService {
    id: rootWmService
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: barPanel
      required property var modelData
      screen: barPanel.modelData
      focusable: false
      aboveWindows: true

      anchors {
        top: true
        left: true
        right: true
      }
      implicitHeight: Config.barHeight
      exclusionMode: ExclusionMode.Auto
      color: Colors.bg

      mask: Region { item: barPanel.contentItem }

      // Background MouseArea to absorb all hover and pointer events
      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        onClicked: function(mouse) { mouse.accepted = true }
        onEntered: {
          Config.lastActiveScreen = barPanel.modelData
        }
      }

      // Thin bottom border line
      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Colors.border
      }

      // Bar Content Container
      Item {
        id: barContent
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        // Left Section: Clock, Command Center Button, Window Title
        Row {
          id: leftRow
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: 12

          ClockWidget {
            id: clockWidget
            horizontal: true
            sharedWindow: sharedTipWindow
          }

          CommandCenterButton {
            id: commandCenterButton
            horizontal: true
            screen: barPanel.modelData
            anchors.verticalCenter: parent.verticalCenter
          }

          LayoutWidget {
            id: layoutWidget
            wmService: rootWmService
            sharedWindow: sharedTipWindow
            horizontal: true
            anchors.verticalCenter: parent.verticalCenter
          }

          Pill {
            id: windowTitlePill
            visible: rootWmService.currentTitle !== ""
            anchors.verticalCenter: parent.verticalCenter
            pillHeight: 24
            padding: 10
            pillColor: Colors.bgRaised
            clip: true

            Behavior on width {
              NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            WindowTitleWidget {
              id: windowTitleWidget
              horizontal: true
              titleText: rootWmService.currentTitle
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }

        // Center Section: Unified Workspaces Widget
        WorkspacesWidget {
          id: workspacesWidget
          horizontal: true
          workspaces: rootWmService.getWorkspaces(barPanel.modelData.name)
          onFocusRequested: function(workspaceId) {
            rootWmService.focusWorkspace(workspaceId)
          }
        }

        // Right Section: Media, Volume, Network, Battery Widgets
        Row {
          id: rightRow
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: 10

          MediaWidget {
            id: mediaWidget
            horizontal: true
            anchors.verticalCenter: parent.verticalCenter
            sharedWindow: sharedTipWindow
          }

          VolumeWidget {
            id: volumeWidget
            horizontal: true
            anchors.verticalCenter: parent.verticalCenter
            sharedWindow: sharedTipWindow
          }

          NetworkWidget {
            id: networkWidget
            horizontal: true
            anchors.verticalCenter: parent.verticalCenter
            sharedWindow: sharedTipWindow
          }

          BatteryWidget {
            id: batteryWidget
            horizontal: true
            anchors.verticalCenter: parent.verticalCenter
            sharedWindow: sharedTipWindow
          }
        }
      }

      // Shared Tooltip Window Layer
      SharedTooltipWindow {
        id: sharedTipWindow
        screenTarget: barPanel.modelData
        barSide: "top"
      }
    }
  }
}
