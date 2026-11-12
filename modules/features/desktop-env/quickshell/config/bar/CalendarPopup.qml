pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."

// Month calendar shown in the bar clock popup, with month navigation.
Card {
  id: root

  property string uiFont: Session.monoFont

  cardColour: Colours.bg
  cardRadius: Config.popupRadius
  implicitWidth: calCol.implicitWidth + Config.popupContentMargins * 2
  implicitHeight: calCol.implicitHeight + Config.popupContentMargins * 2
  width: implicitWidth
  height: implicitHeight

  ColumnLayout {
    id: calCol
    anchors.centerIn: parent
    spacing: Config.spaceMd

    readonly property int realYear: ClockService.year
    readonly property int realMonth: ClockService.month
    readonly property int realDay: ClockService.day

    property int viewYear: realYear
    property int viewMonth: realMonth

    readonly property bool isCurrentMonth: viewYear === realYear && viewMonth === realMonth

    readonly property var monthNames: [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ]

    // Leading blanks plus one entry per day, so the grid starts on Monday.
    readonly property var monthModel: {
      var firstDayIndex = new Date(viewYear, viewMonth, 1).getDay()
      var startOffset = (firstDayIndex === 0) ? 6 : firstDayIndex - 1
      var totalDays = new Date(viewYear, viewMonth + 1, 0).getDate()

      var cells = []
      for (var i = 0; i < startOffset; i++) {
        cells.push({ day: 0, isCurrent: false })
      }
      for (var d = 1; d <= totalDays; d++) {
        cells.push({
          day: d,
          isCurrent: viewYear === realYear && viewMonth === realMonth && d === realDay
        })
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

    RowLayout {
      Layout.preferredWidth: 192
      Layout.preferredHeight: 24
      spacing: Config.spaceSm

      Text {
        Layout.fillWidth: true
        text: calCol.monthNames[calCol.viewMonth] + " " + calCol.viewYear
        color: Colours.fg
        font.family: root.uiFont
        font.pixelSize: Config.fontSizeMd
        font.bold: true
        elide: Text.ElideRight
      }

      IconButton {
        buttonSize: 22
        radius: Config.itemRadiusXs
        icon: "󰅁"
        iconSize: 14
        uiFont: root.uiFont
        iconColour: Colours.fgMid
        onClicked: calCol.prevMonth()
      }

      IconButton {
        buttonSize: 22
        radius: Config.itemRadiusXs
        icon: "󰃭"
        iconSize: Config.iconSizeSm
        uiFont: root.uiFont
        enabled: !calCol.isCurrentMonth
        iconColour: Colours.fgMid
        onClicked: calCol.goToCurrent()
      }

      IconButton {
        buttonSize: 22
        radius: Config.itemRadiusXs
        icon: "󰅂"
        iconSize: 14
        uiFont: root.uiFont
        iconColour: Colours.fgMid
        onClicked: calCol.nextMonth()
      }
    }

    Column {
      spacing: Config.spaceXs

      Row {
        spacing: Config.spaceXs

        Repeater {
          model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

          delegate: Text {
            required property var modelData
            width: 24
            horizontalAlignment: Text.AlignHCenter
            text: modelData
            font.family: root.uiFont
            font.pixelSize: 11
            font.bold: true
            color: Colours.accent
          }
        }
      }

      Grid {
        columns: 7
        rowSpacing: Config.spaceXs
        columnSpacing: Config.spaceXs

        Repeater {
          model: calCol.monthModel

          delegate: Rectangle {
            id: dayCell
            required property var modelData
            width: 24
            height: 24
            radius: Config.itemRadiusXs
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
