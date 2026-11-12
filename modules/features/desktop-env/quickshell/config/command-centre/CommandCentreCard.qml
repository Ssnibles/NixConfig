pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."

// Command Centre panel content: clock header, status pills, system sliders,
// media player, notification history, and power actions.
Card {
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
    anchors.margins: 16
    spacing: 14

    // Header: clock and status pills
    RowLayout {
      Layout.fillWidth: true
      spacing: 12

      Column {
        Layout.alignment: Qt.AlignTop
        spacing: 2

        RowLayout {
          spacing: 6

          Text {
            text: ClockService.ccTimeStr
            color: Colours.fg
            font.family: Config.serifFont
            font.letterSpacing: 2
            font.pixelSize: 36
            font.italic: true
            Layout.alignment: Qt.AlignBaseline
          }

          // Small 12-hour companion to the 24-hour clock
          Text {
            text: ClockService.ccTime12Str
            color: Colours.fgDim
            font.family: Config.sansFont
            font.pixelSize: Config.fontSizeMd
            Layout.alignment: Qt.AlignBaseline
          }
        }

        Text {
          text: ClockService.ccDateStr
          color: Colours.fgDim
          font.family: Config.sansFont
          font.pixelSize: 14
        }
      }

      Item { Layout.fillWidth: true }

      Row {
        spacing: 6
        Layout.alignment: Qt.AlignTop

        NetworkWidget {
          horizontal: true
          anchors.verticalCenter: parent.verticalCenter
        }

        BatteryWidget {
          horizontal: true
          anchors.verticalCenter: parent.verticalCenter
        }

        BluetoothWidget {
          showLabel: true
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }

    // System controls: output volume, sink picker, microphone and brightness
    Card {
      Layout.fillWidth: true
      implicitHeight: sliderCol.implicitHeight + 24

      ColumnLayout {
        id: sliderCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 10

        ControlSliderRow {
          Layout.fillWidth: true
          icon: AudioService.volumeIcon
          alert: AudioService.muted
          iconClickable: true
          onIconClicked: AudioService.toggleMute()
          sliderValue: AudioService.volume
          onSliderMoved: function(v) {
            AudioService.setVolumeDebounced(v)
          }
          percentText: AudioService.volumePercent + "%"
        }

        AudioSinkPicker { }

        Divider {
          visible: Config.ccShowMicSlider && AudioService.hasMic
          Layout.fillWidth: true
        }

        ControlSliderRow {
          Layout.fillWidth: true
          visible: Config.ccShowMicSlider && AudioService.hasMic
          icon: AudioService.micIcon
          alert: AudioService.micMuted
          iconClickable: true
          onIconClicked: AudioService.toggleMicMute()
          sliderValue: AudioService.micVolume
          onSliderMoved: function(v) {
            AudioService.setMicVolumeDebounced(v)
          }
          percentText: AudioService.micVolumePercent + "%"
        }

        Divider {
          visible: Config.ccShowBrightnessSlider && BrightnessService.brightnessAvailable
          Layout.fillWidth: true
        }

        ControlSliderRow {
          Layout.fillWidth: true
          visible: Config.ccShowBrightnessSlider && BrightnessService.brightnessAvailable
          icon: "󰃠"
          iconColour: Colours.yellow
          accent: Colours.yellow
          sliderValue: BrightnessService.brightness
          onSliderMoved: function(v) {
            BrightnessService.setBrightness(v)
          }
          percentText: BrightnessService.brightnessPercent + "%"
        }
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
      onActivated: Config.commandCentreVisible = false
    }
  }
}
