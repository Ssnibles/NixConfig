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

  readonly property real _trackHeight: 12

  // Internal drag state: _dragValue is live during drag, _pendingValue
  // holds the last dragged value until the bound 'value' property catches up.
  property real _dragValue: 0
  property real _pendingValue: -1
  readonly property real _visualValue: mouse.dragging ? _dragValue : (_pendingValue >= 0 ? _pendingValue : value)

  // Clear the pending value once the external source reflects our drag.
  onValueChanged: {
    if (mouse && !mouse.dragging && _pendingValue >= 0 && Math.abs(value - _pendingValue) < 0.001) {
      _pendingValue = -1
    }
  }

  Item {
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: 32

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width
      height: root._trackHeight
      radius: 4
      color: Colors.bgSubtle
      border.width: 1
      border.color: mouse.containsMouse ? root.fillColor : "transparent"
      Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    Rectangle {
      anchors.top: parent.verticalCenter
      anchors.topMargin: -root._trackHeight / 2
      anchors.left: parent.left
      anchors.bottom: parent.verticalCenter
      anchors.bottomMargin: -root._trackHeight / 2
      width: parent.width * root._visualValue
      radius: 4
      color: root.fillColor
      Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      property bool dragging: false

      // Snap slider to increments (e.g. 5% steps) when snapPercent > 0.
      function _snap(v) {
        if (root.snapPercent <= 0) return v
        return Math.round(v / (root.snapPercent / 100)) * (root.snapPercent / 100)
      }

      function _computeValue(mx) {
        var raw = Math.max(0, Math.min(1, mx / width))
        return root.snapPercent > 0 ? _snap(raw) : raw
      }

      onPressed: function(mouse) {
        if (!root.enabled) return
        if (!dragging) {
          dragging = true
          root.dragStarted()
        }
        root._dragValue = _computeValue(mouse.x)
        root.moved(root._dragValue)
      }
      onReleased: {
        if (!dragging) return
        dragging = false
        root._pendingValue = root._dragValue
        root.dragEnded()
      }
      onExited: { if (!dragging) dragging = false }
      onPositionChanged: function(mouse) {
        if (dragging) {
          root._dragValue = _computeValue(mouse.x)
          root.moved(root._dragValue)
        }
      }
    }
  }
}
