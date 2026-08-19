import QtQuick
import Quickshell

Item {
  id: root

  property string uiFont: Config.monoFont
  property string timeFormat: Config.timeFormat
  property string timeStr: ""
  property PanelWindow sharedWindow: null
  property bool horizontal: false

  anchors.horizontalCenter: (parent && !horizontal) ? parent.horizontalCenter : undefined
  anchors.verticalCenter: (parent && horizontal) ? parent.verticalCenter : undefined
  implicitWidth: horizontal ? rowClock.implicitWidth : clockCol.implicitWidth
  implicitHeight: horizontal ? rowClock.implicitHeight : clockCol.implicitHeight

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

  // Vertical stacked format (for side bar)
  Column {
    id: clockCol
    visible: !root.horizontal
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

  // Horizontal single line format (for top bar)
  Row {
    id: rowClock
    visible: root.horizontal
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    spacing: 2

    Text {
      text: root.timeStr
      color: Colors.accent
      font.family: root.uiFont
      font.pixelSize: 14
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
    return day + suffix + " " + Qt.formatDate(date, "of MMMM yyyy");
  }
}
