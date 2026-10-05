pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "Utils.js" as Utils

Item {
  id: root

  property string uiFont: Config.monoFont
  property string timeFormat: Config.timeFormat
  property string timeStr: ""
  property string hourStr: ""
  property string minuteStr: ""
  property PanelWindow sharedWindow: null
  property bool horizontal: false

  anchors.horizontalCenter: (parent && !horizontal) ? parent.horizontalCenter : undefined
  anchors.verticalCenter: (parent && horizontal) ? parent.verticalCenter : undefined
  implicitWidth: horizontal ? rowClock.implicitWidth : clockCol.implicitWidth
  implicitHeight: horizontal ? rowClock.implicitHeight : clockCol.implicitHeight

  function updateTime() {
    var d = new Date()
    root.timeStr = Qt.formatTime(d, root.timeFormat)
    // Keep a 24h hour/minute pair for the stacked vertical layout, independent
    // of `timeFormat` (which may be 12-hour and is not `HH:mm`).
    root.hourStr = Utils.pad2(d.getHours())
    root.minuteStr = Utils.pad2(d.getMinutes())
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
      text: root.hourStr
      color: Colours.accent
      font.family: root.uiFont
      font.pixelSize: 16
      font.bold: true
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.minuteStr
      color: Colours.fg
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
      color: Colours.accent
      font.family: root.uiFont
      font.pixelSize: 14
      font.bold: true
    }
  }

  Tooltip {
    id: clockTip
    target: root
    sharedWindow: root.sharedWindow
    icon: "\u{F017}"
    iconColour: Colours.accent
    title: Utils.getOrdinalDate(new Date())
    contentWidth: 216
    contentComponent: calendarComponent
  }

  Component {
    id: calendarComponent

    Rectangle {
      id: calBg
      color: Colours.bg
      radius: 8
      border.color: Colours.border
      border.width: 1

      implicitWidth: calCol.implicitWidth + 20
      implicitHeight: calCol.implicitHeight + 20
      width: implicitWidth
      height: implicitHeight

      Column {
        id: calCol
        anchors.centerIn: parent
        spacing: 8

        property var today: new Date()
        readonly property int realYear: today.getFullYear()
        readonly property int realMonth: today.getMonth()
        readonly property int realDay: today.getDate()

        property int viewYear: realYear
        property int viewMonth: realMonth

        // Keep the "today" highlight correct if the calendar stays open across
        // midnight. This component only exists while the tooltip is shown.
        Timer {
          interval: 60000
          repeat: true
          running: true
          onTriggered: calCol.today = new Date()
        }

        readonly property bool isCurrentMonth: (viewYear === realYear && viewMonth === realMonth)

        readonly property var monthNames: [
          "January", "February", "March", "April", "May", "June",
          "July", "August", "September", "October", "November", "December"
        ]

        readonly property var monthModel: {
          var firstDayIndex = new Date(viewYear, viewMonth, 1).getDay()
          var startOffset = (firstDayIndex === 0) ? 6 : firstDayIndex - 1
          var totalDays = new Date(viewYear, viewMonth + 1, 0).getDate()

          var cells = []
          for (var i = 0; i < startOffset; i++) {
            cells.push({ day: 0, isCurrent: false })
          }
          for (var d = 1; d <= totalDays; d++) {
            var isCurr = (viewYear === realYear && viewMonth === realMonth && d === realDay)
            cells.push({ day: d, isCurrent: isCurr })
          }
          return cells
        }

        function prevMonth() {
          if (viewMonth === 0) {
            viewMonth = 11
            viewYear--
          } else {
            viewMonth--
          }
        }

        function nextMonth() {
          if (viewMonth === 11) {
            viewMonth = 0
            viewYear++
          } else {
            viewMonth++
          }
        }

        function goToCurrent() {
          viewYear = realYear
          viewMonth = realMonth
        }

        // Calendar Header: Month + Year title & Nav Buttons
        Item {
          width: 192
          height: 24
          anchors.horizontalCenter: parent.horizontalCenter

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: calCol.monthNames[calCol.viewMonth] + " " + calCol.viewYear
            color: Colours.fg
            font.family: root.uiFont
            font.pixelSize: 13
            font.bold: true
          }

          Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            // Previous Month Button
            Rectangle {
              width: 22
              height: 22
              radius: 4
              color: prevHover.containsMouse ? Colours.bgSubtle : "transparent"

              Text {
                anchors.centerIn: parent
                text: "󰅁"
                color: prevHover.containsMouse ? Colours.accent : Colours.fgMid
                font.family: root.uiFont
                font.pixelSize: 14
              }

              MouseArea {
                id: prevHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: calCol.prevMonth()
              }
            }

            // Jump to Current Month Button
            Rectangle {
              width: 22
              height: 22
              radius: 4
              color: (!calCol.isCurrentMonth && todayHover.containsMouse) ? Colours.bgSubtle : "transparent"

              Text {
                anchors.centerIn: parent
                text: "󰃭"
                color: calCol.isCurrentMonth
                       ? Colours.fgDim
                       : (todayHover.containsMouse ? Colours.accent : Colours.fgMid)
                font.family: root.uiFont
                font.pixelSize: 13
              }

              MouseArea {
                id: todayHover
                anchors.fill: parent
                hoverEnabled: !calCol.isCurrentMonth
                cursorShape: calCol.isCurrentMonth ? Qt.ArrowCursor : Qt.PointingHandCursor
                enabled: !calCol.isCurrentMonth
                onClicked: calCol.goToCurrent()
              }
            }

            // Next Month Button
            Rectangle {
              width: 22
              height: 22
              radius: 4
              color: nextHover.containsMouse ? Colours.bgSubtle : "transparent"

              Text {
                anchors.centerIn: parent
                text: "󰅂"
                color: nextHover.containsMouse ? Colours.accent : Colours.fgMid
                font.family: root.uiFont
                font.pixelSize: 14
              }

              MouseArea {
                id: nextHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: calCol.nextMonth()
              }
            }
          }
        }

        // Weekday Header Row
        Row {
          spacing: 4
          Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
            Text {
              id: weekdayLabel
              required property var modelData
              width: 24
              horizontalAlignment: Text.AlignHCenter
              text: weekdayLabel.modelData
              font.family: root.uiFont
              font.pixelSize: 11
              font.bold: true
              color: Colours.accent
            }
          }
        }

        // Days Grid
        Grid {
          columns: 7
          rowSpacing: 4
          columnSpacing: 4

          Repeater {
            model: calCol.monthModel

            Rectangle {
              id: dayCell
              required property var modelData
              width: 24
              height: 24
              radius: 4
              color: dayCell.modelData.isCurrent ? Colours.accent : "transparent"

              Text {
                anchors.centerIn: parent
                visible: dayCell.modelData.day > 0
                text: dayCell.modelData.day > 0 ? dayCell.modelData.day.toString() : ""
                font.family: root.uiFont
                font.pixelSize: 11
                font.bold: dayCell.modelData.isCurrent
                color: dayCell.modelData.isCurrent ? Colours.bg : Colours.fg
              }
            }
          }
        }
      }
    }
  }
}
