import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
  id: rootShell

  // Global Niri IPC Event Stream Service
  NiriService {
    id: niriService
    active: true
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
        left: Config.barSide !== "right"
        right: Config.barSide === "right"
        top: true
        bottom: true
      }
      implicitWidth: Config.barWidth
      exclusionMode: ExclusionMode.Auto
      color: Colors.bg

      mask: Region { item: barPanel.contentItem }

      // Background MouseArea to absorb all hover and pointer events,
      // preventing focus-follows-mouse and clickthrough to windows underneath
      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        onClicked: function(mouse) { mouse.accepted = true }
        onEntered: {
          Config.lastActiveScreen = barPanel.modelData
        }
      }

      // Thin border on the inner edge to separate the bar from workspace windows
      Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: Config.barSide === "right" ? parent.left : undefined
        anchors.right: Config.barSide === "right" ? undefined : parent.right
        width: 1
        color: Colors.border
      }

      // Bar Content Container
      Item {
        id: barContent
        anchors.fill: parent
        anchors.topMargin: Config.barMarginTop
        anchors.bottomMargin: Config.barMarginBottom
        anchors.leftMargin: Config.barMarginLeft
        anchors.rightMargin: Config.barMarginRight

        // Top Section: Clock & Rotated Active Window Title
        Column {
          id: topCol
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          spacing: Config.barSpacing

          ClockWidget {
            id: clockWidget
            sharedWindow: sharedTipWindow
          }

          CommandCenterButton {
            id: commandCenterButton
            screen: barPanel.modelData
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
          spacing: Config.barSpacing

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

      // Shared Tooltip Window Layer (sits on the opposite side of the bar)
      SharedTooltipWindow {
        id: sharedTipWindow
        screenTarget: barPanel.modelData
        barSide: Config.barSide
      }
    }
  }
}
