pragma ComponentBehavior: Bound
import QtQuick
import ".."

// Smart rounded pill container used across bars, popovers, and command centre.
Rectangle {
  id: root

  property bool horizontal: true
  property int pillHeight: root.horizontal ? Config.pillHeightHorizontal : Config.pillHeightVertical
  property int padding: root.horizontal ? Config.pillPaddingHorizontal : 0

  property color baseColour: Colours.bgRaised
  property color hoverColour: Colours.bgSubtle
  property bool hoverHighlight: false
  property color pillColour: (root.hoverHighlight && root.hovered) ? root.hoverColour : root.baseColour

  // Optional built-in pointer interaction for pill buttons
  property bool clickable: false
  // Visibility gate: lets the bar hide a widget without overriding the
  // widget's own visibility rules for its other users.
  property bool shown: true
  property int acceptedButtons: Qt.LeftButton
  signal clicked(var mouse)
  signal wheel(var wheel)

  readonly property bool hovered: _hoverHandler.hovered

  visible: root.shown
  color: root.pillColour
  // Default radius is half of the smaller dimension (caps on ends)
  radius: Math.min(width, height) / 2
  antialiasing: true
  clip: true
  border.width: Config.borderWidth
  border.color: Colours.border

  Behavior on color { ColorAnimation { duration: Config.animNormalMs } }
  Behavior on border.color { ColorAnimation { duration: Config.animNormalMs } }

  HoverHandler {
    id: _hoverHandler
  }

  default property alias contentData: contentItem.data

  // Intrinsic visual extent of visible children (ignoring non-layout overlays
  // like MouseArea). Rotated children swap their axes.
  function _maxChildExtent(horizontal) {
    var maxExtent = 0
    var children = contentItem.children
    for (var i = 0; i < children.length; i++) {
      var child = children[i]
      if (child.visible === false || child === _clickArea) continue
      var isRotated = (child.rotation === 90 || child.rotation === 270)
      var extent = horizontal
        ? (isRotated ? child.implicitHeight : child.implicitWidth)
        : (isRotated ? child.implicitWidth : child.implicitHeight)
      if (extent > maxExtent) maxExtent = extent
    }
    return maxExtent
  }

  readonly property real contentWidth: root._maxChildExtent(true)
  readonly property real contentHeight: root._maxChildExtent(false)

  // Automatic implicit dimensions for the horizontal or vertical layout
  implicitWidth: root.horizontal
    ? Math.max(root.contentWidth + root.padding * 2, root.pillHeight)
    : root.pillHeight

  implicitHeight: root.horizontal
    ? root.pillHeight
    : Math.max(root.contentHeight + root.padding * 2, root.pillHeight)

  // Fills the whole pill so overlay MouseAreas/Handlers (including the padding)
  // are interactive; visual children centre themselves within it.
  Item {
    id: contentItem
    anchors.fill: parent

    MouseArea {
      id: _clickArea
      visible: root.clickable
      enabled: root.clickable
      anchors.fill: parent
      cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
      acceptedButtons: root.acceptedButtons
      onClicked: function(mouse) {
        root.clicked(mouse)
      }
      onWheel: function(wheel) {
        root.wheel(wheel)
      }
    }
  }
}
