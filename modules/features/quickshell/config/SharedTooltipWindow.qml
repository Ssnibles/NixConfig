import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: root

  property var screenTarget: null
  screen: screenTarget

  property string barSide: "left" // which side the bar is on; popup hugs the other side

  property var _active: null
  property bool recentlyActive: false
  property var cachedActive: null
  property real cardOpacity: 0
  property int _repositionTick: 0

  readonly property bool hovered: tipLoader.item !== null && cardHover.hovered

  on_ActiveChanged: {
    if (_active !== null) {
      cachedActive = _active
      recentlyActive = true
      recentTimer.stop()
      fadeTimer.stop()
      cardOpacity = 1
      repositionTimer.restart()
    } else {
      if (!root.hovered) {
        recentTimer.restart()
        fadeTimer.restart()
        cardOpacity = 0
      }
    }
  }

  onHoveredChanged: {
    if (hovered) {
      recentTimer.stop()
      fadeTimer.stop()
      cardOpacity = 1
    } else {
      if (root._active === null) {
        recentTimer.restart()
        fadeTimer.restart()
        cardOpacity = 0
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

  Timer {
    id: repositionTimer
    interval: 60
    onTriggered: root._repositionTick++
  }

  Behavior on cardOpacity { NumberAnimation { duration: Config.popupFadeMs; easing.type: Easing.OutQuad } }

  visible: cachedActive !== null
  focusable: false
  aboveWindows: true
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  anchors { top: true; bottom: true }
  anchors.left: barSide === "left"
  anchors.right: barSide === "right"
  margins { left: barSide === "left" ? Config.popupGap : 0; right: barSide === "left" ? 0 : Config.popupGap }
  implicitWidth: cachedActive
    ? (cachedActive.contentWidth > 0 ? cachedActive.contentWidth : cachedActive.maxWidth)
    : Config.popupMaxWidth

  // Loads either the default rendered card or a fully custom per-Tooltip
  // component (Tooltip.contentComponent). The Loader owns all shared
  // behaviour: fade opacity, and vertical clamping next to the target widget.
  Loader {
    id: tipLoader
    width: parent.width
    opacity: root.cardOpacity

    HoverHandler {
      id: cardHover
    }

    // The Tooltip instance currently active (null while fading out).
    readonly property var src: root.cachedActive

    // Vertical centre of the widget that opened the popup, in window coords.
    readonly property real targetCenterY: {
      var _ = root._repositionTick
      if (!src || !src.target) return 0
      var p = src.target.mapToItem(null, 0, src.target.height / 2)
      return p ? p.y : 0
    }

    y: {
      var _ = root._repositionTick
      if (!src) return 0
      var h = item ? item.height : 0
      return Math.round(Math.max(6, Math.min(targetCenterY - h / 2, root.height - h - 6)))
    }

    sourceComponent: src ? (src.contentComponent ? src.contentComponent : defaultCard) : null

    // The stock card: icon + title row, divider and plain-text detail lines.
    // Fully custom popups replace this entirely via Tooltip.contentComponent.
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
              font.pixelSize: 16
              anchors.verticalCenter: parent.verticalCenter
            }
            Text {
              text: _src ? _src.title : ""
              color: Colors.fg
              font.family: Config.sansFont
              font.pixelSize: 12
              font.bold: true
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
              font.pixelSize: 11
            }
          }
        }
      }
    }
  }
}