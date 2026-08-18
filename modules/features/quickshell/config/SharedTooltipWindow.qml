import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: root

  property var screenTarget: null
  screen: screenTarget

  property string barSide: "left" // "left" | "right" | "top"

  property var _active: null
  property bool recentlyActive: false
  property var cachedActive: null
  property real cardOpacity: 0

  readonly property bool hovered: tipLoader.item !== null && cardHover.hovered

  on_ActiveChanged: {
    if (_active !== null) {
      cachedActive = _active
      recentlyActive = true
      recentTimer.stop()
      fadeTimer.stop()
      cardOpacity = 1
    } else {
      if (!root.hovered) {
        recentTimer.restart()
        fadeTimer.stop()
        graceFadeTimer.restart()
      }
    }
  }

  Timer {
    id: graceFadeTimer
    interval: Config.popupGraceMs
    onTriggered: {
      if (root._active === null && !root.hovered) {
        cardOpacity = 0
        fadeTimer.restart()
      }
    }
  }

  onHoveredChanged: {
    if (hovered) {
      graceFadeTimer.stop()
      fadeTimer.stop()
      cardOpacity = 1
    } else {
      if (root._active === null) {
        graceFadeTimer.restart()
      }
    }
  }

  Timer {
    id: recentTimer
    interval: Config.popupGraceMs
    onTriggered: root.recentlyActive = false
  }

  Timer {
    id: fadeTimer
    interval: Config.popupFadeMs
    onTriggered: {
      root.cachedActive = null
    }
  }

  Behavior on cardOpacity { NumberAnimation { duration: Config.popupFadeMs; easing.type: Easing.OutQuad } }

  visible: cachedActive !== null
  focusable: false
  aboveWindows: true
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  mask: Region { item: tipLoader.item }

  anchors {
    top: true
    bottom: barSide !== "top"
    left: barSide !== "right"
    right: barSide !== "left"
  }
  margins {
    top: barSide === "top" ? (Config.barHeight + 6) : 0
    left: barSide === "left" ? Config.popupGap : 0
    right: barSide === "right" ? Config.popupGap : 0
  }
  implicitWidth: barSide === "top" ? (screenTarget ? screenTarget.width : 1920) : (cachedActive
    ? (cachedActive.contentWidth > 0 ? cachedActive.contentWidth : cachedActive.maxWidth)
    : Config.popupMaxWidth)
  implicitHeight: barSide === "top" ? 300 : (screenTarget ? screenTarget.height : 1080)

  Loader {
    id: tipLoader
    width: cachedActive ? (cachedActive.contentWidth > 0 ? cachedActive.contentWidth : cachedActive.maxWidth) : Config.popupMaxWidth
    opacity: root.cardOpacity

    HoverHandler {
      id: cardHover
    }

    readonly property var src: root.cachedActive

    readonly property real targetCenterY: {
      if (!src || !src.target) return 0
      var p = src.target.mapToItem(null, 0, src.target.height / 2)
      return p ? p.y : 0
    }

    readonly property real targetCenterX: {
      if (!src || !src.target) return 0
      var p = src.target.mapToItem(null, src.target.width / 2, 0)
      return p ? p.x : 0
    }

    x: {
      if (barSide !== "top") return 0
      if (!src) return 0
      var w = item ? item.width : Config.popupMaxWidth
      return Math.round(Math.max(12, Math.min(targetCenterX - w / 2, root.width - w - 12)))
    }

    y: {
      if (barSide === "top") return 0
      if (!src) return 0
      var h = item ? item.height : 0
      return Math.round(Math.max(6, Math.min(targetCenterY - h / 2, root.height - h - 6)))
    }

    sourceComponent: src ? (src.contentComponent ? src.contentComponent : defaultCard) : null

    Component {
      id: defaultCard
      Rectangle {
        id: card
        width: parent ? parent.width : 0
        height: content.implicitHeight + Config.popupContentMargins * 2
        radius: Config.popupRadius
        color: Colors.bg
        antialiasing: true
        border.width: 1
        border.color: Colors.border

        property var _src: root.cachedActive

        Column {
          id: content
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: Config.popupContentMargins
          spacing: Config.popupContentSpacing

          Row {
            spacing: 8
            Text {
              text: _src ? _src.icon : ""
              color: _src ? _src.iconColor : Colors.fg
              font.family: Config.monoFont
              font.pixelSize: 19
              anchors.verticalCenter: parent.verticalCenter
            }
            Text {
              text: _src ? _src.title : ""
              color: Colors.fg
              font.family: Config.sansFont
              font.pixelSize: 15
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          Rectangle {
            visible: _src ? _src.details.length > 0 : false
            width: parent.width
            height: 1
            color: Colors.border
          }

          Repeater {
            model: _src ? _src.details : []
            delegate: Text {
              required property var modelData
              text: modelData
              color: Colors.fgMid
              font.family: Config.sansFont
              font.pixelSize: 13
            }
          }
        }
      }
    }
  }
}