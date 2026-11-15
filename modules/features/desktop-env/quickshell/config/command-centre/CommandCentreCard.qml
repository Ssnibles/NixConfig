pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."

// Command Centre panel content for the sidebar layout: clock header, status
// pills, system sliders, media player, notification history, and power actions.
Card {
  id: root

  anchors.fill: parent
  cardColour: Colours.bg
  cardRadius: Config.commandCentreRadius

  // Swallow clicks inside the card so they cannot reach the dismiss backdrop.
  MouseArea {
    anchors.fill: parent
    onClicked: function(mouse) { mouse.accepted = true }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Config.spaceLg
    spacing: Config.spaceLg

    // Header: clock and status pills
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
            font.pixelSize: Config.fontSize2xl
            font.italic: true
            Layout.alignment: Qt.AlignBaseline
          }

          // Small 12-hour companion to the 24-hour clock
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
          color: Colours.fgDim
          font.family: Session.sansFont
          font.pixelSize: Config.fontSizeMd
        }
      }

      Item { Layout.fillWidth: true }

      StatusPills {
        showBluetoothLabel: true
        Layout.alignment: Qt.AlignTop
      }
    }

    // System controls: output volume, sink picker, microphone and brightness
    Card {
      Layout.fillWidth: true
      implicitHeight: sliders.implicitHeight + Config.spaceLg * 2

      CommandCentreSliders {
        id: sliders
        anchors.fill: parent
        anchors.margins: Config.spaceLg
      }
    }

    // Media player
    MediaCard {
      Layout.fillWidth: true
      showWhenIdle: Config.alwaysShowMediaCard
    }

    NotificationHistoryCard {
      Layout.fillWidth: true
      Layout.fillHeight: true
    }

    // Power actions
    PowerButtons {
      Layout.fillWidth: true
      onActivated: UiState.commandCentreVisible = false
    }
  }
}
