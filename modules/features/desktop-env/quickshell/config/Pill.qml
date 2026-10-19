pragma ComponentBehavior: Bound
import QtQuick

// Smart rounded pill container used across bars, popovers, and command centre.
Rectangle {
  id: root

  property bool horizontal: true
  property int orientation: root.horizontal ? Qt.Horizontal : Qt.Vertical
  property int pillHeight: root.horizontal ? Config.pillHeightHorizontal : Config.pillHeightVertical
  property int padding: root.horizontal ? Config.pillPaddingHorizontal : 0

  property color baseColour: Colours.bgRaised
  property color hoverColour: Colours.bgSubtle
  property bool hoverHighlight: false
  property color pillColour: (root.hoverHighlight && root.hovered) ? root.hoverColour : root.baseColour

  // Optional built-in pointer interaction for pill buttons
  property bool clickable: false
  property int acceptedButtons: Qt.LeftButton
  signal clicked(var mouse)
  signal wheel(var wheel)

  readonly property bool hovered: _hoverHandler.hovered

  // Default radius is half of the smaller dimension (caps on ends)
  property real pillRadius: Math.min(width, height) / 2

  color: root.pillColour
  radius: root.pillRadius
  antialiasing: true
  clip: true
  border.width: 1
  border.color: Colours.border

  Behavior on color { ColorAnimation { duration: Config.animNormalMs } }
  Behavior on border.color { ColorAnimation { duration: Config.animNormalMs } }

  HoverHandler {
    id: _hoverHandler
  }

  default property alias contentData: contentItem.data

  // Intrinsic visual width of visible children (ignoring non-layout overlays like MouseArea)
  readonly property real contentWidth: {
    var maxW = 0
    var children = contentItem.children
    for (var i = 0; i < children.length; i++) {
      var child = children[i]
      if (child.visible !== false && child !== _clickArea) {
        var isRotated = (child.rotation === 90 || child.rotation === 270)
        var iw = isRotated ? child.implicitHeight : child.implicitWidth
        if (iw > maxW) maxW = iw
      }
    }
    return maxW
  }

  // Intrinsic visual height of visible children (ignoring non-layout overlays like MouseArea)
  readonly property real contentHeight: {
    var maxH = 0
    var children = contentItem.children
    for (var i = 0; i < children.length; i++) {
      var child = children[i]
      if (child.visible !== false && child !== _clickArea) {
        var isRotated = (child.rotation === 90 || child.rotation === 270)
        var ih = isRotated ? child.implicitWidth : child.implicitHeight
        if (ih > maxH) maxH = ih
      }
    }
    return maxH
  }

  // Automatic implicit dimensions based on orientation
  implicitWidth: root.orientation === Qt.Vertical
    ? root.pillHeight
    : Math.max(root.contentWidth + root.padding * 2, root.pillHeight)

  implicitHeight: root.orientation === Qt.Vertical
    ? Math.max(root.contentHeight + root.padding * 2, root.pillHeight)
    : root.pillHeight

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
