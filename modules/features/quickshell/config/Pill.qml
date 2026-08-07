import QtQuick

// Rounded pill container used in the bar for grouping related widgets (e.g. media, wifi).
Rectangle {
  id: root

  property int padding: 8
  property int pillHeight: 22
  property color pillColor: Colors.bgRaised

  height: root.pillHeight
  radius: height / 2
  color: root.pillColor
  antialiasing: true

  default property alias data: contentItem.data
  implicitWidth: {
    var maxW = 0
    var children = contentItem.children
    for (var i = 0; i < children.length; i++) {
      var child = children[i]
      if (!child || !child.visible) continue
      var iw = child.implicitWidth
      if (iw !== undefined && iw > 0) {
        if (iw > maxW) maxW = iw
      }
    }
    return Math.max(maxW + padding * 2, height)
  }

  Item {
    id: contentItem
    anchors.left: parent.left
    anchors.leftMargin: root.padding
    anchors.right: parent.right
    anchors.rightMargin: root.padding
    anchors.verticalCenter: parent.verticalCenter
    height: parent.height
  }
}