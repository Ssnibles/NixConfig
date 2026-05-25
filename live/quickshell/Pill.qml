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

  property int padding: 8

  Item {
    id: contentItem
    x: padding
    anchors.top: parent.top
    anchors.bottom: parent.bottom
  }
}
