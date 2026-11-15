pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../Utils.js" as Utils
import ".."

// Month calendar shown in the bar clock popup, with month navigation.
Card {
  id: root

  property string uiFont: Session.monoFont
  property int cellSize: Config.iconSizeXl
  property int cellSpacing: Config.spaceXs
  property int cellFontSize: Config.fontSizeXs
  property int headerFontSize: Config.fontSizeMd
  property int contentSpacing: Config.spaceMd

  cardColour: Colours.bg
  cardRadius: Config.popupRadius
  implicitWidth: calCol.implicitWidth + Config.popupContentMargins * 2
  implicitHeight: calCol.implicitHeight + Config.popupContentMargins * 2
  width: implicitWidth
  height: implicitHeight

  ColumnLayout {
    id: calCol
    anchors.centerIn: parent
    spacing: root.contentSpacing

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

    // A fixed six-row grid keeps the calendar the same height in every month.
    // The leading and trailing cells show the neighbouring month's days dimmed,
    // so a short month does not leave an empty row.
    readonly property var monthModel: Utils.buildMonthGrid(viewYear, viewMonth, realYear, realMonth, realDay)

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
      Layout.preferredWidth: root.cellSize * 7 + root.cellSpacing * 6
      Layout.preferredHeight: Config.iconSizeXl
      spacing: Config.spaceSm

      Text {
        Layout.fillWidth: true
        text: calCol.monthNames[calCol.viewMonth] + " " + calCol.viewYear
        color: Colours.fg
        font.family: root.uiFont
        font.pixelSize: root.headerFontSize
        font.bold: true
        elide: Text.ElideRight
      }

      IconButton {
        buttonSize: Config.iconSizeXl - Config.space2xs
        icon: "󰅁"
        iconSize: Config.iconSizeSm
        uiFont: root.uiFont
        iconColour: Colours.fgMid
        onClicked: calCol.prevMonth()
      }

      IconButton {
        buttonSize: Config.iconSizeXl - Config.space2xs
        icon: "󰃭"
        iconSize: Config.iconSizeSm
        uiFont: root.uiFont
        enabled: !calCol.isCurrentMonth
        iconColour: Colours.fgMid
        onClicked: calCol.goToCurrent()
      }

      IconButton {
        buttonSize: Config.iconSizeXl - Config.space2xs
        icon: "󰅂"
        iconSize: Config.iconSizeSm
        uiFont: root.uiFont
        iconColour: Colours.fgMid
        onClicked: calCol.nextMonth()
      }
    }

    Column {
      spacing: Config.spaceXs

      Row {
        spacing: root.cellSpacing

        Repeater {
          model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

          delegate: Text {
            required property var modelData
            width: root.cellSize
            horizontalAlignment: Text.AlignHCenter
            text: modelData
            font.family: root.uiFont
            font.pixelSize: root.cellFontSize
            font.bold: true
            color: Colours.accent
          }
        }
      }

      Grid {
        columns: 7
        rowSpacing: root.cellSpacing
        columnSpacing: root.cellSpacing

        Repeater {
          model: calCol.monthModel

          delegate: Rectangle {
            id: dayCell
            required property var modelData
            width: root.cellSize
            height: root.cellSize
            radius: Config.itemRadiusXs
            color: dayCell.modelData.isCurrent ? Colours.accent : "transparent"

            Text {
              anchors.centerIn: parent
              text: dayCell.modelData.day.toString()
              font.family: root.uiFont
              font.pixelSize: root.cellFontSize
              font.bold: dayCell.modelData.isCurrent
              color: dayCell.modelData.isCurrent
                ? Colours.bg
                : (dayCell.modelData.inMonth ? Colours.fg : Colours.fgDim)
            }
          }
        }
      }
    }
  }
}
