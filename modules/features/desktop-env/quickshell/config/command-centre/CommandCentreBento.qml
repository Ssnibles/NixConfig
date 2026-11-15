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

  // Swallow clicks in the gaps between cards so they cannot reach the dismiss
  // backdrop. The cards themselves sit above this and handle their own input.
  MouseArea {
    anchors.fill: parent
    onClicked: function(mouse) { mouse.accepted = true }
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
      // The fixed columns take their configured widths; the main column gets
      // what is left after the board padding and the two gaps.
      Layout.preferredWidth: Config.commandCentreBentoWidth - Config.commandCentreBentoNotificationWidth - Config.commandCentreBentoSideWidth - Config.spaceXl * 2 - root.boardPadding * 2
      cardColour: Colours.bg
      cardRadius: Config.commandCentreRadius

      ColumnLayout {
        id: mainCol
        anchors.fill: parent
        anchors.margins: Config.spaceLg
        spacing: Config.spaceLg

        RowLayout {
          Layout.fillWidth: true
          spacing: Config.spaceLg

          Column {
            Layout.alignment: Qt.AlignTop
            spacing: Config.space2xs

            RowLayout {
              spacing: Config.spaceSm

              Text {
                text: ClockService.ccTimeStr
                color: Colours.fg
                font.family: Session.serifFont
                font.letterSpacing: Config.displayLetterSpacing
                font.pixelSize: Config.fontSize3xl
                font.italic: true
                Layout.alignment: Qt.AlignBaseline
              }

              Text {
                text: ClockService.ccTime12Str
                color: Colours.fgDim
                font.family: Session.sansFont
                font.pixelSize: Config.fontSizeMd
                Layout.alignment: Qt.AlignBaseline
              }
            }

            Text {
              text: ClockService.ccDateStr
              color: Colours.fgMid
              font.family: Session.sansFont
              font.pixelSize: Config.fontSizeLg
            }
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
                SystemService.takeScreenshot()
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
          artSize: Config.commandCentreBentoMediaArtSize
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
      Layout.preferredWidth: Config.commandCentreBentoNotificationWidth
      Layout.maximumWidth: Config.commandCentreBentoNotificationWidth
      Layout.fillHeight: true
      cardColour: Colours.bg
      cardRadius: Config.commandCentreRadius
    }

    ColumnLayout {
      Layout.row: 0
      Layout.column: 2
      Layout.preferredWidth: Config.commandCentreBentoSideWidth
      Layout.maximumWidth: Config.commandCentreBentoSideWidth
      Layout.fillHeight: true
      spacing: Config.spaceXl

      WeatherCard {
        Layout.fillWidth: true
      }

      // Fills the space left when the main column is taller than the weather
      // card, so every column ends on the board's bottom edge.
      CalendarPopup {
        Layout.fillWidth: true
        Layout.fillHeight: true
        cardColour: Colours.bg
        cardRadius: Config.commandCentreRadius
        cellSize: Config.space2xl
        cellSpacing: Config.spaceXs
        cellFontSize: Config.fontSizeMd
        headerFontSize: Config.fontSizeLg
        contentSpacing: Config.space2xl
      }
    }
  }
}
