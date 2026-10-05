pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import QtQuick

Scope {
  id: root

  readonly property string position: Config.notifPosition

  // Non-all-screens mode: freeze onto the active screen when a toast appears so
  // notifications follow the user without jumping around while they are shown.
  property var _screen: null
  readonly property int activeCount: NotificationStore.activeModel ? NotificationStore.activeModel.count : 0

  onActiveCountChanged: {
    if (activeCount > 0) {
      if (!root._screen) {
        root._screen = Config.lastActiveScreen || (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
      }
    } else {
      root._screen = null
    }
  }

  readonly property var targetScreens: {
    if (Config.notifAllScreens) return Quickshell.screens
    if (activeCount === 0) return []
    var screens = Quickshell.screens || []
    var s = root._screen || Config.lastActiveScreen || (screens.length > 0 ? screens[0] : null)
    // If the frozen screen was disconnected, fall back to the first available
    // screen instead of rendering onto a dead reference.
    if (s && screens.length > 0) {
      var found = false
      for (var i = 0; i < screens.length; i++) {
        if (screens[i] === s) { found = true; break }
      }
      if (!found) s = screens[0]
    }
    return s ? [s] : []
  }

  Variants {
    model: root.targetScreens

    PanelWindow {
      id: panel
      required property var modelData
      screen: modelData

      WlrLayershell.layer: WlrLayer.Overlay
      exclusionMode: ExclusionMode.Ignore

      readonly property string pos: (root.position || Config.notifPosition || "top-right").toLowerCase().trim()

      readonly property bool onTop: pos.startsWith("top") || pos === "top"
      readonly property bool onBottom: pos.startsWith("bottom") || pos === "bottom"
      readonly property bool isVertCentre: !onTop && !onBottom

      readonly property bool onLeft: pos.endsWith("left") || pos === "left"
      readonly property bool onRight: pos.endsWith("right") || pos === "right"
      readonly property bool isHorizCentre: !onLeft && !onRight

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
        anchors.verticalCenter: panel.isVertCentre ? parent.verticalCenter : undefined
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
            required property var model
            required property int index
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

            onIsHoveredChanged: NotificationStore.setHovered(model.uid, card.isHovered)
            Component.onDestruction: NotificationStore.setHovered(model.uid, false)

            onDismissed: NotificationStore.dismissActiveAt(index, false)
            onActionTriggered: NotificationStore.invokeActionOrFocus(model, index)
          }
        }
      }
    }
  }
}
