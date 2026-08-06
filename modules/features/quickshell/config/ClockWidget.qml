import QtQuick
import Quickshell

Item {
  id: root

  property string uiFont: Config.monoFont
  property string timeFormat: Config.timeFormat
  property string timeStr: ""
  property PanelWindow sharedWindow: null

  anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
  implicitWidth: clockCol.implicitWidth
  implicitHeight: clockCol.implicitHeight

  function updateTime() {
    var d = new Date()
    root.timeStr = Qt.formatTime(d, root.timeFormat)
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

  Column {
    id: clockCol
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    spacing: -2

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

  Tooltip {
    target: root
    sharedWindow: root.sharedWindow
    icon: "\u{F017}"
    iconColor: Colors.accent
    title: {
      var d = new Date()
      return Qt.formatDate(d, "dddd d MMMM yyyy")
    }
    details: [
      Qt.formatTime(new Date(), "hh:mm:ss")
    ]
  }
}