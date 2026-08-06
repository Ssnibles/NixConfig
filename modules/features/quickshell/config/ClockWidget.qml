import QtQuick

Column {
  id: root

  property string uiFont: "JetBrainsMono Nerd Font"
  property string timeStr: ""

  anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
  spacing: -2

  function updateTime() {
    var d = new Date()
    root.timeStr = Qt.formatTime(d, "hh:mm")
    timeTimer.interval = 60000 - (d.getSeconds() * 1000 + d.getMilliseconds())
    timeTimer.restart()
  }

  Timer {
    id: timeTimer
    running: true
    repeat: false
    onTriggered: root.updateTime()
  }

  Component.onCompleted: updateTime()

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    text: root.timeStr ? root.timeStr.split(":")[0] : ""
    color: Colors.accent
    font.family: root.uiFont
    font.pixelSize: 13
    font.bold: true
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    text: root.timeStr ? root.timeStr.split(":")[1] : ""
    color: Colors.fg
    font.family: root.uiFont
    font.pixelSize: 13
    font.bold: true
  }
}
