import QtQuick

Rectangle {
  id: root
  Colors { id: colors }

  default property alias data: root.data
  property int padding: 8

  height: 22
  radius: height / 2
  color: colors.bgRaised
  implicitWidth: root.childrenRect.width + padding * 2
  width: implicitWidth
}
