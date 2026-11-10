pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "Utils.js" as Utils

// System tray widget (StatusNotifierItem / SNI) supporting both horizontal
// top bars and vertical sidebars. Ingests centralised tray state from
// SystemService so multi-monitor bars share a single event-driven model.
Pill {
  id: root

  property PanelWindow sharedWindow: null

  visible: TrayService.trayHasContent
  padding: 5
  implicitWidth: root.horizontal ? (trayLayout.implicitWidth + root.padding * 2) : 34
  implicitHeight: root.horizontal ? Config.pillHeightHorizontal : (trayLayout.implicitHeight + 10)

  GridLayout {
    id: trayLayout
    anchors.centerIn: parent
    flow: root.horizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom
    rowSpacing: Config.traySpacing
    columnSpacing: Config.traySpacing

    // Expand/collapse button for hidden tray icons (only shown when Config.trayShowExpandButton is true)
    Rectangle {
      visible: Config.trayShowExpandButton && TrayService.trayHiddenCount > 0
      Layout.preferredWidth: 18
      Layout.preferredHeight: Config.trayButtonSize
      width: 18
      height: Config.trayButtonSize
      radius: 4
      color: toggleMouse.containsMouse || Config.trayExpanded ? Colours.bgRaised : "transparent"
      Behavior on color { ColorAnimation { duration: Config.animFastMs } }

      Text {
        anchors.centerIn: parent
        text: root.horizontal
          ? (Config.trayExpanded ? "󰅂" : "󰅁")
          : (Config.trayExpanded ? "󰅃" : "󰅀")
        color: Config.trayExpanded ? Colours.accent : Colours.fgDim
        font.family: Config.monoFont
        font.pixelSize: 12
      }

      MouseArea {
        id: toggleMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Config.trayExpanded = !Config.trayExpanded
      }
    }

    Repeater {
      model: TrayService.trayVisibleItems

      delegate: Rectangle {
        id: trayDelegate
        required property var modelData

        readonly property string itemId: TrayService.trayItemKey(trayDelegate.modelData)
        readonly property bool isHiddenItem: TrayService.isTrayItemHidden(trayDelegate.modelData)
        readonly property string appTitle: {
          if (!trayDelegate.modelData) return "Application"
          return trayDelegate.modelData.tooltipTitle
            || trayDelegate.modelData.title
            || Utils.prettifyAppName(trayDelegate.modelData.id)
            || "Application"
        }
        readonly property bool menuActive: root.sharedWindow !== null && root.sharedWindow.cachedActive === trayTip

        Layout.preferredWidth: Config.trayButtonSize
        Layout.preferredHeight: Config.trayButtonSize
        width: Config.trayButtonSize
        height: Config.trayButtonSize
        radius: 4
        opacity: trayDelegate.isHiddenItem ? 0.55 : 1.0
        color: (trayTip.hovered || trayDelegate.menuActive)
          ? Colours.bgRaised
          : "transparent"
        Behavior on color { ColorAnimation { duration: Config.animFastMs } }

        property var _focusTargets: []

        function focusApp() {
          if (!trayDelegate.modelData) return
          trayTip.closeNow()
          trayDelegate._focusTargets = Utils.goToSource(trayDelegate.modelData)
          if (trayDelegate._focusTargets && trayDelegate._focusTargets.length > 0) {
            WindowFocuser.focus(trayDelegate._focusTargets)
            focusFollowUpTimer.restart()
          }
        }

        Timer {
          id: focusFollowUpTimer
          interval: 180
          repeat: false
          onTriggered: {
            if (trayDelegate._focusTargets && trayDelegate._focusTargets.length > 0) {
              WindowFocuser.focus(trayDelegate._focusTargets)
            }
          }
        }

        Tooltip {
          id: trayTip
          target: trayDelegate
          sharedWindow: root.sharedWindow
          contentWidth: Config.trayMenuWidth
          contentComponent: Component {
            TrayMenu {
              sharedWindow: root.sharedWindow
            }
          }
        }

        IconImage {
          anchors.centerIn: parent
          implicitSize: Config.trayIconSize
          source: trayDelegate.modelData ? trayDelegate.modelData.icon : ""
        }

        MouseArea {
          id: itemMouse
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

          onClicked: function(mouse) {
            if (!trayDelegate.modelData) return
            if (mouse.button === Qt.LeftButton) {
              if (Config.trayLeftClickAction === "menu") {
                trayTip.openNow()
              } else if (Config.trayLeftClickAction === "activate") {
                trayTip.closeNow()
                trayDelegate.modelData.activate()
              } else {
                trayDelegate.focusApp()
              }
            } else if (mouse.button === Qt.RightButton) {
              trayTip.openNow()
            } else if (mouse.button === Qt.MiddleButton) {
              trayDelegate.modelData.secondaryActivate()
            }
          }

          onWheel: function(wheel) {
            if (trayDelegate.modelData) {
              trayDelegate.modelData.scroll(wheel.angleDelta.y, false)
              wheel.accepted = true
            }
          }
        }
      }
    }
  }
}
