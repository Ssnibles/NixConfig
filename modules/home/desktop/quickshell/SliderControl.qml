import QtQuick
import QtQml

Item {
  id: root

  property real value: 0
  property color fillColor: Colors.accent
  property real snapPercent: 0

  signal moved(real value)
  signal dragStarted()
  signal dragEnded()

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

      Behavior on width { NumberAnimation { duration: 80 } }
      Behavior on height { NumberAnimation { duration: 80 } }
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      property bool dragging: false

      function snap(v) {
        if (root.snapPercent <= 0) return v;
        return Math.round(v / (root.snapPercent / 100)) * (root.snapPercent / 100);
      }

      function computeValue(mx) {
        var raw = Math.max(0, Math.min(1, mx / width));
        return root.snapPercent > 0 ? snap(raw) : raw;
      }

      onPressed: function(mouse) {
        dragging = true;
        root.dragStarted();
        root._dragValue = computeValue(mouse.x);
        root.moved(root._dragValue);
      }
      onReleased: {
        dragging = false;
        root.dragEnded();
      }
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
