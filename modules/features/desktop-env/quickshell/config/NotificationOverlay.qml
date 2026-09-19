import Quickshell
import Quickshell.Wayland
import QtQuick
import "Utils.js" as Utils

Scope {
  id: root

  property string position: Config.notifPosition

  Variants {
    model: Config.notifAllScreens ? Quickshell.screens : (Quickshell.screens.length > 0 ? [Quickshell.screens[0]] : [])

    PanelWindow {
      id: panel
      required property var modelData
      screen: modelData

      WlrLayershell.layer: WlrLayer.Overlay
      exclusionMode: ExclusionMode.Ignore

      readonly property string pos: (root.position || Config.notifPosition || "top-right").toLowerCase().trim()

      readonly property bool onTop: pos.startsWith("top") || pos === "top"
      readonly property bool onBottom: pos.startsWith("bottom") || pos === "bottom"
      readonly property bool isVertCenter: !onTop && !onBottom

      readonly property bool onLeft: pos.endsWith("left") || pos === "left"
      readonly property bool onRight: pos.endsWith("right") || pos === "right"
      readonly property bool isHorizCenter: !onLeft && !onRight

      anchors {
        top: panel.onTop
        bottom: panel.onBottom
        left: panel.onLeft
        right: panel.onRight
      }

      margins {
        top: panel.onTop ? (Config.hasTopBar ? (Config.barHeight + Config.notifMarginY) : Config.notifMarginY) : 0
        bottom: panel.onBottom ? Config.notifMarginY : 0
        left: panel.onLeft ? (Config.hasLeftBar ? (Config.barWidth + Config.notifMarginX) : Config.notifMarginX) : 0
        right: panel.onRight ? (Config.hasRightBar ? (Config.barWidth + Config.notifMarginX) : Config.notifMarginX) : 0
      }

      implicitWidth: Config.notifWidth + Config.notifCardMargins * 2
      implicitHeight: notifColumn.implicitHeight + Config.notifCardMargins * 2
      color: "transparent"
      visible: NotificationStore.activeModel ? NotificationStore.activeModel.count > 0 : false

      mask: Region { item: notifColumn }

      Column {
        id: notifColumn
        width: parent.width - Config.notifCardMargins * 2
        spacing: Config.notifSpacing

        anchors.margins: Config.notifCardMargins
        anchors.top: panel.onTop ? parent.top : undefined
        anchors.bottom: panel.onBottom ? parent.bottom : undefined
        anchors.verticalCenter: panel.isVertCenter ? parent.verticalCenter : undefined
        anchors.horizontalCenter: parent.horizontalCenter

        add: Transition {
          NumberAnimation { property: "opacity"; from: 0; duration: 250; easing.type: Easing.OutCubic }
          NumberAnimation { property: "scale"; from: 0.8; to: 1.0; duration: 250; easing.type: Easing.OutBack }
        }

        move: Transition {
          NumberAnimation { properties: "x,y"; duration: 250; easing.type: Easing.OutCubic }
        }

        Repeater {
          model: NotificationStore.activeModel

          NotificationCard {
            id: card
            notification: model.notification
            appName: model.appName || ""
            desktopEntry: model.desktopEntry || ""
            summary: model.summary || ""
            body: model.body || ""
            appIcon: model.appIcon || ""
            image: model.image || ""
            urgency: model.urgency !== undefined ? model.urgency : 1
            trackTitle: model.trackTitle || ""
            trackArtist: model.trackArtist || ""
            isMedia: model.isMedia !== undefined ? model.isMedia : false
            timeStr: model.timeStr || ""

            onIsHoveredChanged: {
              if (card.isHovered) {
                NotificationStore.hoveredIndex = index
              } else if (NotificationStore.hoveredIndex === index) {
                NotificationStore.hoveredIndex = -1
              }
            }

            onDismissed: NotificationStore.dismissActiveAt(index, false)
            onActionTriggered: NotificationStore.invokeActionOrFocus(model, index)
          }
        }
      }
    }
  }
}
