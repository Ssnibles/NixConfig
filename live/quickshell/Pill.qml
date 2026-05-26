import QtQuick

Rectangle {
  id: root
  Colors { id: colors }

  default property alias data: contentItem.data

  anchors.verticalCenter: parent.verticalCenter
  height: 22
  radius: height / 2
  color: colors.bgRaised
  implicitWidth: contentItem.childrenRect.width + padding * 2
  width: implicitWidth

  property int padding: 8

  Item {
    id: contentItem
    anchors.left: parent.left
    anchors.leftMargin: padding
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: Math.max(0, parent.width - padding * 2)
  }
}
