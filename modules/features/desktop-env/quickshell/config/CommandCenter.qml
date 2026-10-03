pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import "Utils.js" as Utils

Scope {
  id: ccScope

  property bool closing: false
  property bool active: Config.commandCenterVisible || ccScope.closing
  property bool pendingOpen: false

  Timer {
    id: openTimeoutTimer
    // Fallback for when the cursor-query process hangs. Kept generous so a
    // normal (but not instant) WM query isn't pre-empted, which would open the
    // panel on the stale `lastActiveScreen`.
    interval: 250
    repeat: false
    onTriggered: {
      if (ccScope.pendingOpen) {
        ccScope.pendingOpen = false
        if (!Config.targetScreen) {
          Config.targetScreen = Utils.resolveActiveScreen(Config.targetScreen, Config.lastActiveScreen, Quickshell.screens)
        }
        Config.commandCenterVisible = true
      }
    }
  }

  Process {
    id: cursorQueryProc
    stdout: SplitParser {
      onRead: line => {
        if (!ccScope.pendingOpen) return
        var txt = line.trim()
        if (!txt) return

        var foundScreen = null
        try {
          if (Config.wm === "mangowc") {
            var data = JSON.parse(txt)
            if (data && data.monitor) {
              foundScreen = Utils.screenByName(data.monitor, Quickshell.screens)
            } else if (data && data.x !== undefined && data.y !== undefined) {
              foundScreen = Utils.screenAt(data.x, data.y, Quickshell.screens)
            }
          } else if (Config.wm === "hyprland") {
            var parts = txt.split(",")
            if (parts.length >= 2) {
              var hx = parseInt(parts[0].trim())
              var hy = parseInt(parts[1].trim())
              if (!isNaN(hx) && !isNaN(hy)) {
                foundScreen = Utils.screenAt(hx, hy, Quickshell.screens)
              }
            }
          } else if (Config.wm === "niri") {
            var niriData = JSON.parse(txt)
            if (niriData && niriData.name) {
              foundScreen = Utils.screenByName(niriData.name, Quickshell.screens)
            }
          }
        } catch (e) {}

        if (foundScreen) {
          Config.targetScreen = foundScreen
          Config.lastActiveScreen = foundScreen
        }

        ccScope.pendingOpen = false
        openTimeoutTimer.stop()
        if (!Config.targetScreen) {
          Config.targetScreen = Utils.resolveActiveScreen(Config.targetScreen, Config.lastActiveScreen, Quickshell.screens)
        }
        Config.commandCenterVisible = true
      }
    }

    onExited: function(exitCode, exitStatus) {
      if (ccScope.pendingOpen) {
        ccScope.pendingOpen = false
        openTimeoutTimer.stop()
        if (!Config.targetScreen) {
          Config.targetScreen = Utils.resolveActiveScreen(Config.targetScreen, Config.lastActiveScreen, Quickshell.screens)
        }
        Config.commandCenterVisible = true
      }
    }
  }

  function openOnActiveScreen(): void {
    if (Config.commandCenterVisible) return

    var cmd = null
    if (Config.wm === "mangowc") {
      cmd = ["mmsg", "get", "cursorpos"]
    } else if (Config.wm === "hyprland") {
      cmd = ["hyprctl", "cursorpos"]
    } else if (Config.wm === "niri") {
      cmd = ["niri", "msg", "--json", "focused-output"]
    }

    if (cmd) {
      ccScope.pendingOpen = true
      openTimeoutTimer.start()
      cursorQueryProc.exec(cmd)
    } else {
      Config.targetScreen = Utils.resolveActiveScreen(Config.targetScreen, Config.lastActiveScreen, Quickshell.screens)
      Config.commandCenterVisible = true
    }
  }

  IpcHandler {
    target: "command-center"
    function toggle(): void {
      if (Config.commandCenterVisible || ccScope.pendingOpen) {
        ccScope.pendingOpen = false
        openTimeoutTimer.stop()
        Config.commandCenterVisible = false
      } else {
        ccScope.openOnActiveScreen()
      }
    }

    function open(): void {
      if (!Config.commandCenterVisible) {
        ccScope.openOnActiveScreen()
      }
    }

    function close(): void {
      ccScope.pendingOpen = false
      openTimeoutTimer.stop()
      Config.commandCenterVisible = false
    }
  }

  Connections {
    target: Config
    function onCommandCenterVisibleChanged() {
      if (Config.commandCenterVisible) {
        ccScope.closing = false
        if (!Config.targetScreen) {
          Config.targetScreen = Utils.resolveActiveScreen(Config.targetScreen, Config.lastActiveScreen, Quickshell.screens)
        }
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
      property bool isPrimaryScreen: isTargetScreen
      readonly property bool isLeft: Config.commandCenterSide === "left"
      readonly property real slideDistance: isLeft ? -Config.commandCenterSlideOffset : Config.commandCenterSlideOffset
      property real panelOpacity: 0
      property real panelSlide: slideDistance

      // Brightness state
      property real brightnessPct: 0.5
      property bool brightnessAvailable: false

      Process {
        id: brightnessGetProc
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
          onDataChanged: {
            var lines = this.text.trim().split("\n")
            for (var i = 0; i < lines.length; i++) {
              var parts = lines[i].split(",")
              if (parts.length >= 4) {
                var deviceClass = parts[1]
                if (deviceClass === "backlight") {
                  var pctStr = parts[3].replace("%", "")
                  var pct = parseInt(pctStr) / 100.0
                  if (!isNaN(pct)) {
                    panel.brightnessPct = pct
                    panel.brightnessAvailable = true
                    return
                  }
                }
              }
            }
            panel.brightnessAvailable = false
          }
        }
      }

      Component.onCompleted: {
        panelOpacity = 0
        panelSlide = slideDistance
        if (panel.isTargetScreen) {
          outsideDismiss.forceActiveFocus()
          brightnessGetProc.exec(["brightnessctl", "-m"])
        }
        fadeInAnim.start()
      }

      Connections {
        target: ccScope
        function onClosingChanged() {
          if (ccScope.closing) {
            fadeInAnim.stop()
            fadeOutAnim.start()
          } else if (Config.commandCenterVisible) {
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
          NumberAnimation { target: panel; property: "panelOpacity"; to: 1; duration: Config.commandCenterAnimDuration; easing.type: Easing.OutCubic }
          NumberAnimation { target: panel; property: "panelSlide"; to: 0; duration: Config.commandCenterAnimDuration; easing.type: Easing.OutCubic }
        }
      }

      SequentialAnimation {
        id: fadeOutAnim
        ParallelAnimation {
          NumberAnimation { target: panel; property: "panelOpacity"; to: 0; duration: Config.commandCenterCloseDuration; easing.type: Easing.OutCubic }
          NumberAnimation { target: panel; property: "panelSlide"; to: panel.slideDistance; duration: Config.commandCenterCloseDuration; easing.type: Easing.OutCubic }
        }
        onFinished: {
          if (ccScope.closing) {
            ccScope.closing = false
            Config.targetScreen = null
          }
        }
      }

      // Audio tracking (only tracked on target screen to save resources)
      property var volNodes: (panel.isTargetScreen && Pipewire.ready && Pipewire.defaultAudioSink) ? [Pipewire.defaultAudioSink] : []
      PwObjectTracker { objects: panel.volNodes }
      property var volInfo: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
      property real volPct: volInfo ? volInfo.volume : 0
      property bool volMuted: volInfo ? volInfo.muted : false

      // Debounce audio volume setting to avoid spamming PipeWire
      Timer {
        id: volSetTimer
        interval: 50
        repeat: false
        property real targetVal: 0
        onTriggered: {
          if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
            Pipewire.defaultAudioSink.audio.volume = targetVal
          }
        }
      }

      // Debounce brightness setting
      Timer {
        id: brightnessSetTimer
        interval: 50
        repeat: false
        property real targetVal: 0
        onTriggered: {
          Quickshell.execDetached(["brightnessctl", "set", Math.round(targetVal * 100) + "%"])
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
            Config.commandCenterVisible = false
            event.accepted = true
          }
        }
        onClicked: {
          Config.commandCenterVisible = false
        }
      }

      // Main Card container (lazily loaded only on the target screen to avoid duplicating across displays)
      Loader {
        id: cardLoader
        active: panel.isTargetScreen
        sourceComponent: mainCardComponent
        width: Config.commandCenterWidth
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: panel.isLeft ? parent.left : undefined
        anchors.right: panel.isLeft ? undefined : parent.right
        anchors.topMargin: Config.hasTopBar ? (Config.barHeight + Config.commandCenterMargin) : Config.commandCenterMargin
        anchors.bottomMargin: Config.commandCenterMargin
        anchors.leftMargin: panel.isLeft ? (Config.hasLeftBar ? (Config.barWidth + Config.commandCenterMargin) : Config.commandCenterMargin) : 0
        anchors.rightMargin: !panel.isLeft ? (Config.hasRightBar ? (Config.barWidth + Config.commandCenterMargin) : Config.commandCenterMargin) : 0
      }

      Component {
        id: mainCardComponent

        Rectangle {
          id: mainCard
          anchors.fill: parent

          // Prevent clicks inside mainCard from propagating to outsideDismiss
          MouseArea {
            anchors.fill: parent
            onClicked: function(mouse) { mouse.accepted = true }
          }

          transform: Translate {
            x: panel.panelSlide
          }
          opacity: panel.panelOpacity

          color: Colors.bg
          border.color: Colors.border
          border.width: 1
          radius: Config.commandCenterRadius

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 16
          spacing: 14

          // --- HEADER: CLOCK & STATUS PILLS ---
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
                  text: Qt.formatDateTime(new Date(), Config.commandCenterClockFormat)
                  color: Colors.fg
                  font.family: Config.serifFont
                  font.letterSpacing: 2
                  font.pixelSize: 36
                  font.italic: true
                  Layout.alignment: Qt.AlignBaseline

                  function updateTime() {
                    var d = new Date()
                    headerTime.text = Qt.formatDateTime(d, Config.commandCenterClockFormat)
                    headerTime12.text = Qt.formatDateTime(d, "h:mm AP")
                    headerTimer.interval = 60000 - (d.getSeconds() * 1000 + d.getMilliseconds())
                    headerTimer.restart()
                  }

                  Timer {
                    id: headerTimer
                    running: panel.panelOpacity > 0
                    repeat: false
                    onTriggered: headerTime.updateTime()
                  }

                  Component.onCompleted: updateTime()
                }

                // Small 12-hour companion to the 24-hour clock
                Text {
                  id: headerTime12
                  text: Qt.formatDateTime(new Date(), "h:mm AP")
                  color: Colors.fgDim
                  font.family: Config.sansFont
                  font.pixelSize: 13
                  Layout.alignment: Qt.AlignBaseline
                }
              }

              Text {
                text: Qt.formatDateTime(new Date(), Config.commandCenterDateFormat)
                color: Colors.fgDim
                font.family: Config.sansFont
                font.pixelSize: 14
              }
            }

            Item { Layout.fillWidth: true }

            // Wi-Fi / Wired / Battery / Bluetooth Status Pills
            Row {
              spacing: 6
              Layout.alignment: Qt.AlignTop

              // Network Pill (Wi-Fi / Wired)
              NetworkWidget {
                horizontal: true
                anchors.verticalCenter: parent.verticalCenter
              }

              // Battery Pill
              BatteryWidget {
                horizontal: true
                anchors.verticalCenter: parent.verticalCenter
              }

              // Bluetooth Pill
              BluetoothWidget {
                showLabel: true
                anchors.verticalCenter: parent.verticalCenter
              }
            }
          }

          // --- SYSTEM CONTROLS CARD (VOLUME & BRIGHTNESS) ---
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: sliderCol.implicitHeight + 20
            color: Colors.bgRaised
            border.color: Colors.border
            border.width: 1
            radius: Config.commandCenterCardRadius

            Column {
              id: sliderCol
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.margins: 12
              spacing: 12

              // Volume Row
              RowLayout {
                width: parent.width
                spacing: 12

                Rectangle {
                  id: volIconBox
                  Layout.preferredWidth: 32
                  Layout.preferredHeight: 32
                  radius: 8
                  color: Colors.bgSubtle
                  border.width: 1
                  border.color: panel.volMuted ? Colors.red : Colors.border

                  Text {
                    anchors.centerIn: parent
                    text: Utils.volumeIcon(panel.volPct, panel.volMuted)
                    color: panel.volMuted ? Colors.red : Colors.fg
                    font.family: Config.monoFont
                    font.pixelSize: 16
                  }

                  MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                        Pipewire.defaultAudioSink.audio.muted = !panel.volMuted
                      }
                    }
                  }
                }

                SliderControl {
                  Layout.fillWidth: true
                  Layout.alignment: Qt.AlignVCenter
                  value: panel.volPct
                  fillColor: panel.volMuted ? Colors.red : Colors.accent
                  snapPercent: 5
                  onMoved: function(v) {
                    volSetTimer.targetVal = v
                    volSetTimer.restart()
                  }
                }

                Text {
                  Layout.preferredWidth: 42
                  horizontalAlignment: Text.AlignRight
                  text: Math.round(panel.volPct * 100) + "%"
                  color: panel.volMuted ? Colors.red : Colors.fg
                  font.family: Config.monoFont
                  font.pixelSize: 14
                }
              }

              // Divider if brightness is available
              Rectangle {
                visible: panel.brightnessAvailable
                width: parent.width
                height: 1
                color: Colors.border
              }

              // Brightness Row
              RowLayout {
                visible: panel.brightnessAvailable
                width: parent.width
                spacing: 12

                Rectangle {
                  Layout.preferredWidth: 32
                  Layout.preferredHeight: 32
                  radius: 8
                  color: Colors.bgSubtle
                  border.width: 1
                  border.color: Colors.border

                  Text {
                    anchors.centerIn: parent
                    text: "󰃠"
                    color: Colors.yellow
                    font.family: Config.monoFont
                    font.pixelSize: 16
                  }
                }

                SliderControl {
                  Layout.fillWidth: true
                  Layout.alignment: Qt.AlignVCenter
                  value: panel.brightnessPct
                  fillColor: Colors.yellow
                  snapPercent: 5
                  onMoved: function(v) {
                    panel.brightnessPct = v
                    brightnessSetTimer.targetVal = v
                    brightnessSetTimer.restart()
                  }
                }

                Text {
                  Layout.preferredWidth: 42
                  horizontalAlignment: Text.AlignRight
                  text: Math.round(panel.brightnessPct * 100) + "%"
                  color: Colors.fg
                  font.family: Config.monoFont
                  font.pixelSize: 14
                }
              }
            }
          }

          // --- MEDIA PLAYER CARD ---
          MediaCard {
            Layout.fillWidth: true
            showWhenIdle: Config.alwaysShowMediaCard
          }

          // --- NOTIFICATION HISTORY CARD ---
          Rectangle {
            id: notifCard
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Colors.bgRaised
            border.color: Colors.border
            border.width: 1
            radius: Config.commandCenterCardRadius

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
                    text: NotificationStore.dnd ? "󰂛" : "󰂚"
                    color: NotificationStore.dnd ? Colors.red : Colors.accent
                    font.family: Config.monoFont
                    font.pixelSize: 17
                    anchors.verticalCenter: parent.verticalCenter
                  }

                  Text {
                    text: "Notifications"
                    color: Colors.fg
                    font.family: Config.sansFont
                    font.pixelSize: 15
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                  }

                  // Badge count pill
                  Rectangle {
                    visible: NotificationStore.historyModel.count > 0
                    height: 18
                    radius: 9
                    color: Colors.bgSubtle
                    border.color: Colors.border
                    border.width: 1
                    implicitWidth: badgeText.width + 10
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                      id: badgeText
                      anchors.centerIn: parent
                      text: NotificationStore.historyModel.count
                      color: Colors.fgDim
                      font.family: Config.sansFont
                      font.pixelSize: 11
                    }
                  }
                }

                Item { Layout.fillWidth: true }

                // Controls: Mute toggle & Clear button
                Row {
                  spacing: 6
                  Layout.alignment: Qt.AlignVCenter

                  // Mute / DND Toggle Button
                  Rectangle {
                    height: 26
                    radius: 13
                    color: NotificationStore.dnd ? Colors.red : (muteHover.containsMouse ? Colors.bgSubtle : "transparent")
                    border.color: NotificationStore.dnd ? Colors.red : Colors.border
                    border.width: 1
                    implicitWidth: muteRow.width + 12

                    Row {
                      id: muteRow
                      anchors.centerIn: parent
                      spacing: 4

                      Text {
                        text: NotificationStore.dnd ? "󰂛" : "󰂚"
                        color: NotificationStore.dnd ? Colors.bg : (muteHover.containsMouse ? Colors.red : Colors.fgDim)
                        font.family: Config.monoFont
                        font.pixelSize: 13
                        anchors.verticalCenter: parent.verticalCenter
                      }

                      Text {
                        text: NotificationStore.dnd ? "Muted" : "Mute"
                        color: NotificationStore.dnd ? Colors.bg : (muteHover.containsMouse ? Colors.fg : Colors.fgMid)
                        font.family: Config.sansFont
                        font.pixelSize: 12
                        anchors.verticalCenter: parent.verticalCenter
                      }
                    }

                    MouseArea {
                      id: muteHover
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: NotificationStore.toggleDnd()
                    }
                  }

                  // Clear Button
                  Rectangle {
                    visible: NotificationStore.historyModel.count > 0
                    height: 26
                    radius: 13
                    color: clearHover.containsMouse ? Colors.bgSubtle : "transparent"
                    border.color: Colors.border
                    border.width: 1
                    implicitWidth: clearRow.width + 12

                    Row {
                      id: clearRow
                      anchors.centerIn: parent
                      spacing: 4

                      Text {
                        text: "󰎟"
                        color: clearHover.containsMouse ? Colors.red : Colors.fgDim
                        font.family: Config.monoFont
                        font.pixelSize: 13
                        anchors.verticalCenter: parent.verticalCenter
                      }

                      Text {
                        text: "Clear"
                        color: clearHover.containsMouse ? Colors.fg : Colors.fgMid
                        font.family: Config.sansFont
                        font.pixelSize: 12
                        anchors.verticalCenter: parent.verticalCenter
                      }
                    }

                    MouseArea {
                      id: clearHover
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: NotificationStore.clearHistory()
                    }
                  }
                }
              }

              // Divider line
              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Colors.border
              }

              // Empty State view
              Item {
                visible: NotificationStore.historyModel.count === 0
                Layout.fillWidth: true
                Layout.fillHeight: true

                Row {
                  anchors.centerIn: parent
                  spacing: 8

                  Text {
                    text: "󰂜"
                    color: Colors.fgDim
                    font.family: Config.monoFont
                    font.pixelSize: 22
                    anchors.verticalCenter: parent.verticalCenter
                  }

                  Text {
                    text: "No notifications"
                    color: Colors.fgDim
                    font.family: Config.sansFont
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }
              }

              // Notification History ListView Container
              Item {
                visible: NotificationStore.historyModel.count > 0
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
                  model: NotificationStore.historyModel

                  delegate: NotificationCard {
                    id: historyCard
                    required property var model
                    required property int index
                    width: notifHistList.width
                    notification: model.notification
                    appName: model.appName || ""
                    desktopEntry: model.desktopEntry || ""
                    summary: model.summary || ""
                    body: model.body || ""
                    appIcon: model.appIcon || ""
                    image: model.image || ""
                    urgency: model.urgency !== undefined ? model.urgency : 1
                    trackTitle: model.trackTitle || ""
                    trackArtist: model.trackArtist || ""
                    isMedia: model.isMedia !== undefined ? model.isMedia : false
                    timeStr: model.timeStr || ""

                    onDismissed: NotificationStore.removeHistoryAt(index)
                    onActionTriggered: NotificationStore.invokeActionOrFocus(model)
                  }
                }
              }
            }
          }

          // --- SYSTEM POWER/CONTROLS ---
          PowerButtons {
            Layout.fillWidth: true
            onActivated: Config.commandCenterVisible = false
          }
        }
      }
    }
  }
}
}
