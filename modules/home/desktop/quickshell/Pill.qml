import QtQuick

Rectangle {
  id: root
  Colors { id: colors }

  property int padding: 8

  height: 22
  radius: height / 2
  color: colors.bgRaised

  Item {
    id: contentItem
    anchors.left: parent.left
    anchors.leftMargin: root.padding
    anchors.right: parent.right
    anchors.rightMargin: root.padding
    anchors.verticalCenter: parent.verticalCenter
    height: parent.height
  }

  default property alias data: contentItem.data

  implicitWidth: Math.max(contentItem.childrenRect.width + padding * 2, height)
}
