import QtQuick

// Rounded pill container used in the bar for grouping related widgets (e.g. media, wifi).
Rectangle {
  id: root

  property int padding: 8

  height: 22
  radius: height / 2
  color: Colors.bgRaised

  default property alias data: contentItem.data
  implicitWidth: Math.max(contentItem.childrenRect.width + padding * 2, height)

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
