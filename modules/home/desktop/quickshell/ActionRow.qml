import QtQuick
import QtQuick.Layouts
import QtQml

Row {
  id: root

  property var actions: []
  property string uiFont: "JetBrains Mono"
  property int actionBtnHeight: 26
  property int cardSpacing: 6

  signal actionInvoked()

  spacing: cardSpacing
  visible: actions && actions.length > 0

  Repeater {
    model: actions

    Rectangle {
      required property QtObject modelData

      height: root.actionBtnHeight
      radius: 6
      color: "transparent"
      border.width: 1
      border.color: Colors.border
      width: btnLabel.implicitWidth + 20

      Behavior on scale {
        NumberAnimation { duration: 60; easing.type: Easing.OutQuad }
      }

      Text {
        id: btnLabel
        anchors.centerIn: parent
        text: modelData.text
        color: Colors.fgMid
        font.family: root.uiFont
        font.pixelSize: 11
        textFormat: Text.PlainText
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: {
          parent.color = Colors.bgSubtle;
          parent.scale = 0.96;
        }
        onExited: {
          parent.color = "transparent";
          parent.scale = 1;
        }
        onPressed: parent.scale = 0.93
        onReleased: parent.scale = 0.96
        onClicked: {
          modelData.invoke();
          root.actionInvoked();
        }
      }
    }
  }
}
