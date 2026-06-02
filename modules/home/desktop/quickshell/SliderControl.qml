import QtQuick
import QtQml

Item {
  id: root

  property real value: 0
  property color fillColor: Colors.accent

  signal moved(real value)

  implicitHeight: 36
  implicitWidth: 120

  readonly property real _thumbSize: mouse.dragging ? 26 : (mouse.containsMouse ? 22 : 18)
  readonly property real _trackHeight: 8

  property real _dragValue: 0
  readonly property real _visualValue: mouse.dragging ? _dragValue : value

  Item {
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: root._thumbSize + 8

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width
      height: root._trackHeight
      radius: root._trackHeight / 2
      color: Colors.bgSubtle
    }

    Rectangle {
      anchors.top: parent.verticalCenter
      anchors.topMargin: -root._trackHeight / 2
      anchors.left: parent.left
      anchors.bottom: parent.verticalCenter
      anchors.bottomMargin: -root._trackHeight / 2
      width: parent.width * root._visualValue
      radius: root._trackHeight / 2
      color: root.fillColor

      Behavior on width {
        enabled: !mouse.dragging
        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
      }
      Behavior on color { ColorAnimation { duration: 150 } }
    }

    Rectangle {
      id: thumb
      x: (parent.width - root._thumbSize) * root._visualValue
      y: (parent.height - root._thumbSize) / 2
      width: root._thumbSize
      height: root._thumbSize
      radius: root._thumbSize / 2
      color: root.fillColor
      border.width: root._visualValue > 0 || mouse.containsMouse ? 0 : 2
      border.color: root.fillColor

      Behavior on x {
        enabled: !mouse.dragging
        NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
      }
      Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
      Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      property bool dragging: false

      function computeValue(mx) {
        return Math.max(0, Math.min(1, mx / width));
      }

      onPressed: function(mouse) {
        dragging = true;
        root._dragValue = computeValue(mouse.x);
        root.moved(root._dragValue);
      }
      onReleased: dragging = false
      onExited: { if (!dragging) dragging = false; }
      onPositionChanged: function(mouse) {
        if (dragging) {
          root._dragValue = computeValue(mouse.x);
          root.moved(root._dragValue);
        }
      }
    }
  }
}
