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
        anchors.leftMargin: panel.isLeft ? (Config.hasLeftBar ? (Config.barWidth + Config.commandCentreMargin) : Config.commandCentreMargin) : 0
        anchors.rightMargin: !panel.isLeft ? (Config.hasRightBar ? (Config.barWidth + Config.commandCentreMargin) : Config.commandCentreMargin) : 0
      }

      Component {
        id: mainCardComponent

        Card {
          id: mainCard
          anchors.fill: parent
          cardColour: Colours.bg
          cardRadius: Config.commandCentreRadius

          property bool sinkPickerOpen: false

          Connections {
            target: Config
            function onCommandCentreVisibleChanged() {
              if (!Config.commandCentreVisible) {
                mainCard.sinkPickerOpen = false
              }
            }
          }

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

              Column {
                id: sliderCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 10

                // Output Volume Row
                RowLayout {
                  width: parent.width
                  spacing: 10

                  IconButton {
                    id: volIconBox
                    buttonSize: 32
                    icon: SystemService.volumeIcon
                    baseColour: Colours.bgSubtle
                    hoverColour: Colours.bgRaised
                    borderColour: SystemService.muted ? Colours.red : Colours.border
                    hoverBorderColour: SystemService.muted ? Colours.red : Colours.accent
                    iconColour: SystemService.muted ? Colours.red : Colours.fg
                    hoverIconColour: SystemService.muted ? Colours.red : Colours.accent
                    onClicked: SystemService.toggleMute()
                  }

                  SliderControl {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    value: SystemService.volume
                    fillColour: SystemService.muted ? Colours.red : Colours.accent
                    snapPercent: 5
                    onMoved: function(v) {
                      SystemService.setVolumeDebounced(v)
                    }
                  }

                  Text {
                    Layout.preferredWidth: 42
                    horizontalAlignment: Text.AlignRight
                    text: SystemService.volumePercent + "%"
                    color: SystemService.muted ? Colours.red : Colours.fg
                    font.family: Config.monoFont
                    font.pixelSize: 14
                  }

                  IconButton {
                    visible: Config.ccShowSinkSwitcher && SystemService.audioSinks.length > 0
                    buttonSize: 28
                    icon: mainCard.sinkPickerOpen ? "󰅃" : "󰅀"
                    iconSize: Config.iconSizeSm
                    baseColour: mainCard.sinkPickerOpen ? Colours.bgRaised : Colours.bgSubtle
                    hoverColour: Colours.bgRaised
                    borderColour: mainCard.sinkPickerOpen ? Colours.accent : Colours.border
                    hoverBorderColour: Colours.accent
                    iconColour: mainCard.sinkPickerOpen ? Colours.accent : Colours.fgMid
                    hoverIconColour: Colours.accent
                    onClicked: mainCard.sinkPickerOpen = !mainCard.sinkPickerOpen
                  }
                }

                // Expandable Audio Output Device Switcher
                Column {
                  visible: Config.ccShowSinkSwitcher && mainCard.sinkPickerOpen && SystemService.audioSinks.length > 0
                  width: parent.width
                  spacing: 6

                  Repeater {
                    model: SystemService.audioSinks

                    delegate: Pill {
                      id: sinkPill
                      required property var modelData
                      readonly property bool isCurrent: SystemService.audioSink !== null && modelData.id === SystemService.audioSink.id

                      width: sliderCol.width
                      pillHeight: 30
                      radius: Config.itemRadiusMd
                      baseColour: sinkPill.isCurrent ? Colours.bgRaised : Colours.bgSubtle
                      hoverColour: Colours.bgRaised
                      border.color: sinkPill.isCurrent ? Colours.accent : (sinkPill.hovered ? Colours.accent : Colours.border)
                      clickable: true
                      onClicked: SystemService.selectAudioSink(sinkPill.modelData)

                      RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                          text: sinkPill.isCurrent ? "󰄬" : "󰓃"
                          color: sinkPill.isCurrent ? Colours.accent : Colours.fgDim
                          font.family: Config.monoFont
                          font.pixelSize: Config.iconSizeSm
                          Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                          Layout.fillWidth: true
                          text: SystemService.sinkDisplayName(sinkPill.modelData)
                          color: sinkPill.isCurrent ? Colours.fg : Colours.fgMid
                          font.family: Config.sansFont
                          font.pixelSize: Config.fontSizeSm
                          font.bold: sinkPill.isCurrent
                          elide: Text.ElideRight
                          Layout.alignment: Qt.AlignVCenter
                        }
                      }
                    }
                  }

                  Pill {
                    id: mixerPill
                    width: sliderCol.width
                    pillHeight: 26
                    radius: Config.itemRadiusSm
                    baseColour: "transparent"
                    hoverColour: Colours.bgSubtle
                    hoverHighlight: true
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
                        color: mixerPill.hovered ? Colours.accent : Colours.fgDim
                        font.family: Config.monoFont
                        font.pixelSize: Config.iconSizeSm
                        anchors.verticalCenter: parent.verticalCenter
                      }

                      Text {
                        text: "Open Audio Mixer"
                        color: mixerPill.hovered ? Colours.fg : Colours.fgMid
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
                  width: parent.width
                  height: 1
                  color: Colours.border
                }

                // Microphone Row
                RowLayout {
                  visible: Config.ccShowMicSlider && SystemService.hasMic
                  width: parent.width
                  spacing: 10

                  IconButton {
                    buttonSize: 32
                    icon: SystemService.micIcon
                    baseColour: Colours.bgSubtle
                    hoverColour: Colours.bgRaised
                    borderColour: SystemService.micMuted ? Colours.red : Colours.border
                    hoverBorderColour: SystemService.micMuted ? Colours.red : Colours.accent
                    iconColour: SystemService.micMuted ? Colours.red : Colours.fg
                    hoverIconColour: SystemService.micMuted ? Colours.red : Colours.accent
                    onClicked: SystemService.toggleMicMute()
                  }

                  SliderControl {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    value: SystemService.micVolume
                    fillColour: SystemService.micMuted ? Colours.red : Colours.accent
                    snapPercent: 5
                    onMoved: function(v) {
                      SystemService.setMicVolumeDebounced(v)
                    }
                  }

                  Text {
                    Layout.preferredWidth: 42
                    horizontalAlignment: Text.AlignRight
                    text: SystemService.micVolumePercent + "%"
                    color: SystemService.micMuted ? Colours.red : Colours.fg
                    font.family: Config.monoFont
                    font.pixelSize: 14
                  }
                }

                // Divider if brightness is available
                Rectangle {
                  visible: Config.ccShowBrightnessSlider && SystemService.brightnessAvailable
                  width: parent.width
                  height: 1
                  color: Colours.border
                }

                // Brightness Row
                RowLayout {
                  visible: Config.ccShowBrightnessSlider && SystemService.brightnessAvailable
                  width: parent.width
                  spacing: 10

                  Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: Config.itemRadiusMd
                    color: Colours.bgSubtle
                    border.width: 1
                    border.color: Colours.border

                    Text {
                      anchors.centerIn: parent
                      text: "󰃠"
                      color: Colours.yellow
                      font.family: Config.monoFont
                      font.pixelSize: Config.iconSizeMd
                    }
                  }

                  SliderControl {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    value: SystemService.brightness
                    fillColour: Colours.yellow
                    snapPercent: 5
                    onMoved: function(v) {
                      SystemService.setBrightness(v)
                    }
                  }

                  Text {
                    Layout.preferredWidth: 42
                    horizontalAlignment: Text.AlignRight
                    text: SystemService.brightnessPercent + "%"
                    color: Colours.fg
                    font.family: Config.monoFont
                    font.pixelSize: 14
                  }
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
