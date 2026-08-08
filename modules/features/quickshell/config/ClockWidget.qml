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
      font.pixelSize: 16
      font.bold: true
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.timeStr ? root.timeStr.split(":")[1] : ""
      color: Colors.fg
      font.family: root.uiFont
      font.pixelSize: 16
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
      return Qt.formatDate(d, getOrdinalDate(d))
    }
    details: [
      Qt.formatTime(new Date(), "hh:mm")
    ]
  }

  function getOrdinalDate(date) {
    var day = date.getDate();
    var suffix = "th";

    if (day < 11 || day > 13) {
      switch (day % 10) {
          case 1: suffix = "st"; break;
          case 2: suffix = "nd"; break;
          case 3: suffix = "rd"; break;
        }
    }
    // Combines the day, suffix, and remaining formatted date
    return day + suffix + " " + Qt.formatDate(date, "of MMMM yyyy");
}

}
