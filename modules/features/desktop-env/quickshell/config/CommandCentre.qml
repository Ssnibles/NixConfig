pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "Utils.js" as Utils

Scope {
  id: ccScope

  property bool closing: false
  property bool active: Config.commandCentreVisible || ccScope.closing

  // Distance from the screen edge to the near edge of the card: the side bar
  // (when there is one) plus the command centre margin.
  readonly property int cardMargin: {
    var barSpace = (Config.commandCentreSide === "right" ? Config.hasRightBar : Config.hasLeftBar) ? Config.barWidth : 0
    return barSpace + Config.commandCentreMargin
  }

  function openOnActiveScreen(): void {
    if (Config.commandCentreVisible) return
    WmService.resolveTargetScreen(function() {
      Config.commandCentreVisible = true
    })
  }

  IpcHandler {
    target: "command-centre"
    function toggle(): void {
      if (Config.commandCentreVisible || WmService.queryingScreen) {
        WmService.cancelScreenQuery()
        Config.commandCentreVisible = false
      } else {
        ccScope.openOnActiveScreen()
      }
    }

    function open(): void {
      if (!Config.commandCentreVisible && !WmService.queryingScreen) {
        ccScope.openOnActiveScreen()
      }
    }

    function close(): void {
      WmService.cancelScreenQuery()
      Config.commandCentreVisible = false
    }
  }

  Connections {
    target: Config
    function onCommandCentreVisibleChanged() {
      if (Config.commandCentreVisible) {
        ccScope.closing = false
        if (!Config.targetScreen) {
          Config.targetScreen = Utils.resolveActiveScreen(Config.targetScreen, Config.lastActiveScreen, Quickshell.screens)
        }
        BrightnessService.refreshBrightness()
      } else if (ccScope.active) {
        ccScope.closing = true
      }
    }
  }

  Variants {
    id: root
    model: ccScope.active ? Quickshell.screens : []

    delegate: PanelWindow {
      id: panel
      required property var modelData
      screen: modelData

      // Full screen overlay for click-outside & escape dismiss
      anchors.top: true
      anchors.bottom: true
      anchors.left: true
      anchors.right: true

      color: "transparent"
      visible: true

      // Make sure it sits above windows and does not disrupt layout
      aboveWindows: true
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
      exclusionMode: ExclusionMode.Ignore

      // State for transition animation
      property bool isTargetScreen: {
        var target = Utils.resolveActiveScreen(Config.targetScreen, Config.lastActiveScreen, Quickshell.screens)
        if (!target) return false
        return panel.modelData === target || (panel.modelData && target && panel.modelData.name === target.name)
      }
      readonly property bool isLeft: Config.commandCentreSide === "left"
      readonly property real slideDistance: isLeft ? -Config.commandCentreSlideOffset : Config.commandCentreSlideOffset
      property real panelOpacity: 0
      property real panelSlide: slideDistance

      Component.onCompleted: {
        panelOpacity = 0
        panelSlide = slideDistance
        if (panel.isTargetScreen) {
          outsideDismiss.forceActiveFocus()
        }
        fadeInAnim.start()
      }

      Connections {
        target: ccScope
        function onClosingChanged() {
          if (ccScope.closing) {
            fadeInAnim.stop()
            fadeOutAnim.start()
          } else if (Config.commandCentreVisible) {
            fadeOutAnim.stop()
            panel.panelSlide = panel.slideDistance
            fadeInAnim.start()
            if (panel.isTargetScreen) outsideDismiss.forceActiveFocus()
          }
        }
      }

      SequentialAnimation {
        id: fadeInAnim
        PauseAnimation { duration: 1 }
        ParallelAnimation {
          NumberAnimation { target: panel; property: "panelOpacity"; to: 1; duration: Config.commandCentreAnimDuration; easing.type: Easing.OutCubic }
          NumberAnimation { target: panel; property: "panelSlide"; to: 0; duration: Config.commandCentreAnimDuration; easing.type: Easing.OutCubic }
        }
      }

      SequentialAnimation {
        id: fadeOutAnim
        ParallelAnimation {
          NumberAnimation { target: panel; property: "panelOpacity"; to: 0; duration: Config.commandCentreCloseDuration; easing.type: Easing.OutCubic }
          NumberAnimation { target: panel; property: "panelSlide"; to: panel.slideDistance; duration: Config.commandCentreCloseDuration; easing.type: Easing.OutCubic }
        }
        onFinished: {
          if (ccScope.closing) {
            ccScope.closing = false
            Config.targetScreen = null
            Qt.callLater(gc)
          }
        }
      }

      // Full-screen backdrop mouse area to catch clicks outside the card
      MouseArea {
        id: outsideDismiss
        anchors.fill: parent
        // Only the target screen needs hover tracking (to update the active
        // screen); every other overlay only needs to catch clicks.
        hoverEnabled: panel.isTargetScreen
        focus: panel.isTargetScreen
        onEntered: {
          Config.lastActiveScreen = panel.modelData
        }
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            Config.commandCentreVisible = false
            event.accepted = true
          }
        }
        onClicked: {
          Config.commandCentreVisible = false
        }
      }

      // Main Card container (lazily loaded only on the target screen to avoid duplicating across displays)
      Loader {
        id: cardLoader
        active: panel.isTargetScreen
        sourceComponent: mainCardComponent
        width: Config.commandCentreWidth
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: panel.isLeft ? parent.left : undefined
        anchors.right: panel.isLeft ? undefined : parent.right
        anchors.topMargin: Config.hasTopBar ? (Config.barHeight + Config.commandCentreMargin) : Config.commandCentreMargin
        anchors.bottomMargin: Config.commandCentreMargin
        anchors.leftMargin: panel.isLeft ? ccScope.cardMargin : 0
        anchors.rightMargin: panel.isLeft ? 0 : ccScope.cardMargin
      }

      Component {
        id: mainCardComponent

        Card {
          id: mainCard
          anchors.fill: parent
          cardColour: Colours.bg
          cardRadius: Config.commandCentreRadius

          // Prevent clicks inside mainCard from propagating to outsideDismiss
          MouseArea {
            anchors.fill: parent
            onClicked: function(mouse) { mouse.accepted = true }
          }

          transform: Translate {
            x: panel.panelSlide
          }
          opacity: panel.panelOpacity

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            // HEADER: CLOCK & STATUS PILLS
            RowLayout {
              Layout.fillWidth: true
              spacing: 12

              // Clock & Date (Left)
              Column {
                Layout.alignment: Qt.AlignTop
                spacing: 2

                RowLayout {
                  spacing: 6

                  Text {
                    id: headerTime
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
                    id: headerTime12
                    text: ClockService.ccTime12Str
                    color: Colours.fgDim
                    font.family: Config.sansFont
                    font.pixelSize: Config.fontSizeMd
                    Layout.alignment: Qt.AlignBaseline
                  }
                }

                Text {
                  id: headerDate
                  text: ClockService.ccDateStr
                  color: Colours.fgDim
                  font.family: Config.sansFont
                  font.pixelSize: 14
                }
              }

              Item { Layout.fillWidth: true }

              // Wi-Fi / Wired / Battery / Bluetooth Status Pills
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

            // SYSTEM CONTROLS CARD (OUTPUT VOLUME, SINK PICKER, MICROPHONE & BRIGHTNESS)
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

                // Output Volume Row
                ControlSliderRow {
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

                // Divider if microphone is available
                Divider {
                  visible: Config.ccShowMicSlider && AudioService.hasMic
                  Layout.fillWidth: true
                }

                // Microphone Row
                ControlSliderRow {
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

                // Divider if brightness is available
                Divider {
                  visible: Config.ccShowBrightnessSlider && BrightnessService.brightnessAvailable
                  Layout.fillWidth: true
                }

                // Brightness Row
                ControlSliderRow {
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

            // MEDIA PLAYER CARD
            MediaCard {
              Layout.fillWidth: true
              showWhenIdle: Config.alwaysShowMediaCard
            }

            NotificationHistoryCard {
              Layout.fillWidth: true
              Layout.fillHeight: true
            }

            // SYSTEM POWER/CONTROLS
            PowerButtons {
              Layout.fillWidth: true
              onActivated: Config.commandCentreVisible = false
            }
          }
        }
      }
    }
  }
}
