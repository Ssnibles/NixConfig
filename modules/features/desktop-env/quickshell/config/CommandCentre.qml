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
  // (when there is one) plus the command centre margin. Shared by the card's
  // anchors and the tooltip window so the two cannot drift apart.
  readonly property int cardMargin: {
    var barSpace = (Config.commandCentreSide === "right" ? Config.hasRightBar : Config.hasLeftBar) ? Config.barWidth : 0
    return barSpace + Config.commandCentreMargin
  }

  // Side rows park their tooltip just outside the card, facing the centre.
  readonly property int tooltipEdgeOffset: ccScope.cardMargin + Config.commandCentreWidth + 8

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
    signal iconSecondaryClicked()
    property real sliderValue: 0
    signal sliderMoved(real value)
    property string percentText: ""
    // Width of the fixed percentage column, measured below.
    readonly property real percentColumnWidth: Math.ceil(percentSizer.implicitWidth)

    // Tooltip is opt-in: rows that leave tooltipWindow null show nothing.
    property var tooltipWindow: null
    property string tooltipTitle: ""
    property var tooltipDetails: []
    property int tooltipShowDelay: Config.popupShowDelay
    // Optional custom card content for the tooltip (see Tooltip.contentComponent)
    property Component tooltipContent: null
    property int tooltipContentWidth: 0
    readonly property alias tooltip: iconTip

    width: parent ? parent.width : 0
    spacing: 10

    // Hovering anywhere on the row (icon, slider or percentage) keeps the
    // row's tooltip open, not just hovering the icon.
    HoverHandler { id: rowHover }

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
      onSecondaryClicked: rowRoot.iconSecondaryClicked()

      Tooltip {
        id: iconTip
        sharedWindow: rowRoot.tooltipWindow
        icon: rowRoot.icon
        iconColour: rowRoot.iconColour
        title: rowRoot.tooltipTitle
        details: rowRoot.tooltipDetails
        contentWidth: rowRoot.tooltipContentWidth
        contentComponent: rowRoot.tooltipContent
        showDelay: rowRoot.tooltipShowDelay
        extraHover: rowHover.hovered && !slider.dragging
      }
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

    // Fixed, right aligned column sized to the widest value ("000%" covers
    // 100% and the 150% volume ceiling), so the slider keeps the same length as
    // the digits change.
    Text {
      id: percentLabel
      text: rowRoot.percentText
      color: rowRoot.percentColour
      font.family: Config.monoFont
      font.pixelSize: 14
      Layout.minimumWidth: rowRoot.percentColumnWidth
      Layout.preferredWidth: rowRoot.percentColumnWidth
      Layout.maximumWidth: rowRoot.percentColumnWidth
      horizontalAlignment: Text.AlignRight
      Layout.alignment: Qt.AlignVCenter
    }

    // Hidden twin: measures the widest value with the same font. Layouts skip
    // invisible items, so it costs no space.
    Text {
      id: percentSizer
      visible: false
      text: "000%"
      font: percentLabel.font
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
            if (ccTipWindow.isOpen) {
              ccTipWindow.closeNow()
            } else {
              Config.commandCentreVisible = false
            }
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

      // Shared tooltip window for the slider rows, parked just outside the card
      SharedTooltipWindow {
        id: ccTipWindow
        screenTarget: panel.modelData
        barSide: Config.commandCentreSide
        edgeOffset: ccScope.tooltipEdgeOffset
        // The command centre panel lives on the overlay layer, so the tooltip
        // has to as well. Otherwise the panel's full screen backdrop is stacked
        // above the tooltip and swallows clicks meant for the output picker.
        WlrLayershell.layer: WlrLayer.Overlay
      }

      // Custom tooltip content for the volume icon: the audio output picker.
      // It renders inside the shared tooltip window, so it floats beside the
      // card instead of pushing the card's contents around.
      Component {
        id: outputPickerComponent

        Card {
          width: parent ? parent.width : Config.ccOutputPickerWidth
          height: outputPickerCol.implicitHeight + Config.popupContentMargins * 2
          cardRadius: Config.popupRadius
          cardColour: Colours.bg

          ColumnLayout {
            id: outputPickerCol
            anchors.fill: parent
            anchors.margins: Config.popupContentMargins
            spacing: Config.popupContentSpacing

            Text {
              Layout.leftMargin: 2
              Layout.bottomMargin: 2
              text: "Audio Output"
              color: Colours.fgDim
              font.family: Config.sansFont
              font.pixelSize: Config.fontSizeXs
              font.letterSpacing: 0.5
            }

            Repeater {
              model: SystemService.audioSinks

              delegate: Pill {
                id: outputPill
                required property var modelData
                readonly property bool isCurrent: SystemService.audioSink !== null && modelData.id === SystemService.audioSink.id

                Layout.fillWidth: true
                pillHeight: 30
                radius: Config.itemRadiusMd
                baseColour: outputPill.isCurrent ? Colours.bgSubtle : "transparent"
                hoverColour: Colours.bgSubtle
                hoverHighlight: true
                border.color: (outputPill.isCurrent || outputPill.hovered) ? Colours.accent : Colours.border
                clickable: true
                onClicked: {
                  SystemService.selectAudioSink(outputPill.modelData)
                  ccTipWindow.closeNow()
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

            Rectangle {
              Layout.fillWidth: true
              implicitHeight: 1
              Layout.topMargin: 2
              Layout.bottomMargin: 2
              color: Colours.border
            }

            Pill {
              id: outputMixerPill
              Layout.fillWidth: true
              pillHeight: 26
              radius: Config.itemRadiusSm
              baseColour: "transparent"
              hoverColour: Colours.bgSubtle
              hoverHighlight: true
              border.color: "transparent"
              clickable: true
              onClicked: {
                SystemService.openMixer()
                ccTipWindow.closeNow()
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
        }
      }

      Component {
        id: mainCardComponent

        Card {
          id: mainCard
          anchors.fill: parent
          cardColour: Colours.bg
          cardRadius: Config.commandCentreRadius

          Connections {
            target: Config
            function onCommandCentreVisibleChanged() {
              if (!Config.commandCentreVisible && ccTipWindow.isOpen) ccTipWindow.closeNow()
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

                // Output Volume Row. Hovering the row (or right clicking the
                // icon) floats the audio output picker beside the card.
                ControlSliderRow {
                  icon: SystemService.volumeIcon
                  alert: SystemService.muted
                  iconClickable: true
                  onIconClicked: SystemService.toggleMute()
                  onIconSecondaryClicked: tooltip.openNow()
                  tooltipWindow: ccTipWindow
                  // A beat longer than the default so a quick volume drag does
                  // not throw the output picker open.
                  tooltipShowDelay: 300
                  tooltipTitle: "Volume " + SystemService.volumePercent + "%"
                  tooltipDetails: ["Left click · Mute"]
                  tooltipContent: ccScope.showSinkPicker ? outputPickerComponent : null
                  tooltipContentWidth: ccScope.showSinkPicker ? Config.ccOutputPickerWidth : 0
                  sliderValue: SystemService.volume
                  onSliderMoved: function(v) {
                    SystemService.setVolumeDebounced(v)
                  }
                  percentText: SystemService.volumePercent + "%"
                }

                // Divider if microphone is available
                Rectangle {
                  visible: Config.ccShowMicSlider && SystemService.hasMic
                  width: parent.width
                  height: 1
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
                  width: parent.width
                  height: 1
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
