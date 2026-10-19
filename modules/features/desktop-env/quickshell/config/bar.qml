pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import QtQuick.Layouts

// Unified status bar supporting both horizontal top-bar layouts (MangoWC,
// Hyprland) and vertical side-bar layouts (Niri), powered by WmService.
Scope {
  id: root

  property bool barVisible: Config.barVisible
  readonly property bool isHorizontal: Config.barType !== "niri"

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: barPanel
      required property var modelData
      screen: barPanel.modelData
      visible: root.barVisible
      focusable: false
      aboveWindows: true

      anchors {
        top: true
        bottom: !root.isHorizontal
        left: root.isHorizontal || Config.barSide !== "right"
        right: root.isHorizontal || Config.barSide === "right"
      }
      implicitHeight: root.isHorizontal ? Config.barHeight : 0
      implicitWidth: root.isHorizontal ? 0 : Config.barWidth
      exclusionMode: ExclusionMode.Auto
      color: Colours.bg

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

      // Thin inner border line separating the bar from workspace windows
      Rectangle {
        anchors.top: root.isHorizontal ? undefined : parent.top
        anchors.bottom: parent.bottom
        anchors.left: (!root.isHorizontal && Config.barSide !== "right") ? undefined : parent.left
        anchors.right: (!root.isHorizontal && Config.barSide === "right") ? undefined : parent.right
        height: root.isHorizontal ? 1 : 0
        width: root.isHorizontal ? 0 : 1
        color: Colours.border
      }

      // Bar Content Container
      Item {
        id: barContent
        anchors.fill: parent
        anchors.topMargin: root.isHorizontal ? 0 : Config.barMarginTop
        anchors.bottomMargin: root.isHorizontal ? 0 : Config.barMarginBottom
        anchors.leftMargin: root.isHorizontal ? Config.barHorizontalMargin : Config.barMarginLeft
        anchors.rightMargin: root.isHorizontal ? Config.barHorizontalMargin : Config.barMarginRight

        // Start Section (Left on top bar, Top on side bar):
        // Clock, Command Centre Button, Layout Switcher, Active Window Title
        GridLayout {
          id: startSection
          flow: root.isHorizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom
          rowSpacing: Config.barSpacing
          columnSpacing: Config.barLeftSpacing
          anchors.left: parent.left
          anchors.right: root.isHorizontal ? undefined : parent.right
          anchors.top: root.isHorizontal ? undefined : parent.top
          anchors.verticalCenter: root.isHorizontal ? parent.verticalCenter : undefined

          ClockWidget {
            id: clockWidget
            horizontal: root.isHorizontal
            sharedWindow: sharedTipWindow
            Layout.alignment: Qt.AlignCenter
          }

          CommandCentreButton {
            id: commandCentreButton
            horizontal: root.isHorizontal
            screen: barPanel.modelData
            Layout.alignment: Qt.AlignCenter
          }

          LayoutWidget {
            id: layoutWidget
            horizontal: root.isHorizontal
            screen: barPanel.modelData
            sharedWindow: sharedTipWindow
            Layout.alignment: Qt.AlignCenter
          }

          WindowTitleWidget {
            id: windowTitleWidget
            horizontal: root.isHorizontal
            Layout.alignment: Qt.AlignCenter
          }
        }

        // Centre Section: Unified Workspaces Widget
        WorkspacesWidget {
          id: workspacesWidget
          anchors.centerIn: parent
          horizontal: root.isHorizontal
          screen: barPanel.modelData
        }

        // End Section (Right on top bar, Bottom on side bar):
        // System Tray, Media, Volume, Network, Battery Widgets
        GridLayout {
          id: endSection
          flow: root.isHorizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom
          rowSpacing: Config.barSpacing
          columnSpacing: Config.barRightSpacing
          anchors.right: parent.right
          anchors.left: root.isHorizontal ? undefined : parent.left
          anchors.bottom: root.isHorizontal ? undefined : parent.bottom
          anchors.verticalCenter: root.isHorizontal ? parent.verticalCenter : undefined

          SystemTrayWidget {
            id: systemTrayWidget
            horizontal: root.isHorizontal
            sharedWindow: sharedTipWindow
            Layout.alignment: Qt.AlignCenter
          }

          MediaWidget {
            id: mediaWidget
            horizontal: root.isHorizontal
            sharedWindow: sharedTipWindow
            Layout.alignment: Qt.AlignCenter
          }

          VolumeWidget {
            id: volumeWidget
            horizontal: root.isHorizontal
            sharedWindow: sharedTipWindow
            Layout.alignment: Qt.AlignCenter
          }

          NetworkWidget {
            id: networkWidget
            horizontal: root.isHorizontal
            sharedWindow: sharedTipWindow
            Layout.alignment: Qt.AlignCenter
          }

          BatteryWidget {
            id: batteryWidget
            horizontal: root.isHorizontal
            sharedWindow: sharedTipWindow
            Layout.alignment: Qt.AlignCenter
          }
        }
      }

      // Shared Tooltip Window Layer
      SharedTooltipWindow {
        id: sharedTipWindow
        screenTarget: barPanel.modelData
        barSide: root.isHorizontal ? "top" : Config.barSide
      }
    }
  }
}
