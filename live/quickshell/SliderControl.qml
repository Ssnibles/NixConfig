import QtQuick
import QtQml

Item {
  id: root

  Colors { id: colors }

  property real value: 0
  property color fillColor: colors.accent

  readonly property bool hovered: mouse.containsMouse
  readonly property bool active: mouse.dragging

  signal moved(real value)

  implicitHeight: 28
  implicitWidth: 120

  readonly property real _thumbSize: active ? 20 : (hovered ? 18 : 14)
  readonly property real _trackHeight: 6

  Item {
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: root._thumbSize + 8

    // Track background
    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width
      height: root._trackHeight
      radius: root._trackHeight / 2
      color: Qt.rgba(0.145, 0.145, 0.18, 0.7)
    }

    // Track fill
    Rectangle {
      anchors.top: parent.verticalCenter
      anchors.topMargin: -root._trackHeight / 2
      anchors.left: parent.left
      anchors.bottom: parent.verticalCenter
      anchors.bottomMargin: -root._trackHeight / 2
      width: parent.width * root.value
      radius: root._trackHeight / 2
      color: root.fillColor

      Behavior on width {
        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
      }
      Behavior on color {
        ColorAnimation { duration: 150 }
      }
    }

    // Thumb shadow
    Rectangle {
      x: (parent.width - root._thumbSize) * root.value
      y: (parent.height - root._thumbSize) / 2
      width: root._thumbSize
      height: root._thumbSize
      radius: root._thumbSize / 2
      color: Qt.rgba(0, 0, 0, 0.12)
      opacity: root.hovered || root.active ? 1 : 0.5

      Behavior on x {
        NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
      }
    }

    // Thumb
    Rectangle {
      x: (parent.width - root._thumbSize) * root.value
      y: (parent.height - root._thumbSize) / 2
      width: root._thumbSize
      height: root._thumbSize
      radius: root._thumbSize / 2
      color: root.fillColor
      border.width: root.value > 0 || root.hovered || root.active ? 0 : 2
      border.color: root.fillColor

      Behavior on width {
        NumberAnimation { duration: 120; easing.type: Easing.OutBack }
      }
      Behavior on height {
        NumberAnimation { duration: 120; easing.type: Easing.OutBack }
      }
      Behavior on x {
        NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
      }

      // Inner dot for inactive look when at zero
      Rectangle {
        anchors.centerIn: parent
        width: root.value > 0 ? 0 : (root.hovered ? 0 : 6)
        height: root.value > 0 ? 0 : (root.hovered ? 0 : 6)
        radius: 3
        color: root.fillColor
        opacity: 0.6

        Behavior on width { NumberAnimation { duration: 100 } }
        Behavior on height { NumberAnimation { duration: 100 } }
      }
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      property bool dragging: false

      onPressed: function(mouse) {
        dragging = true
        root.moved(Math.max(0, Math.min(1, mouse.x / width)))
      }
      onReleased: dragging = false
      onExited: { if (!dragging) dragging = false }
      onPositionChanged: function(mouse) {
        if (dragging) root.moved(Math.max(0, Math.min(1, mouse.x / width)))
      }
    }
  }
}
