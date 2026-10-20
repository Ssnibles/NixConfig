pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

PanelWindow {
  id: root

  property var screenTarget: null
  screen: screenTarget

  property string barSide: "left" // "left" | "right" | "top"

  // Distance from the anchored screen edge. A negative value keeps the default
  // bar gap; set it to park the tooltip next to something that is not a bar
  // (e.g. just outside the command centre card).
  property int edgeOffset: -1
  readonly property int edgeDistance: root.edgeOffset >= 0 ? root.edgeOffset : Config.popupGap

  property var _active: null
  property bool recentlyActive: false
  property var cachedActive: null
  // True while a tooltip (or its custom content) is on screen.
  readonly property bool isOpen: root.cachedActive !== null
  property real cardOpacity: 0

  readonly property bool hovered: tipLoader.item !== null && cardHover.hovered

  on_ActiveChanged: {
    if (_active !== null) {
      graceFadeTimer.stop()
      recentTimer.stop()
      fadeTimer.stop()
      cachedActive = _active
      recentlyActive = true
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
        root.cardOpacity = 0
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
      Qt.callLater(gc)
    }
  }

  Behavior on cardOpacity { NumberAnimation { duration: Config.popupFadeMs; easing.type: Easing.OutQuad } }

  visible: root.isOpen
  focusable: false
  aboveWindows: true
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  mask: Region { item: tipLoader.item }

  function openNow(tooltip) {
    graceFadeTimer.stop()
    recentTimer.stop()
    fadeTimer.stop()
    root._active = tooltip
    root.cachedActive = tooltip
    root.recentlyActive = true
    root.cardOpacity = 1
  }

  function closeNow() {
    graceFadeTimer.stop()
    fadeTimer.stop()
    root._active = null
    root.cardOpacity = 0
    root.cachedActive = null
    root.recentlyActive = false
    Qt.callLater(gc)
  }

  readonly property int screenW: screenTarget ? screenTarget.width : 1920
  readonly property int screenH: screenTarget ? screenTarget.height : 1080
  readonly property int cardW: root.cachedActive
    ? (root.cachedActive.contentWidth > 0 ? root.cachedActive.contentWidth : root.cachedActive.maxWidth)
    : 1
  readonly property int cardH: (tipLoader.item && tipLoader.item.height > 0)
    ? Math.ceil(tipLoader.item.height)
    : 1

  anchors {
    top: true
    bottom: false
    left: root.barSide !== "right"
    right: root.barSide === "right"
  }
  margins {
    top: root.barSide === "top"
      ? (Config.barHeight + 6)
      : Math.round(Math.max(6, Math.min(tipLoader.targetCentreY - root.cardH / 2, root.screenH - root.cardH - 6)))
    left: root.barSide === "top"
      ? Math.round(Math.max(12, Math.min(tipLoader.targetCentreX - root.cardW / 2, root.screenW - root.cardW - 12)))
      : (root.barSide === "left" ? root.edgeDistance : 0)
    right: root.barSide === "right" ? root.edgeDistance : 0
  }
  implicitWidth: root.cardW
  implicitHeight: root.cardH

  Loader {
    id: tipLoader
    width: root.cardW
    opacity: root.cardOpacity

    HoverHandler {
      id: cardHover
    }

    readonly property var src: root.cachedActive

    readonly property real targetCentreY: {
      if (!src || !src.target) return 0
      var p = src.target.mapToItem(null, 0, src.target.height / 2)
      return p ? p.y : 0
    }

    readonly property real targetCentreX: {
      if (!src || !src.target) return 0
      var p = src.target.mapToItem(null, src.target.width / 2, 0)
      return p ? p.x : 0
    }

    sourceComponent: src ? (src.contentComponent ? src.contentComponent : defaultCard) : null

    Component {
      id: defaultCard
      Card {
        id: card
        width: parent ? parent.width : 0
        height: content.implicitHeight + Config.popupContentMargins * 2
        cardRadius: Config.popupRadius
        cardColour: Colours.bg

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
              text: card._src ? card._src.icon : ""
              color: card._src ? card._src.iconColour : Colours.fg
              font.family: Config.monoFont
              font.pixelSize: 19
              anchors.verticalCenter: parent.verticalCenter
            }
            Text {
              text: card._src ? card._src.title : ""
              color: Colours.fg
              font.family: Config.sansFont
              font.pixelSize: Config.fontSizeLg
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          Rectangle {
            visible: card._src ? card._src.details.length > 0 : false
            width: parent.width
            height: 1
            color: Colours.border
          }

          Repeater {
            model: card._src ? card._src.details : []
            delegate: Text {
              required property var modelData
              text: modelData
              color: Colours.fgMid
              font.family: Config.sansFont
              font.pixelSize: Config.fontSizeMd
            }
          }
        }
      }
    }
  }
}