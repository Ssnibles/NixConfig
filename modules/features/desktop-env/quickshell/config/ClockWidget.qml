pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

Item {
  id: root

  property string uiFont: Config.monoFont
  property string timeFormat: Config.timeFormat
  readonly property string timeStr: root.timeFormat === Config.timeFormat
    ? ClockService.timeStr
    : Qt.formatTime(ClockService.now, root.timeFormat)
  readonly property string hourStr: ClockService.hourStr
  readonly property string minuteStr: ClockService.minuteStr
  readonly property string dateStr: ClockService.ordinalDateStr
  property PanelWindow sharedWindow: null
  property bool horizontal: false

  implicitWidth: horizontal ? rowClock.implicitWidth : clockCol.implicitWidth
  implicitHeight: horizontal ? rowClock.implicitHeight : clockCol.implicitHeight

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
    title: root.dateStr
    contentWidth: 216
    contentComponent: calendarComponent
  }

  Component {
    id: calendarComponent

    Card {
      id: calBg
      cardColour: Colours.bg
      cardRadius: Config.popupRadius

      implicitWidth: calCol.implicitWidth + Config.popupContentMargins * 2
      implicitHeight: calCol.implicitHeight + Config.popupContentMargins * 2
      width: implicitWidth
      height: implicitHeight

      Column {
        id: calCol
        anchors.centerIn: parent
        spacing: 8

        readonly property int realYear: ClockService.year
        readonly property int realMonth: ClockService.month
        readonly property int realDay: ClockService.day

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
          viewYear = Qt.binding(() => calCol.realYear)
          viewMonth = Qt.binding(() => calCol.realMonth)
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
            font.pixelSize: Config.fontSizeMd
            font.bold: true
          }

          Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            IconButton {
              buttonSize: 22
              radius: 4
              icon: "󰅁"
              iconSize: 14
              uiFont: root.uiFont
              iconColour: Colours.fgMid
              onClicked: calCol.prevMonth()
            }

            IconButton {
              buttonSize: 22
              radius: 4
              icon: "󰃭"
              iconSize: Config.iconSizeSm
              uiFont: root.uiFont
              enabled: !calCol.isCurrentMonth
              iconColour: Colours.fgMid
              onClicked: calCol.goToCurrent()
            }

            IconButton {
              buttonSize: 22
              radius: 4
              icon: "󰅂"
              iconSize: 14
              uiFont: root.uiFont
              iconColour: Colours.fgMid
              onClicked: calCol.nextMonth()
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
