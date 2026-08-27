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
    id: clockTip
    target: root
    sharedWindow: root.sharedWindow
    icon: "\u{F017}"
    iconColor: Colors.accent
    title: {
      var d = new Date()
      return Qt.formatDate(d, getOrdinalDate(d))
    }
    contentWidth: 216
    contentComponent: calendarComponent
  }

  Component {
    id: calendarComponent

    Rectangle {
      id: calBg
      color: Colors.bg
      radius: 8
      border.color: Colors.border
      border.width: 1

      implicitWidth: calCol.implicitWidth + 20
      implicitHeight: calCol.implicitHeight + 20
      width: implicitWidth
      height: implicitHeight

      Column {
        id: calCol
        anchors.centerIn: parent
        spacing: 8

        readonly property var today: new Date()
        readonly property int realYear: today.getFullYear()
        readonly property int realMonth: today.getMonth()
        readonly property int realDay: today.getDate()

        property int viewYear: realYear
        property int viewMonth: realMonth

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
            color: Colors.fg
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
              color: prevHover.containsMouse ? Colors.bgSubtle : "transparent"

              Text {
                anchors.centerIn: parent
                text: "󰅁"
                color: prevHover.containsMouse ? Colors.accent : Colors.fgMid
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
              color: (!calCol.isCurrentMonth && todayHover.containsMouse) ? Colors.bgSubtle : "transparent"

              Text {
                anchors.centerIn: parent
                text: "󰃭"
                color: calCol.isCurrentMonth
                       ? Colors.fgDim
                       : (todayHover.containsMouse ? Colors.accent : Colors.fgMid)
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
              color: nextHover.containsMouse ? Colors.bgSubtle : "transparent"

              Text {
                anchors.centerIn: parent
                text: "󰅂"
                color: nextHover.containsMouse ? Colors.accent : Colors.fgMid
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
              width: 24
              horizontalAlignment: Text.AlignHCenter
              text: modelData
              font.family: root.uiFont
              font.pixelSize: 11
              font.bold: true
              color: Colors.accent
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
              width: 24
              height: 24
              radius: 4
              color: modelData.isCurrent ? Colors.accent : "transparent"

              Text {
                anchors.centerIn: parent
                visible: modelData.day > 0
                text: modelData.day > 0 ? modelData.day.toString() : ""
                font.family: root.uiFont
                font.pixelSize: 11
                font.bold: modelData.isCurrent
                color: modelData.isCurrent ? Colors.bg : Colors.fg
              }
            }
          }
        }
      }
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
