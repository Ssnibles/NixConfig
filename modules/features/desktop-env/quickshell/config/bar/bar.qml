pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."

// Unified status bar supporting both horizontal top-bar layouts (MangoWC,
// Hyprland) and vertical side-bar layouts (Niri), powered by WmService.
Scope {
  id: root

  readonly property bool isHorizontal: Session.barType !== "niri"
  readonly property bool sideLeft: !root.isHorizontal && Session.barSide !== "right"
  readonly property bool sideRight: !root.isHorizontal && Session.barSide === "right"

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: barPanel
      required property var modelData
      screen: barPanel.modelData
      visible: Config.barVisible
      focusable: false
      aboveWindows: true

      anchors {
        top: true
        bottom: !root.isHorizontal
        left: root.isHorizontal || root.sideLeft
        right: root.isHorizontal || root.sideRight
      }
      implicitHeight: root.isHorizontal ? Config.barHeight : 0
      implicitWidth: root.isHorizontal ? 0 : Config.barWidth
      exclusionMode: ExclusionMode.Auto
      color: Colours.bg

      // Absorbs every hover and pointer event so the bar never click-throughs
      // to the windows underneath.
      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        onClicked: function(mouse) { mouse.accepted = true }
        onEntered: Config.lastActiveScreen = barPanel.modelData
      }

      // Thin inner border line separating the bar from workspace windows
      Rectangle {
        anchors.top: root.isHorizontal ? undefined : parent.top
        anchors.bottom: parent.bottom
        anchors.left: (root.isHorizontal || root.sideRight) ? parent.left : undefined
        anchors.right: (root.isHorizontal || root.sideLeft) ? parent.right : undefined
        height: root.isHorizontal ? 1 : 0
        width: root.isHorizontal ? 0 : 1
        color: Colours.border
      }

      Item {
        anchors.fill: parent
        anchors.topMargin: root.isHorizontal ? 0 : Config.barMarginTop
        anchors.bottomMargin: root.isHorizontal ? 0 : Config.barMarginBottom
        anchors.leftMargin: root.isHorizontal ? Config.barHorizontalMargin : Config.barMarginLeft
        anchors.rightMargin: root.isHorizontal ? Config.barHorizontalMargin : Config.barMarginRight

        // Start section: left on the top bar, top on the side bar.
        GridLayout {
          flow: root.isHorizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom
          rowSpacing: Config.barSpacing
          columnSpacing: Config.barLeftSpacing
          anchors.left: parent.left
          anchors.right: root.isHorizontal ? undefined : parent.right
          anchors.top: root.isHorizontal ? undefined : parent.top
          anchors.verticalCenter: root.isHorizontal ? parent.verticalCenter : undefined

          ClockWidget {
            horizontal: root.isHorizontal
            sharedWindow: sharedTipWindow
            Layout.alignment: Qt.AlignCenter
          }

          CommandCentreButton {
            horizontal: root.isHorizontal
            screen: barPanel.modelData
            sharedWindow: sharedTipWindow
            Layout.alignment: Qt.AlignCenter
          }

          LayoutWidget {
            horizontal: root.isHorizontal
            screen: barPanel.modelData
            sharedWindow: sharedTipWindow
            Layout.alignment: Qt.AlignCenter
          }

          WindowTitleWidget {
            horizontal: root.isHorizontal
            Layout.alignment: Qt.AlignCenter
          }
        }

        WorkspacesWidget {
          anchors.centerIn: parent
          horizontal: root.isHorizontal
          screen: barPanel.modelData
        }

        // End section: right on the top bar, bottom on the side bar.
        GridLayout {
          flow: root.isHorizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom
          rowSpacing: Config.barSpacing
          columnSpacing: Config.barRightSpacing
          anchors.right: parent.right
          anchors.left: root.isHorizontal ? undefined : parent.left
          anchors.bottom: root.isHorizontal ? undefined : parent.bottom
          anchors.verticalCenter: root.isHorizontal ? parent.verticalCenter : undefined

          SystemTrayWidget {
            horizontal: root.isHorizontal
            sharedWindow: sharedTipWindow
            Layout.alignment: Qt.AlignCenter
          }

          MediaWidget {
            horizontal: root.isHorizontal
            sharedWindow: sharedTipWindow
            Layout.alignment: Qt.AlignCenter
          }

          VolumeWidget {
            horizontal: root.isHorizontal
            sharedWindow: sharedTipWindow
            Layout.alignment: Qt.AlignCenter
          }

          NetworkWidget {
            horizontal: root.isHorizontal
            sharedWindow: sharedTipWindow
            Layout.alignment: Qt.AlignCenter
          }

          BatteryWidget {
            horizontal: root.isHorizontal
            sharedWindow: sharedTipWindow
            Layout.alignment: Qt.AlignCenter
          }
        }
      }

      SharedTooltipWindow {
        id: sharedTipWindow
        screenTarget: barPanel.modelData
        barSide: root.isHorizontal ? "top" : Session.barSide
      }
    }
  }
}
