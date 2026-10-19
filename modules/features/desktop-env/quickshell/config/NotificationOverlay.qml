pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import QtQuick
import "Utils.js" as Utils

Scope {
  id: root

  readonly property string position: Config.notifPosition

  // Non-all-screens mode: freeze onto the active screen when a toast appears so
  // notifications follow the user without jumping around while they are shown.
  property var _screen: null
  readonly property int activeCount: NotificationService.activeModel.count

  onActiveCountChanged: {
    if (activeCount > 0) {
      if (!root._screen) {
        root._screen = Config.lastActiveScreen || (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
      }
    } else {
      root._screen = null
    }
  }

  readonly property var targetScreens: Utils.resolveOverlayScreens(
    Config.notifAllScreens,
    root.activeCount > 0,
    root._screen,
    Config.lastActiveScreen,
    Quickshell.screens
  )

  Variants {
    model: root.targetScreens

    PanelWindow {
      id: panel
      required property var modelData
      screen: modelData

      WlrLayershell.layer: WlrLayer.Overlay
      exclusionMode: ExclusionMode.Ignore

      readonly property var pos: Utils.parseOverlayPosition(root.position || Config.notifPosition, "top-right")

      anchors {
        top: panel.pos.onTop
        bottom: panel.pos.onBottom
        left: panel.pos.onLeft
        right: panel.pos.onRight
      }

      margins {
        top: panel.pos.onTop ? (Config.hasTopBar ? (Config.barHeight + Config.notifMarginY) : Config.notifMarginY) : 0
        bottom: panel.pos.onBottom ? Config.notifMarginY : 0
        left: panel.pos.onLeft ? (Config.hasLeftBar ? (Config.barWidth + Config.notifMarginX) : Config.notifMarginX) : 0
        right: panel.pos.onRight ? (Config.hasRightBar ? (Config.barWidth + Config.notifMarginX) : Config.notifMarginX) : 0
      }

      implicitWidth: Config.notifWidth + Config.notifCardMargins * 2
      implicitHeight: notifColumn.implicitHeight + Config.notifCardMargins * 2
      color: "transparent"
      visible: root.activeCount > 0

      mask: Region { item: notifColumn }

      Column {
        id: notifColumn
        width: parent.width - Config.notifCardMargins * 2
        spacing: Config.notifSpacing

        anchors.margins: Config.notifCardMargins
        anchors.top: panel.pos.onTop ? parent.top : undefined
        anchors.bottom: panel.pos.onBottom ? parent.bottom : undefined
        anchors.verticalCenter: panel.pos.isVertCentre ? parent.verticalCenter : undefined
        anchors.horizontalCenter: parent.horizontalCenter

        add: Transition {
          NumberAnimation { property: "opacity"; from: 0; duration: 250; easing.type: Easing.OutCubic }
          NumberAnimation { property: "scale"; from: 0.8; to: 1.0; duration: 250; easing.type: Easing.OutBack }
        }

        move: Transition {
          NumberAnimation { properties: "x,y"; duration: 250; easing.type: Easing.OutCubic }
        }

        Repeater {
          model: NotificationService.activeModel
          delegate: NotificationCard {}
        }
      }
    }
  }
}
