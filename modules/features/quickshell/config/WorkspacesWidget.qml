import QtQuick

Column {
  id: root

  property var workspaces: []
  signal focusRequested(int workspaceId)

  anchors.centerIn: parent ? parent : undefined
  spacing: 6

  Repeater {
    model: root.workspaces

    delegate: Rectangle {
      required property var modelData
      property bool isFocused: modelData && modelData.is_focused
      property bool isActive: modelData && modelData.is_active
      property bool isUrgent: modelData && modelData.is_urgent

      width: 10
      height: isFocused ? 26 : 10
      radius: width / 2
      color: isFocused ? Colors.accent : (isUrgent ? Colors.red : (isActive ? Colors.fgMid : Colors.fgDim))

      Behavior on height {
        SpringAnimation { spring: 10; damping: 0.3 }
      }
      Behavior on color {
        ColorAnimation { duration: 200; easing.type: Easing.InOutQuad }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.focusRequested(modelData.id)
      }
    }
  }
}
