pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."

// Centred Command Centre board. Left: clock, status pills, sliders, media and
// power. Middle: notifications. Right: weather and calendar.
Item {
  id: root

  // Padding between the optional board surface and the cards. Without the
  // surface the board takes the full panel width.
  readonly property int boardPadding: Config.commandCentreBentoSurface ? Config.spaceLg : 0

  // Content height, used as a floor when the screen is shorter than the
  // configured board size.
  implicitHeight: board.implicitHeight + root.boardPadding * 2

  // Column widths follow the board width so the board keeps its proportions on
  // any screen. The main column takes what is left after these and the gaps.
  readonly property real notificationWidth: Math.round(board.width * Config.commandCentreBentoNotificationRatio)
  readonly property real sideWidth: Math.round(board.width * Config.commandCentreBentoSideRatio)

  // The right column stacks the weather card, the calendar and the system card.
  // The calendar sizes its own cells to fit the space left between them.
  readonly property int calendarCellSize: calendar.fittedCellSize(
    root.sideWidth,
    root.height - weatherCard.implicitHeight - Config.spaceXl * 2 - root.statsFloorHeight
  )
  // Height kept for the system card before the calendar takes its share.
  readonly property int statsFloorHeight: Config.space3xl * 2

  // Swallow clicks in the gaps between cards so they cannot reach the dismiss
  // backdrop. The cards themselves sit above this and handle their own input.
  MouseArea {
    anchors.fill: parent
    onClicked: function(mouse) { mouse.accepted = true }
  }

  // Screenshot tools freeze the screen as soon as they start, so wait for the
  // panel to finish fading out before taking the shot.
  Timer {
    id: screenshotTimer
    interval: Config.commandCentreCloseDuration + Config.animFastMs
    onTriggered: SystemService.takeScreenshot()
  }

  // Optional solid board behind the cards. Sized from the grid so it always
  // matches the cards, including when the panel height is clamped.
  Card {
    width: board.width + root.boardPadding * 2
    height: board.height + root.boardPadding * 2
    visible: Config.commandCentreBentoSurface
    cardColour: Colours.bgRaised
    cardRadius: Config.commandCentreRadius + root.boardPadding
  }

  GridLayout {
    id: board
    x: root.boardPadding
    y: root.boardPadding
    width: parent.width - root.boardPadding * 2
    // The panel gives the board its full height so the columns share it, which
    // keeps the cards roomy even when the notification list is empty.
    height: Math.max(implicitHeight, root.height - root.boardPadding * 2)
    columns: 3
    columnSpacing: Config.spaceXl
    rowSpacing: Config.spaceXl

    Card {
      id: mainCard

      Layout.row: 0
      Layout.column: 0
      Layout.fillWidth: true
      Layout.fillHeight: true
      // The fixed ratio columns take their widths; the main column gets what is
      // left after them and the two gaps.
      Layout.preferredWidth: board.width - root.notificationWidth - root.sideWidth - Config.spaceXl * 2
      cardColour: Colours.bg
      cardRadius: Config.commandCentreRadius

      ColumnLayout {
        id: mainCol
        anchors.fill: parent
        anchors.margins: Config.commandCentreCardPadding
        spacing: Config.commandCentreCardSpacing

        RowLayout {
          Layout.fillWidth: true
          spacing: Config.spaceLg

          // The bar clock and the calendar already carry the time and date, so
          // this clock only anchors the column.
          Text {
            text: ClockService.ccTimeStr
            color: Colours.fg
            font.family: Session.serifFont
            font.letterSpacing: Config.displayLetterSpacing
            font.pixelSize: Config.fontSize3xl
            font.italic: true
            Layout.alignment: Qt.AlignTop
          }

          Item { Layout.fillWidth: true }

          RowLayout {
            Layout.alignment: Qt.AlignTop
            spacing: Config.spaceSm

            StatusPills { }

            // Screenshot has no other shortcut in the shell, so it keeps its
            // own button now that the quick action tiles are gone.
            IconButton {
              icon: "󰄄"
              iconSize: Config.iconSizeMd
              iconColour: Colours.fgDim
              onClicked: {
                UiState.commandCentreVisible = false
                screenshotTimer.restart()
              }
            }
          }
        }

        CommandCentreSliders {
          Layout.fillWidth: true
        }

        Divider {
          Layout.fillWidth: true
        }

        // The media card takes the slack here, so the card does not end with a
        // gap above the power row on a tall board.
        MediaCard {
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.minimumHeight: implicitHeight
          vertical: true
          contentPadding: Config.commandCentreCardPadding
          coverCard: true
          titleSize: Config.fontSizeXl
          detailSize: Config.fontSizeLg
          showWhenIdle: Config.alwaysShowMediaCard
        }

        Divider {
          Layout.fillWidth: true
        }

        PowerButtons {
          Layout.fillWidth: true
          onActivated: UiState.commandCentreVisible = false
        }
      }
    }

    NotificationHistoryCard {
      Layout.row: 0
      Layout.column: 1
      Layout.preferredWidth: root.notificationWidth
      Layout.maximumWidth: root.notificationWidth
      Layout.fillHeight: true
      cardColour: Colours.bg
      cardRadius: Config.commandCentreRadius
    }

    ColumnLayout {
      Layout.row: 0
      Layout.column: 2
      Layout.preferredWidth: root.sideWidth
      Layout.maximumWidth: root.sideWidth
      Layout.fillHeight: true
      spacing: Config.spaceXl

      WeatherCard {
        id: weatherCard
        Layout.fillWidth: true
      }

      // The calendar hugs its square grid; the system card below takes the
      // height left over so every column ends on the board's bottom edge.
      CalendarPopup {
        id: calendar
        Layout.fillWidth: true
        cardColour: Colours.bg
        cardRadius: Config.commandCentreRadius
        cellSize: root.calendarCellSize
        cellSpacing: Config.spaceXs
        contentPadding: Config.commandCentreCardPadding
        // The digits take about a third of a cell, the month title a little more.
        cellFontSize: Math.round(root.calendarCellSize * 0.32)
        headerFontSize: Math.round(root.calendarCellSize * 0.36)
        contentSpacing: Config.commandCentreCardSpacing
      }

      SystemStatsCard {
        Layout.fillWidth: true
        Layout.fillHeight: true
      }
    }
  }
}
