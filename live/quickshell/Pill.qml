import QtQuick
import "colors.js" as Colors

Rectangle {
  id: root

  default property alias data: contentItem.data

  anchors.verticalCenter: parent.verticalCenter
  height: 22
  radius: height / 2
  color: Colors.bgRaised
  implicitWidth: contentItem.childrenRect.width + padding * 2

  property int padding: 8

  Item {
    id: contentItem
    x: padding
    anchors.top: parent.top
    anchors.bottom: parent.bottom
  }
}
