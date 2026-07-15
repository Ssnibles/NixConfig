import QtQuick
import QtQuick.Layouts
import QtQml

Row {
  id: root

  property var actions: []
  readonly property string uiFont: "JetBrainsMono Nerd Font"
  property int actionBtnHeight: 28
  property int cardSpacing: 6

  signal actionInvoked()

  spacing: cardSpacing
  visible: actions && actions.length > 0

  Repeater {
    model: actions

    Rectangle {
      required property QtObject modelData

      height: root.actionBtnHeight
      radius: 8
      color: "transparent"
      border.width: 1
      border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.3)
      width: btnLabel.implicitWidth + 22

      Behavior on scale {
        NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
      }

      Behavior on border.color {
        ColorAnimation { duration: 120 }
      }

      Behavior on color {
        ColorAnimation { duration: 120 }
      }

      Text {
        id: btnLabel
        anchors.centerIn: parent
        text: modelData.text
        color: Colors.accent
        font.family: root.uiFont
        font.pixelSize: 10
        font.bold: true
        textFormat: Text.PlainText
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: {
          parent.color = Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.12)
          parent.border.color = Colors.accent
          parent.scale = 0.96
        }
        onExited: {
          parent.color = "transparent"
          parent.border.color = Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.3)
          parent.scale = 1
        }
        onPressed: parent.scale = 0.93
        onReleased: parent.scale = 0.96
        onClicked: {
          modelData.invoke()
          root.actionInvoked()
        }
      }
    }
  }
}
