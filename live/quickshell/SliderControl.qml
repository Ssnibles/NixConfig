import QtQuick
import QtQml

Item {
  id: root

  Colors { id: colors }

  property real value: 0
  property color fillColor: colors.accent

  readonly property bool hovered: mouse.containsMouse || mouse.dragging

  signal moved(real value)

  implicitHeight: 20
  implicitWidth: 120

  Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: 20
    radius: 10
    color: Qt.rgba(0.145, 0.145, 0.18, 0.7)

    Rectangle {
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      width: parent.width * root.value
      radius: 10
      color: root.fillColor

      Behavior on width {
        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
      }
      Behavior on color {
        ColorAnimation { duration: 150 }
      }
    }

    Rectangle {
      x: parent.width * root.value - width / 2
      y: (parent.height - height) / 2
      width: root.hovered ? 22 : 0
      height: root.hovered ? 22 : 0
      radius: 11
      color: root.fillColor
      opacity: root.hovered ? 1 : 0
      border.width: 2
      border.color: colors.bg

      Behavior on width {
        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
      }
      Behavior on height {
        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
      }
      Behavior on opacity {
        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
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
