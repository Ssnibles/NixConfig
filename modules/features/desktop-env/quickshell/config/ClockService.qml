pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import "Utils.js" as Utils

// Central minute-aligned clock singleton ingested by ClockWidget,
// CommandCentre, and LockScreen.
Singleton {
  id: root

  property var now: new Date()

  readonly property int year: root.now.getFullYear()
  readonly property int month: root.now.getMonth()
  readonly property int day: root.now.getDate()

  readonly property string timeStr: Qt.formatTime(root.now, Config.timeFormat)
  readonly property string hourStr: Utils.pad2(root.now.getHours())
  readonly property string minuteStr: Utils.pad2(root.now.getMinutes())
  readonly property string ordinalDateStr: Utils.getOrdinalDate(root.now)

  readonly property string ccTimeStr: Qt.formatDateTime(root.now, Config.commandCentreClockFormat)
  readonly property string ccTime12Str: Qt.formatDateTime(root.now, "h:mm AP")
  readonly property string ccDateStr: Qt.formatDateTime(root.now, Config.commandCentreDateFormat)

  readonly property string lockTimeStr: Qt.formatDateTime(root.now, Config.lockClockFormat)
  readonly property string lockDateStr: Qt.formatDateTime(root.now, Config.lockDateFormat)

  function updateTime() {
    var d = new Date()
    root.now = d
    minuteTimer.interval = 60000 - (d.getSeconds() * 1000 + d.getMilliseconds())
    minuteTimer.restart()
  }

  Timer {
    id: minuteTimer
    running: true
    repeat: false
    onTriggered: root.updateTime()
  }

  Component.onCompleted: root.updateTime()
}
