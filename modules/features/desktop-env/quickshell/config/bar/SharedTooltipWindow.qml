pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import ".."

// One layer window per display that renders the tooltip card. It owns the
// fade-out grace window, screen-edge clamping, and instant swapping between
// adjacent widgets.
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

  // Tooltip under the cursor, and the one still on screen while it fades out.
  property var activeTip: null
  property var shownTip: null
  property bool recentlyActive: false
  property real cardOpacity: 0

  readonly property bool isOpen: root.shownTip !== null
  readonly property bool hovered: tipLoader.item !== null && cardHover.hovered

  onActiveTipChanged: {
    if (activeTip !== null) {
      graceFadeTimer.stop()
      recentTimer.stop()
      fadeTimer.stop()
      shownTip = activeTip
      recentlyActive = true
      cardOpacity = 1
    } else if (!root.hovered) {
      recentTimer.restart()
      fadeTimer.stop()
      graceFadeTimer.restart()
    }
  }

  onHoveredChanged: {
    if (hovered) {
      graceFadeTimer.stop()
      fadeTimer.stop()
      cardOpacity = 1
    } else if (root.activeTip === null) {
      graceFadeTimer.restart()
    }
  }

  readonly property int screenW: screenTarget ? screenTarget.width : 1920
  readonly property int screenH: screenTarget ? screenTarget.height : 1080
  readonly property int cardW: root.shownTip
    ? (root.shownTip.contentWidth > 0 ? root.shownTip.contentWidth : root.shownTip.maxWidth)
    : 1
  readonly property int cardH: (tipLoader.item && tipLoader.item.height > 0)
    ? Math.ceil(tipLoader.item.height)
    : 1

  // The grace window lets the cursor cross the gap to the card without the
  // tooltip flickering closed; the fade timer then releases the card.
  Timer {
    id: graceFadeTimer
    interval: Config.popupGraceMs
    onTriggered: {
      if (root.activeTip === null && !root.hovered) {
        root.cardOpacity = 0
        fadeTimer.restart()
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
      root.shownTip = null
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
    root.activeTip = tooltip
    root.shownTip = tooltip
    root.recentlyActive = true
    root.cardOpacity = 1
  }

  function closeNow() {
    graceFadeTimer.stop()
    fadeTimer.stop()
    root.activeTip = null
    root.cardOpacity = 0
    root.shownTip = null
    root.recentlyActive = false
    Qt.callLater(gc)
  }

  anchors {
    top: true
    bottom: false
    left: root.barSide !== "right"
    right: root.barSide === "right"
  }

  margins {
    top: root.barSide === "top"
      ? (Config.barHeight + Config.spaceSm)
      : Math.round(Math.max(Config.spaceSm, Math.min(tipLoader.targetCentreY - root.cardH / 2, root.screenH - root.cardH - Config.spaceSm)))
    left: root.barSide === "top"
      ? Math.round(Math.max(Config.spaceLg, Math.min(tipLoader.targetCentreX - root.cardW / 2, root.screenW - root.cardW - Config.spaceLg)))
      : (root.barSide === "left" ? root.edgeDistance : 0)
    right: root.barSide === "right" ? root.edgeDistance : 0
  }

  implicitWidth: root.cardW
  implicitHeight: root.cardH

  Loader {
    id: tipLoader
    width: root.cardW
    opacity: root.cardOpacity

    readonly property var src: root.shownTip

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

    HoverHandler {
      id: cardHover
    }

    Component {
      id: defaultCard
      TooltipCard {
        tooltip: root.shownTip
      }
    }
  }
}
