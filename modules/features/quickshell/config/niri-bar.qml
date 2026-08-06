import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

ShellRoot {
  id: rootShell

  // Global Niri IPC Event Stream Service
  NiriService {
    id: niriService
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: barPanel
      required property var modelData
      screen: barPanel.modelData
      focusable: false
      aboveWindows: true

      anchors { left: true; top: true; bottom: true }
      implicitWidth: 38
      exclusionMode: ExclusionMode.Auto
      color: Colors.bg

      // Thin right border to separate the bar from workspace windows
      Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: Colors.border
      }

      // Bar Content Container
      Item {
        id: barContent
        anchors.fill: parent
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        // Top Section: Clock & Rotated Active Window Title
        Column {
          id: topCol
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          spacing: 12

          ClockWidget {
            id: clockWidget
          }

          WindowTitleWidget {
            id: windowTitleWidget
            titleText: niriService.currentTitle
          }
        }

        // Center Section: Workspaces Indicators
        WorkspacesWidget {
          id: workspacesWidget
          workspaces: niriService.workspacesForOutput(barPanel.modelData.name)
          onFocusRequested: function(workspaceId) {
            niriService.focusWorkspace(workspaceId)
          }
        }

        // Bottom Section: Media, Volume, Network, Battery Widgets
        Column {
          id: bottomCol
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.right: parent.right
          spacing: 12

          MediaWidget {
            id: mediaWidget
            sharedWindow: sharedTipWindow
          }

          VolumeWidget {
            id: volumeWidget
            sharedWindow: sharedTipWindow
          }

          NetworkWidget {
            id: networkWidget
            sharedWindow: sharedTipWindow
          }

          BatteryWidget {
            id: batteryWidget
            sharedWindow: sharedTipWindow
          }
        }
      }

      // Shared Side Tooltip Window Layer
      SharedTooltipWindow {
        id: sharedTipWindow
        screenTarget: barPanel.modelData
      }
    }
  }
}
