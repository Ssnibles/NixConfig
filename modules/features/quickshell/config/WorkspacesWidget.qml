import QtQuick

Column {
  id: root

  property var workspaces: []
  signal focusRequested(int workspaceId)

  property int dotSize: 10
  property int dotSizeFocused: 26
  property int dotSpacing: 6
  property color dotColorFocused: Colors.accent
  property color dotColorActive: Colors.fgMid
  property color dotColorUrgent: Colors.red
  property color dotColorEmpty: Colors.fgDim

  anchors.centerIn: parent ? parent : undefined
  spacing: root.dotSpacing

  Repeater {
    model: root.workspaces

    delegate: Rectangle {
      required property var modelData
      property bool isFocused: modelData && modelData.is_focused
      property bool isActive: modelData && modelData.is_active
      property bool isUrgent: modelData && modelData.is_urgent

      width: root.dotSize
      height: isFocused ? root.dotSizeFocused : root.dotSize
      radius: width / 2
      color: isFocused ? root.dotColorFocused : (isUrgent ? root.dotColorUrgent : (isActive ? root.dotColorActive : root.dotColorEmpty))

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