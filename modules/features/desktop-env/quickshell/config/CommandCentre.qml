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

  // Gates both the output picker content and the width it needs.
  readonly property bool showSinkPicker: Config.ccShowSinkSwitcher && SystemService.audioSinks.length > 0

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
        SystemService.refreshBrightness()
      } else if (ccScope.active) {
        ccScope.closing = true
      }
    }
  }

  // Reusable slider row used for Volume, Microphone, and Brightness controls
  component ControlSliderRow: RowLayout {
    id: rowRoot
    property string icon: ""
    // Red tint for muted/unavailable states; drives all the derived colours.
    property bool alert: false
    property color accent: Colours.accent
    property color iconColour: rowRoot.alert ? Colours.red : Colours.fg
    property color iconBorderColour: rowRoot.alert ? Colours.red : Colours.border
    property color sliderFillColour: rowRoot.alert ? Colours.red : rowRoot.accent
    property color percentColour: rowRoot.alert ? Colours.red : Colours.fg
    property bool iconClickable: false
    signal iconClicked()
    property real sliderValue: 0
    signal sliderMoved(real value)
    property string percentText: ""

    width: parent ? parent.width : 0
    spacing: 10

    IconButton {
      buttonSize: 32
      icon: rowRoot.icon
      baseColour: Colours.bgSubtle
      hoverColour: Colours.bgRaised
      borderColour: rowRoot.iconBorderColour
      hoverBorderColour: rowRoot.iconBorderColour
      iconColour: rowRoot.iconColour
      hoverIconColour: rowRoot.iconColour
      enabled: rowRoot.iconClickable
      onClicked: rowRoot.iconClicked()
    }

    SliderControl {
      id: slider
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      value: rowRoot.sliderValue
      fillColour: rowRoot.sliderFillColour
      snapPercent: 5
      onMoved: function(v) { rowRoot.sliderMoved(v) }
    }

    // Fixed, right aligned column sized to 38px so the slider keeps
    // identical length regardless of 1, 2, or 3 digits.
    Text {
      id: percentLabel
      text: rowRoot.percentText
      color: rowRoot.percentColour
      font.family: Config.monoFont
      font.pixelSize: 14
      Layout.minimumWidth: 38
      Layout.preferredWidth: 38
      Layout.maximumWidth: 38
      horizontalAlignment: Text.AlignRight
      Layout.alignment: Qt.AlignVCenter
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
              id: systemControlsCard
              Layout.fillWidth: true
              implicitHeight: sliderCol.implicitHeight + 24

              property bool sinkPickerOpen: false

              ColumnLayout {
                id: sliderCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 10

                // Output Volume Row
                ControlSliderRow {
                  icon: SystemService.volumeIcon
                  alert: SystemService.muted
                  iconClickable: true
                  onIconClicked: SystemService.toggleMute()
                  sliderValue: SystemService.volume
                  onSliderMoved: function(v) {
                    SystemService.setVolumeDebounced(v)
                  }
                  percentText: SystemService.volumePercent + "%"
                }

                // Audio Output Sink Selector Pill
                Pill {
                  visible: ccScope.showSinkPicker
                  Layout.fillWidth: true
                  pillHeight: 26
                  radius: Config.itemRadiusSm
                  baseColour: Colours.bgSubtle
                  hoverColour: Colours.bgRaised
                  hoverHighlight: true
                  border.color: systemControlsCard.sinkPickerOpen ? Colours.accent : Colours.border
                  clickable: true
                  onClicked: systemControlsCard.sinkPickerOpen = !systemControlsCard.sinkPickerOpen

                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                      text: "󰓃"
                      color: systemControlsCard.sinkPickerOpen ? Colours.accent : Colours.fgDim
                      font.family: Config.monoFont
                      font.pixelSize: Config.iconSizeSm
                      Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                      Layout.fillWidth: true
                      text: SystemService.audioSink ? SystemService.sinkDisplayName(SystemService.audioSink) : "Default Output"
                      color: Colours.fg
                      font.family: Config.sansFont
                      font.pixelSize: Config.fontSizeSm
                      elide: Text.ElideRight
                      Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                      text: systemControlsCard.sinkPickerOpen ? "󰅃" : "󰅀"
                      color: systemControlsCard.sinkPickerOpen ? Colours.accent : Colours.fgDim
                      font.family: Config.monoFont
                      font.pixelSize: Config.iconSizeSm
                      Layout.alignment: Qt.AlignVCenter
                    }
                  }
                }

                // Expandable Audio Output Sink List
                ColumnLayout {
                  visible: ccScope.showSinkPicker && systemControlsCard.sinkPickerOpen
                  Layout.fillWidth: true
                  spacing: 4

                  Repeater {
                    model: SystemService.audioSinks

                    delegate: Pill {
                      id: outputPill
                      required property var modelData
                      readonly property bool isCurrent: SystemService.audioSink !== null && modelData.id === SystemService.audioSink.id

                      Layout.fillWidth: true
                      pillHeight: 28
                      radius: Config.itemRadiusSm
                      baseColour: outputPill.isCurrent ? Colours.bgSubtle : "transparent"
                      hoverColour: Colours.bgSubtle
                      hoverHighlight: true
                      border.color: outputPill.isCurrent ? Colours.accent : "transparent"
                      clickable: true
                      onClicked: {
                        SystemService.selectAudioSink(outputPill.modelData)
                        systemControlsCard.sinkPickerOpen = false
                      }

                      RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                          text: outputPill.isCurrent ? "󰄬" : "󰓃"
                          color: outputPill.isCurrent ? Colours.accent : Colours.fgDim
                          font.family: Config.monoFont
                          font.pixelSize: Config.iconSizeSm
                          Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                          Layout.fillWidth: true
                          text: SystemService.sinkDisplayName(outputPill.modelData)
                          color: outputPill.isCurrent ? Colours.fg : Colours.fgMid
                          font.family: Config.sansFont
                          font.pixelSize: Config.fontSizeSm
                          font.bold: outputPill.isCurrent
                          elide: Text.ElideRight
                          Layout.alignment: Qt.AlignVCenter
                        }
                      }
                    }
                  }

                  Pill {
                    id: outputMixerPill
                    Layout.fillWidth: true
                    pillHeight: 24
                    radius: Config.itemRadiusSm
                    baseColour: "transparent"
                    hoverColour: Colours.bgSubtle
                    hoverHighlight: true
                    border.color: "transparent"
                    clickable: true
                    onClicked: {
                      SystemService.openMixer()
                      Config.commandCentreVisible = false
                    }

                    Row {
                      anchors.centerIn: parent
                      spacing: 6

                      Text {
                        text: "󰒓"
                        color: outputMixerPill.hovered ? Colours.accent : Colours.fgDim
                        font.family: Config.monoFont
                        font.pixelSize: Config.iconSizeSm
                        anchors.verticalCenter: parent.verticalCenter
                      }

                      Text {
                        text: "Open Audio Mixer"
                        color: outputMixerPill.hovered ? Colours.fg : Colours.fgMid
                        font.family: Config.sansFont
                        font.pixelSize: Config.fontSizeXs
                        anchors.verticalCenter: parent.verticalCenter
                      }
                    }
                  }
                }

                // Divider if microphone is available
                Rectangle {
                  visible: Config.ccShowMicSlider && SystemService.hasMic
                  Layout.fillWidth: true
                  implicitHeight: 1
                  color: Colours.border
                }

                // Microphone Row
                ControlSliderRow {
                  visible: Config.ccShowMicSlider && SystemService.hasMic
                  icon: SystemService.micIcon
                  alert: SystemService.micMuted
                  iconClickable: true
                  onIconClicked: SystemService.toggleMicMute()
                  sliderValue: SystemService.micVolume
                  onSliderMoved: function(v) {
                    SystemService.setMicVolumeDebounced(v)
                  }
                  percentText: SystemService.micVolumePercent + "%"
                }

                // Divider if brightness is available
                Rectangle {
                  visible: Config.ccShowBrightnessSlider && SystemService.brightnessAvailable
                  Layout.fillWidth: true
                  implicitHeight: 1
                  color: Colours.border
                }

                // Brightness Row
                ControlSliderRow {
                  visible: Config.ccShowBrightnessSlider && SystemService.brightnessAvailable
                  icon: "󰃠"
                  iconColour: Colours.yellow
                  accent: Colours.yellow
                  sliderValue: SystemService.brightness
                  onSliderMoved: function(v) {
                    SystemService.setBrightness(v)
                  }
                  percentText: SystemService.brightnessPercent + "%"
                }
              }
            }

            // MEDIA PLAYER CARD
            MediaCard {
              Layout.fillWidth: true
              showWhenIdle: Config.alwaysShowMediaCard
            }

            // NOTIFICATION HISTORY CARD
            Card {
              id: notifCard
              Layout.fillWidth: true
              Layout.fillHeight: true

              ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                // Header Row
                RowLayout {
                  id: notifHeaderRow
                  Layout.fillWidth: true
                  spacing: 8

                  Row {
                    spacing: 6
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                      text: NotificationService.dnd ? "󰂛" : "󰂚"
                      color: NotificationService.dnd ? Colours.red : Colours.accent
                      font.family: Config.monoFont
                      font.pixelSize: 17
                      anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                      text: "Notifications"
                      color: Colours.fg
                      font.family: Config.sansFont
                      font.pixelSize: Config.fontSizeLg
                      font.bold: true
                      anchors.verticalCenter: parent.verticalCenter
                    }

                    // Badge count pill
                    Pill {
                      visible: NotificationService.historyModel.count > 0
                      pillHeight: 18
                      padding: 5
                      pillColour: Colours.bgSubtle
                      anchors.verticalCenter: parent.verticalCenter

                      Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: NotificationService.historyModel.count
                        color: Colours.fgDim
                        font.family: Config.sansFont
                        font.pixelSize: Config.fontSizeXs
                      }
                    }
                  }

                  Item { Layout.fillWidth: true }

                  // Controls: Mute toggle & Clear button
                  Row {
                    spacing: 6
                    Layout.alignment: Qt.AlignVCenter

                    // Mute / DND Toggle Button
                    Pill {
                      id: mutePill
                      pillHeight: 26
                      padding: 6
                      baseColour: NotificationService.dnd ? Colours.red : "transparent"
                      hoverColour: NotificationService.dnd ? Colours.red : Colours.bgSubtle
                      hoverHighlight: true
                      border.color: NotificationService.dnd ? Colours.red : Colours.border
                      clickable: true
                      onClicked: NotificationService.toggleDnd()

                      Row {
                        id: muteRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                          text: NotificationService.dnd ? "󰂛" : "󰂚"
                          color: NotificationService.dnd ? Colours.bg : (mutePill.hovered ? Colours.red : Colours.fgDim)
                          font.family: Config.monoFont
                          font.pixelSize: Config.iconSizeSm
                          anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                          text: NotificationService.dnd ? "Muted" : "Mute"
                          color: NotificationService.dnd ? Colours.bg : (mutePill.hovered ? Colours.fg : Colours.fgMid)
                          font.family: Config.sansFont
                          font.pixelSize: Config.fontSizeSm
                          anchors.verticalCenter: parent.verticalCenter
                        }
                      }
                    }

                    // Clear Button
                    Pill {
                      id: clearPill
                      visible: NotificationService.historyModel.count > 0
                      pillHeight: 26
                      padding: 6
                      baseColour: "transparent"
                      hoverColour: Colours.bgSubtle
                      hoverHighlight: true
                      clickable: true
                      onClicked: NotificationService.clearHistory()

                      Row {
                        id: clearRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                          text: "󰎟"
                          color: clearPill.hovered ? Colours.red : Colours.fgDim
                          font.family: Config.monoFont
                          font.pixelSize: Config.iconSizeSm
                          anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                          text: "Clear"
                          color: clearPill.hovered ? Colours.fg : Colours.fgMid
                          font.family: Config.sansFont
                          font.pixelSize: Config.fontSizeSm
                          anchors.verticalCenter: parent.verticalCenter
                        }
                      }
                    }
                  }
                }

                // Divider line
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 1
                  color: Colours.border
                }

                // Empty State view
                Item {
                  visible: NotificationService.historyModel.count === 0
                  Layout.fillWidth: true
                  Layout.fillHeight: true

                  Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                      text: "󰂜"
                      color: Colours.fgDim
                      font.family: Config.monoFont
                      font.pixelSize: 22
                      anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                      text: "No notifications"
                      color: Colours.fgDim
                      font.family: Config.sansFont
                      font.pixelSize: 14
                      anchors.verticalCenter: parent.verticalCenter
                    }
                  }
                }

                // Notification History ListView Container
                Item {
                  visible: NotificationService.historyModel.count > 0
                  Layout.fillWidth: true
                  Layout.fillHeight: true
                  clip: true

                  ListView {
                    id: notifHistList
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    anchors.topMargin: 2
                    anchors.bottomMargin: 2
                    spacing: 6
                    model: NotificationService.historyModel

                    delegate: NotificationCard {
                      width: notifHistList.width
                      isHistory: true
                    }
                  }
                }
              }
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
