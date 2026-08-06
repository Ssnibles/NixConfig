import Quickshell
import Quickshell.Wayland
import QtQuick
import "Utils.js" as Utils

Scope {
  id: root

  property string position: Config.notifPosition

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel
      required property var modelData
      screen: modelData

      readonly property bool onTop: root.position.indexOf("top") !== -1
      readonly property bool onLeft: root.position.indexOf("left") !== -1

      anchors.top: onTop
      anchors.bottom: onTop ? false : true
      anchors.left: onLeft
      anchors.right: onLeft ? false : true

      implicitWidth: Config.notifWidth + Config.notifCardMargins * 2
      implicitHeight: notifList.contentHeight + Config.notifCardMargins * 2
      color: "transparent"

      ListView {
        id: notifList
        width: parent.width - Config.notifCardMargins * 2
        height: contentHeight
        spacing: Config.notifSpacing
        interactive: false
        model: NotificationStore.activeModel

        anchors.margins: Config.notifCardMargins
        anchors.top: panel.onTop ? parent.top : undefined
        anchors.bottom: panel.onTop ? undefined : parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        add: Transition {
          NumberAnimation { property: "opacity"; from: 0; duration: 250; easing.type: Easing.OutCubic }
          NumberAnimation { property: "scale"; from: 0.8; to: 1.0; duration: 250; easing.type: Easing.OutBack }
        }

        remove: Transition {
          NumberAnimation { property: "opacity"; to: 0; duration: 200; easing.type: Easing.OutCubic }
          NumberAnimation { property: "scale"; to: 0.8; duration: 200; easing.type: Easing.OutCubic }
        }

        displaced: Transition {
          NumberAnimation { properties: "y"; duration: 250; easing.type: Easing.OutCubic }
        }

        delegate: NotificationCard {
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