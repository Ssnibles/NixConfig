import QtQuick

// Smart rounded pill container used across bars and command center.
Rectangle {
  id: root

  property int padding: 8
  property int pillHeight: 22
  property color pillColor: Colors.bgRaised
  property int orientation: Qt.Horizontal // Qt.Horizontal | Qt.Vertical

  // Default radius is half of the smaller dimension (caps on ends)
  property real pillRadius: Math.min(width, height) / 2

  color: root.pillColor
  radius: root.pillRadius
  antialiasing: true

  default property alias data: contentItem.data

  // Intrinsic visual width of visible children (ignoring non-layout overlays like MouseArea)
  readonly property real contentWidth: {
    var maxW = 0
    var children = contentItem.children
    for (var i = 0; i < children.length; i++) {
      var child = children[i]
      if (child.visible !== false) {
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
      if (child.visible !== false) {
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

  width: implicitWidth
  height: implicitHeight

  Item {
    id: contentItem
    anchors.centerIn: parent
    width: root.contentWidth
    height: root.contentHeight
  }
}