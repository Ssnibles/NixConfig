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
            font.letterSpacing: 2
            font.pixelSize: 36
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
          font.pixelSize: 14
        }
      }

      Item { Layout.fillWidth: true }

      Row {
        spacing: Config.spaceSm
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
      implicitHeight: sliderCol.implicitHeight + Config.spaceLg * 2

      ColumnLayout {
        id: sliderCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Config.spaceLg
        spacing: Config.spaceMd

        // Output chips sit above or below the volume slider, whichever the
        // config asks for. Both Loaders share one definition; only one is ever
        // active, and an inactive Loader takes no space in the layout.
        Loader {
          Layout.fillWidth: true
          visible: Config.ccSinkSwitcherAboveVolume
          active: visible
          sourceComponent: sinkPickerComponent
        }

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

        Loader {
          Layout.fillWidth: true
          visible: !Config.ccSinkSwitcherAboveVolume
          active: visible
          sourceComponent: sinkPickerComponent
        }

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

      Component {
        id: sinkPickerComponent

        AudioSinkPicker { }
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
