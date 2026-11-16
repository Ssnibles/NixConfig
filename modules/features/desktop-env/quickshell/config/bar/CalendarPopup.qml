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
  property int contentPadding: Config.popupContentMargins

  // The header controls follow the header text so a larger calendar does not
  // leave the month title beside small buttons.
  readonly property int headerHeight: Math.max(Config.iconSizeXl, root.headerFontSize + Config.spaceSm)
  readonly property int navButtonSize: Math.max(Config.iconSizeXl - Config.space2xs, root.headerFontSize + Config.spaceSm)
  readonly property int navIconSize: Math.max(Config.iconSizeSm, Math.round(root.headerFontSize * 0.85))

  // Month navigation button, sized from the header text.
  component NavButton: IconButton {
    buttonSize: root.navButtonSize
    iconSize: root.navIconSize
    uiFont: root.uiFont
    iconColour: Colours.fgMid
  }

  // Largest square cell that fits a card of the given size, leaving room for the
  // header, weekday row and padding. The header and weekday rows are at least an
  // icon tall, and using that floor keeps the result independent of the fonts
  // derived from the cell size.
  function fittedCellSize(availableWidth, availableHeight) {
    var byWidth = Math.floor((availableWidth - root.contentPadding * 2 - root.cellSpacing * 6) / 7)
    var chrome = Config.iconSizeXl * 2 + root.contentSpacing + Config.spaceXs
      + root.cellSpacing * 5 + root.contentPadding * 2
    var byHeight = Math.floor((availableHeight - chrome) / 6)
    return Math.max(Config.spaceLg * 2, Math.min(byWidth, byHeight))
  }

  cardColour: Colours.bg
  cardRadius: Config.popupRadius
  implicitWidth: calCol.implicitWidth + root.contentPadding * 2
  implicitHeight: calCol.implicitHeight + root.contentPadding * 2
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
      Layout.preferredHeight: root.headerHeight
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

      NavButton {
        icon: "󰅁"
        onClicked: calCol.prevMonth()
      }

      NavButton {
        icon: "󰃭"
        enabled: !calCol.isCurrentMonth
        onClicked: calCol.goToCurrent()
      }

      NavButton {
        icon: "󰅂"
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

          delegate: Item {
            id: dayCell
            required property var modelData
            width: root.cellSize
            height: root.cellSize

            // Today is marked by its text alone, so it reads as part of the
            // grid rather than as a filled box.
            Text {
              anchors.centerIn: parent
              text: dayCell.modelData.day.toString()
              font.family: root.uiFont
              font.pixelSize: root.cellFontSize
              font.bold: dayCell.modelData.isCurrent
              font.italic: dayCell.modelData.isCurrent
              color: dayCell.modelData.isCurrent
                ? Colours.accent
                : (dayCell.modelData.inMonth ? Colours.fg : Colours.fgDim)
            }
          }
        }
      }
    }
  }
}
