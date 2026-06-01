import QtQuick
import QtQml

Item {
  id: root

  property real value: 0
  property color fillColor: Colors.accent

  signal moved(real value)

  implicitHeight: 28
  implicitWidth: 120

  readonly property real _thumbSize: mouse.dragging ? 20 : (mouse.containsMouse ? 18 : 14)
  readonly property real _trackHeight: 6

  Item {
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: root._thumbSize + 8

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width
      height: root._trackHeight
      radius: root._trackHeight / 2
      color: Qt.rgba(0.145, 0.145, 0.18, 0.7)
    }

    Rectangle {
      anchors.top: parent.verticalCenter
      anchors.topMargin: -root._trackHeight / 2
      anchors.left: parent.left
      anchors.bottom: parent.verticalCenter
      anchors.bottomMargin: -root._trackHeight / 2
      width: parent.width * root.value
      radius: root._trackHeight / 2
      color: root.fillColor

      Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
      Behavior on color { ColorAnimation { duration: 150 } }
    }

    Rectangle {
      id: thumb
      x: (parent.width - root._thumbSize) * root.value
      y: (parent.height - root._thumbSize) / 2
      width: root._thumbSize
      height: root._thumbSize
      radius: root._thumbSize / 2
      color: root.fillColor
      border.width: root.value > 0 || mouse.containsMouse ? 0 : 2
      border.color: root.fillColor

      Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
      Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
      Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      property bool dragging: false

      onPressed: function(mouse) {
        dragging = true;
        root.moved(Math.max(0, Math.min(1, mouse.x / width)));
      }
      onReleased: dragging = false
      onExited: { if (!dragging) dragging = false; }
      onPositionChanged: function(mouse) {
        if (dragging) root.moved(Math.max(0, Math.min(1, mouse.x / width)));
      }
    }
  }
}
