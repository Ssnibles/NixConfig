pragma ComponentBehavior: Bound
import QtQuick
import ".."

// Rounded overlay scrollbar for list views. It only shows while the content
// overflows, so short lists keep their full width. Lists reserve `gutter` on
// the right, which drops to zero with the bar, so row highlights stop before a
// visible bar and nothing is held back when there is none.
//
// Drawn here instead of taken from Qt Quick Controls: the style plugin and its
// QML cost a few megabytes at runtime, which is more than a thumb is worth.
Item {
  id: root

  // The view to track. Keep it in the same parent: the bar positions itself
  // against the view's geometry.
  property Flickable view: null

  readonly property int gutter: root.overflows ? Config.scrollBarWidth + Config.spaceXs : 0

  readonly property bool overflows: root.view !== null
    && root.view.contentHeight + root.view.topMargin + root.view.bottomMargin > root.view.height + 0.5

  // Content that is out of view, in pixels.
  readonly property real _contentSpan: root.view !== null
    ? Math.max(0, root.view.contentHeight + root.view.topMargin + root.view.bottomMargin - root.view.height)
    : 0

  readonly property real _thumbHeight: {
    if (root.view === null || root.view.contentHeight <= 0) return root.height
    var visibleFraction = (root.view.height - root.view.topMargin - root.view.bottomMargin) / root.view.contentHeight
    return Math.max(Config.spaceLg, Math.min(root.height, root.height * visibleFraction))
  }

  readonly property real _maxThumbY: Math.max(0, root.height - root._thumbHeight)

  readonly property real _scrollFraction: {
    if (root.view === null || root._contentSpan <= 0) return 0
    var offset = root.view.contentY - root.view.originY
    return Math.max(0, Math.min(1, offset / root._contentSpan))
  }

  readonly property bool _thumbHovered: drag.containsMouse
    && drag.mouseY >= root._thumbHeightY && drag.mouseY <= root._thumbHeightY + root._thumbHeight

  readonly property real _thumbHeightY: root._scrollFraction * root._maxThumbY

  function _contentYForThumbY(thumbY) {
    if (root.view === null) return 0
    if (root._maxThumbY <= 0) return root.view.originY
    var fraction = Math.max(0, Math.min(1, thumbY / root._maxThumbY))
    return root.view.originY + fraction * root._contentSpan
  }

  width: Config.scrollBarWidth
  // Follow the view's right edge directly: a list that is still being sized
  // would leave a bar placed only once behind.
  x: root.view !== null ? root.view.x + root.view.width - root.width : 0
  y: root.view !== null ? root.view.y + root.view.topMargin : 0
  height: root.view !== null
    ? Math.max(0, root.view.height - root.view.topMargin - root.view.bottomMargin)
    : 0
  visible: root.overflows && root.view.visible

  Rectangle {
    id: thumb

    width: parent.width
    height: root._thumbHeight
    y: root._thumbHeightY
    radius: width / 2
    color: Colours.fgMid
    antialiasing: true

    // The pill keeps one colour; hovering only thickens it into the gutter.
    // It grows from its right edge so it never spills out of the list.
    transform: Scale {
      origin.x: thumb.width
      origin.y: 0
      xScale: root._thumbHovered ? 1.5 : 1
      Behavior on xScale { NumberAnimation { duration: Config.animFastMs; easing.type: Easing.OutCubic } }
    }
  }

  // Dragging maps the pointer to a content offset, so grabbing the middle of
  // the thumb does not jump the list.
  MouseArea {
    id: drag
    anchors.fill: parent
    hoverEnabled: true
    preventStealing: true
    cursorShape: root._thumbHovered ? Qt.PointingHandCursor : Qt.ArrowCursor

    property real grabOffset: 0

    onPressed: function(mouse) {
      if (root.view === null) return
      drag.grabOffset = root._thumbHovered ? (mouse.y - root._thumbHeightY) : (root._thumbHeight / 2)
      root.view.contentY = root._contentYForThumbY(mouse.y - drag.grabOffset)
    }

    onPositionChanged: function(mouse) {
      if (!pressed || root.view === null) return
      root.view.contentY = root._contentYForThumbY(mouse.y - drag.grabOffset)
    }
  }
}
