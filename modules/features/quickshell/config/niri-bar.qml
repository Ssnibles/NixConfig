import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Networking
import Quickshell.Services.UPower

import QtQuick
import QtQuick.Layouts
import QtQml

import "Utils.js" as Utils

ShellRoot {
  id: rootShell

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: barPanel
      required property var modelData
      screen: barPanel.modelData
      focusable: false
      aboveWindows: true

      anchors { left: true; top: true; bottom: true }
      implicitWidth: 38
      exclusionMode: ExclusionMode.Auto
      color: Colors.bg

      // Thin right border to separate the bar from windows
      Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: Colors.border
      }

      readonly property string uiFont: "JetBrainsMono Nerd Font"
      property string timeStr: ""

      // --- Precise Time Update ---
      function updateTime() {
        var d = new Date()
        barPanel.timeStr = Qt.formatTime(d, "hh:mm")
        timeTimer.interval = 60000 - (d.getSeconds() * 1000 + d.getMilliseconds())
        timeTimer.restart()
      }

      Timer {
        id: timeTimer
        running: true
        repeat: false
        onTriggered: barPanel.updateTime()
      }

      Component.onCompleted: updateTime()

      // --- Niri Workspaces & Window Title State ---
      property var allWorkspaces: []
      property string currentTitle: ""

      Process {
        id: niriEvents
        command: ["niri", "msg", "--json", "event-stream"]
        running: true

        stdout: SplitParser {
          onRead: line => {
            var cleanLine = line.trim()
            if (!cleanLine.startsWith("{")) return
            try {
              var event = JSON.parse(cleanLine)
              barPanel.handleEvent(event)
            } catch (e) {}
          }
        }
      }

      function handleEvent(event) {
        if (event.WorkspacesChanged) {
          var wsList = event.WorkspacesChanged.workspaces
          wsList.sort((a, b) => a.idx - b.idx)
          barPanel.allWorkspaces = wsList
        } else if (event.WorkspaceActivated) {
          var activated = event.WorkspaceActivated
          var outputName = null
          for (var i = 0; i < barPanel.allWorkspaces.length; i++) {
            if (barPanel.allWorkspaces[i].id === activated.id) {
              outputName = barPanel.allWorkspaces[i].output
              break
            }
          }
          if (!outputName) return
          var updated = []
          for (var i = 0; i < barPanel.allWorkspaces.length; i++) {
            var ws = barPanel.allWorkspaces[i]
            if (ws.output === outputName) {
              updated.push({
                id: ws.id, idx: ws.idx, name: ws.name, output: ws.output,
                is_active: ws.id === activated.id,
                is_focused: activated.focused ? ws.id === activated.id : ws.is_focused,
                is_urgent: ws.is_urgent
              })
            } else {
              updated.push(ws)
            }
          }
          barPanel.allWorkspaces = updated
        } else if (event.WindowFocused !== undefined) {
          var focus = event.WindowFocused
          if (focus) {
            barPanel.currentTitle = barPanel._formatActiveTitle(focus.title, focus.app_id)
          } else {
            barPanel.currentTitle = ""
          }
        }
      }

      function _formatActiveTitle(title, appId) {
        var appName = Utils.prettifyAppName(appId)
        title = title || ""

        if (title.endsWith(" — Zen Browser")) {
          title = title.slice(0, title.length - " — Zen Browser".length)
          appName = "Zen"
        } else if (title.endsWith(" — Mozilla Firefox")) {
          title = title.slice(0, title.length - " — Mozilla Firefox".length)
          appName = "Firefox"
        }

        if (title.endsWith(" - nvim")) {
          title = title.slice(0, title.length - " - nvim".length)
          appName = "Neovim"
        } else if (title.endsWith(" - foot")) {
          title = title.slice(0, title.length - " - foot".length)
        }

        title = String(title).trim()
        if (appName && title && title !== appName) return appName + ": " + title
        return appName || title
      }

      function focusWorkspace(id) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", id.toString()])
      }

      property var wsForOutput: {
        var result = []
        var wsList = barPanel.allWorkspaces
        var outputName = barPanel.modelData.name
        for (var i = 0; i < wsList.length; i++) {
          if (wsList[i].output === outputName)
            result.push(wsList[i])
        }
        return result
      }

      // --- Volume Service (Pipewire) ---
      property var volNodes: Pipewire.ready && Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
      PwObjectTracker { objects: barPanel.volNodes }
      property var volInfo: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
      property real volPct: volInfo ? volInfo.volume : 0
      property bool volMuted: volInfo ? volInfo.muted : false

      // --- WiFi Service (Networking) ---
      property var wifiDev: Utils.findFirst(Networking.devices.values, function(d) { return d.type === DeviceType.Wifi })
      property var wifiNet: Utils.findFirst(wifiDev ? wifiDev.networks.values : [], function(n) { return n.connected })
      property string wifiSsid: wifiNet ? wifiNet.name : ""
      property string wifiIcon: Utils.wifiIcon(wifiNet ? wifiNet.signalStrength : 0, !!wifiNet)

      // --- Battery Service (UPower) ---
      property var batDevice: {
        var count = UPower.devices.count
        for (var i = 0; i < count; i++) {
          var d = UPower.devices.get(i)
          if (d.isLaptopBattery && d.ready) return d
        }
        return UPower.displayDevice && UPower.displayDevice.ready ? UPower.displayDevice : null
      }

      readonly property bool batPresent: {
        var count = UPower.devices.count
        for (var i = 0; i < count; i++) {
          var d = UPower.devices.get(i)
          if (d.isLaptopBattery && d.ready) return true
        }
        return false
      }
      readonly property int batPct: batDevice ? Math.round(batDevice.percentage * 100) : 0
      readonly property bool batCharging: batDevice && batDevice.state === UPowerDeviceState.Charging
      readonly property bool batPlugged: batDevice && batDevice.state === UPowerDeviceState.FullyCharged
      readonly property int batState: batDevice ? batDevice.state : UPowerDeviceState.Unknown

      property string batIcon: Utils.batteryIcon(batPct, batCharging, batPlugged, batPresent)
      property color batColor: {
        if (!batPresent) return Colors.fg
        if (batCharging || batPlugged) return Colors.green
        if (batPct <= 15) return Colors.red
        if (batPct <= 30) return Colors.yellow
        return Colors.fg
      }

      // --- Media Service (MPRIS) ---
      property var mediaPlayers: Mpris.players.values
      property var mediaPlayer: {
        var playing = Utils.findFirst(mediaPlayers, function(p) { return p.isPlaying })
        return playing ? playing : Utils.findFirst(mediaPlayers, function(p) {
          return p.playbackState === MprisPlaybackState.Paused
        })
      }
      property string mediaText: mediaPlayer
        ? (mediaPlayer.trackArtist
          ? mediaPlayer.trackTitle + " — " + mediaPlayer.trackArtist
          : mediaPlayer.trackTitle)
        : ""
      property bool hasMedia: mediaText !== ""
      property int mediaTick: 0
      property real mediaLastPosition: 0
      property real mediaLastLength: 0
      property int mediaResetToken: 0
      property real mediaWallClock: 0
      function _resetMediaTiming(pos, len) {
        barPanel.mediaLastPosition = Math.max(0, pos || 0)
        barPanel.mediaLastLength = Math.max(0, len || 0)
        barPanel.mediaWallClock = Date.now() / 1000
        barPanel.mediaTick = 0
        barPanel.mediaResetToken++
      }
      function _updateMediaPosition(pos, len) {
        var p = Math.max(0, pos || 0)
        var l = Math.max(0, len || 0)
        if (p + 0.5 < barPanel.mediaLastPosition) {
          barPanel._resetMediaTiming(p, l)
          return
        }
        barPanel.mediaLastPosition = p
        barPanel.mediaLastLength = l
        barPanel.mediaWallClock = Date.now() / 1000
      }
      property real mediaEstimatedPosition: {
        var _ = barPanel.mediaTick
        var __ = barPanel.mediaResetToken
        if (!mediaPlayer) return barPanel.mediaLastPosition
        var elapsed = Date.now() / 1000 - barPanel.mediaWallClock
        return barPanel.mediaLastPosition + (mediaPlayer.isPlaying ? elapsed : 0)
      }

      property real mediaProgress: {
        var _ = barPanel.mediaTick
        var __ = barPanel.mediaResetToken
        if (!mediaPlayer || barPanel.mediaLastLength <= 0) return 0
        return Math.min(1, Math.max(0, barPanel.mediaEstimatedPosition / barPanel.mediaLastLength))
      }
      onMediaPlayerChanged: {
        if (!mediaPlayer) {
          barPanel._resetMediaTiming(0, 0)
          return
        }
        barPanel._resetMediaTiming(mediaPlayer.position, mediaPlayer.length)
      }

      Connections {
        target: barPanel.mediaPlayer
        ignoreUnknownSignals: true
        function onPositionChanged() {
          if (!barPanel.mediaPlayer) return
          barPanel._updateMediaPosition(barPanel.mediaPlayer.position, barPanel.mediaPlayer.length)
        }
        function onLengthChanged() {
          if (!barPanel.mediaPlayer) return
          barPanel.mediaLastLength = Math.max(0, barPanel.mediaPlayer.length || 0)
        }
        function onTrackChanged() {
          if (!barPanel.mediaPlayer) return
          barPanel._resetMediaTiming(barPanel.mediaPlayer.position, barPanel.mediaPlayer.length)
        }
      }

      Timer {
        id: tickTimer
        interval: 300
        running: barPanel.mediaPlayer && barPanel.mediaPlayer.isPlaying
        repeat: true
        onTriggered: {
          if (barPanel.mediaPlayer) {
            barPanel._updateMediaPosition(barPanel.mediaPlayer.position, barPanel.mediaPlayer.length)
          }
          barPanel.mediaTick++
        }
      }

      function _focusMediaPlayer() {
        if (!barPanel.mediaPlayer) return
        var entry = barPanel.mediaPlayer.desktopEntry || barPanel.mediaPlayer.name || ""
        if (!entry) return
        var cmd = "niri msg --json windows | jq -r '.[] | select((.app_id | ascii_downcase) == \"" + entry.toLowerCase() + "\") | .id' | head -n1"
        var fullCmd = "id=$(" + cmd + "); if [ -n \"$id\" ]; then niri msg action focus-window --id \"$id\"; fi"
        Quickshell.execDetached(["sh", "-c", fullCmd])
      }

      // --- Bar Layout Content ---
      Item {
        id: barContent
        anchors.fill: parent
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        // Top Section: Clock/Time and Rotated Window Title
        Column {
          id: topCol
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          spacing: 12

          // Stacked Clock
          Column {
            id: topTime
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: -2

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: barPanel.timeStr ? barPanel.timeStr.split(":")[0] : ""
              color: Colors.accent
              font.family: barPanel.uiFont
              font.pixelSize: 13
              font.bold: true
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: barPanel.timeStr ? barPanel.timeStr.split(":")[1] : ""
              color: Colors.fg
              font.family: barPanel.uiFont
              font.pixelSize: 13
              font.bold: true
            }
          }

          // Rotated Window Title Pill
          Item {
            id: titleContainer
            width: 22
            height: Math.min(titleLabel.implicitWidth, 120)
            anchors.horizontalCenter: parent.horizontalCenter
            visible: barPanel.currentTitle !== ""
            clip: true

            Text {
              id: titleLabel
              text: barPanel.currentTitle
              color: Colors.fgMid
              font.family: barPanel.uiFont
              font.pixelSize: 11
              font.italic: true

              transform: [
                Rotation {
                  angle: 270
                  origin.x: 0
                  origin.y: 0
                },
                Translate {
                  x: 0
                  y: titleLabel.implicitWidth
                }
              ]

              width: titleLabel.implicitWidth
              height: 22
            }
          }
        }

        // Center Section: Workspaces
        Column {
          id: centerWorkspaces
          anchors.centerIn: parent
          spacing: 6

          Repeater {
            model: barPanel.wsForOutput
            delegate: Rectangle {
              required property var modelData
              property bool isFocused: modelData && modelData.is_focused
              property bool isActive: modelData && modelData.is_active
              property bool isUrgent: modelData && modelData.is_urgent

              width: 10
              height: isFocused ? 26 : 10
              radius: width / 2
              color: isFocused ? Colors.accent : (isUrgent ? Colors.red : (isActive ? Colors.fgMid : Colors.fgDim))

              Behavior on height {
                SpringAnimation { spring: 10; damping: 0.3 }
              }
              Behavior on color {
                ColorAnimation { duration: 200; easing.type: Easing.InOutQuad }
              }

              MouseArea {
                anchors.fill: parent
                onClicked: barPanel.focusWorkspace(modelData.id)
              }
            }
          }
        }

        // Bottom Section: Media, Volume, Network, Battery
        Column {
          id: bottomCol
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.right: parent.right
          spacing: 12

          // Native Media Pill
            Pill {
              id: mediaPill
              visible: barPanel.hasMedia
              padding: 4
              anchors.horizontalCenter: parent.horizontalCenter
              height: mediaLayout.implicitHeight + 12
              radius: width / 2

              Column {
                id: mediaLayout
                spacing: 8
                anchors.top: parent.top
                anchors.topMargin: 6
                anchors.horizontalCenter: parent.horizontalCenter

                Item {
                  id: spinningContainer
                  width: 16
                  height: 16
                  anchors.horizontalCenter: parent.horizontalCenter

                  Text {
                    id: mediaIcon
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: barPanel.mediaPlayer && barPanel.mediaPlayer.isPlaying ? "󰎈" : "󰎆"
                    color: barPanel.mediaPlayer && barPanel.mediaPlayer.isPlaying ? Colors.accent : Colors.fgDim
                    font.pixelSize: 12
                    font.family: barPanel.uiFont
                  }

                  NumberAnimation on rotation {
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 4000
                    running: barPanel.mediaPlayer && barPanel.mediaPlayer.isPlaying
                  }
                }

                // Vertical progress bar
                Item {
                  width: 6
                  height: 36
                  anchors.horizontalCenter: parent.horizontalCenter

                  Rectangle {
                    anchors.fill: parent
                    radius: 3
                    color: Colors.bgSubtle

                    Rectangle {
                      anchors.bottom: parent.bottom
                      anchors.left: parent.left
                      anchors.right: parent.right
                      height: parent.height * barPanel.mediaProgress
                      radius: 3
                      color: Colors.accent
                    }
                  }
                }
              }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              onClicked: function(mouse) {
                if (!barPanel.mediaPlayer) return
                if (mouse.button === Qt.RightButton) {
                  barPanel._focusMediaPlayer()
                } else {
                  barPanel.mediaPlayer.playPause()
                }
              }
              onWheel: function(wheel) {
                if (!barPanel.mediaPlayer) return
                if (wheel.angleDelta.y > 0) {
                  if (barPanel.mediaPlayer.canGoNext) barPanel.mediaPlayer.next()
                } else if (wheel.angleDelta.y < 0) {
                  if (barPanel.mediaPlayer.canGoPrevious) barPanel.mediaPlayer.previous()
                }
                wheel.accepted = true
              }
            }

            Tooltip {
              target: mediaPill
              sharedWindow: sharedTipWindow
              icon: barPanel.mediaPlayer && barPanel.mediaPlayer.isPlaying ? "󰎈" : "󰎆"
              iconColor: Colors.accent
              title: barPanel.mediaPlayer ? barPanel.mediaPlayer.identity : "Media Player"
              details: {
                var d = []
                if (barPanel.mediaPlayer) {
                  d.push(barPanel.mediaText)
                  var p = Math.round(barPanel.mediaEstimatedPosition)
                  var l = Math.round(barPanel.mediaLastLength)
                  if (l > 0) {
                    d.push(Utils.formatTime(p) + " / " + Utils.formatTime(l))
                  }
                }
                d.push("Left click · Play/Pause")
                d.push("Right click · Focus app")
                d.push("Scroll · Next/Prev")
                return d
              }
            }
          }

          // Volume Widget
          Item {
            id: volWidget
            width: parent.width
            height: volLayout.height + 8
            anchors.horizontalCenter: parent.horizontalCenter

            Tooltip {
              id: volTooltip
              sharedWindow: sharedTipWindow
              icon: Utils.volumeIcon(barPanel.volPct, barPanel.volMuted)
              iconColor: barPanel.volMuted ? Colors.red : Colors.accent
              title: {
                var pct = Math.round(barPanel.volPct * 100)
                return barPanel.volMuted ? "Muted" : ("Volume " + pct + "%")
              }
              details: ["Left click · Mute", "Right click · Mixer", "Scroll · Adjust"]
            }

            Rectangle {
              id: volBg
              anchors.fill: parent
              radius: 4
              color: volTooltip.hovered ? Colors.bgRaised : "transparent"
              Behavior on color { ColorAnimation { duration: 100 } }
            }

            Column {
              id: volLayout
              anchors.top: parent.top
              anchors.topMargin: 4
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: 4

              Item {
                width: 8
                height: 32
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                  anchors.fill: parent
                  radius: 4
                  color: Colors.bgSubtle
                  Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: parent.height * Math.min(1.0, barPanel.volPct)
                    radius: 4
                    color: barPanel.volMuted ? Colors.red : Colors.accent
                    Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                  }
                }
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Utils.volumeIcon(barPanel.volPct, barPanel.volMuted)
                color: barPanel.volMuted ? Colors.red : Colors.fg
                font.family: barPanel.uiFont
                font.pixelSize: 12
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Math.round(barPanel.volPct * 100) + "%"
                color: barPanel.volMuted ? Colors.red : Colors.fg
                font.family: barPanel.uiFont
                font.pixelSize: 10
                font.bold: true
              }
            }

            MouseArea {
              id: volMouse
              anchors.fill: parent
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                  Quickshell.execDetached(["pavucontrol"])
                } else if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                  Pipewire.defaultAudioSink.audio.muted = !barPanel.volMuted
                }
              }
              onWheel: function(wheel) {
                if (!Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio) return
                var step = 0.05
                var dir = wheel.angleDelta.y > 0 ? 1 : -1
                Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1.5, barPanel.volPct + dir * step))
              }
            }
          }

          // WiFi Pill Widget
          Pill {
            id: wifiPill
            padding: 4
            anchors.horizontalCenter: parent.horizontalCenter

            Tooltip {
              target: wifiPill
              sharedWindow: sharedTipWindow
              icon: barPanel.wifiIcon
              iconColor: barPanel.wifiNet ? Colors.accent : Colors.fgDim
              title: barPanel.wifiNet ? barPanel.wifiNet.name : "Disconnected"
              details: {
                var d = []
                if (barPanel.wifiNet) d.push("Signal · " + Math.round(barPanel.wifiNet.signalStrength * 100) + "%")
                d.push("Right click · nmtui")
                return d
              }
            }

            Text {
              text: barPanel.wifiIcon
              color: barPanel.wifiNet ? Colors.accent : Colors.fgDim
              font.family: barPanel.uiFont
              font.pixelSize: 12
              anchors.centerIn: parent
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              acceptedButtons: Qt.RightButton
              onClicked: Quickshell.execDetached(["kitty", "-e", "nmtui"])
            }
          }

          // Battery Pill Widget
          Pill {
            id: batteryPill
            visible: barPanel.batPresent
            padding: 4
            anchors.horizontalCenter: parent.horizontalCenter

            Tooltip {
              target: batteryPill
              sharedWindow: sharedTipWindow
              icon: barPanel.batIcon
              iconColor: barPanel.batColor
              title: {
                var pct = Math.round(barPanel.batPct)
                var state
                switch (barPanel.batState) {
                  case UPowerDeviceState.Charging:        state = "Charging"; break
                  case UPowerDeviceState.FullyCharged:    state = "Plugged in"; break
                  case UPowerDeviceState.PendingCharge:   state = "Pending charge"; break
                  case UPowerDeviceState.PendingDischarge:state = "Pending discharge"; break
                  case UPowerDeviceState.Empty:           state = "Empty"; break
                  default:                                state = "Discharging"; break
                }
                return pct + "% · " + state
              }
              details: {
                var d = []
                if (barPanel.batDevice) {
                  if (barPanel.batCharging && barPanel.batDevice.timeToFull > 0) {
                    var mins = Math.round(barPanel.batDevice.timeToFull / 60)
                    var h = Math.floor(mins / 60)
                    var m = mins % 60
                    d.push((h > 0 ? h + "h " : "") + m + "m until full")
                  } else if (!barPanel.batCharging && !barPanel.batPlugged && barPanel.batDevice.timeToEmpty > 0) {
                    var mins2 = Math.round(barPanel.batDevice.timeToEmpty / 60)
                    var h2 = Math.floor(mins2 / 60)
                    var m2 = mins2 % 60
                    d.push((h2 > 0 ? h2 + "h " : "") + m2 + "m remaining")
                  }
                }
                return d
              }
            }

            Column {
              anchors.centerIn: parent
              spacing: 2

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: barPanel.batIcon
                color: barPanel.batColor
                font.family: barPanel.uiFont
                font.pixelSize: 12
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Math.round(barPanel.batPct) + "%"
                color: barPanel.batColor
                font.family: barPanel.uiFont
                font.pixelSize: 8
              }
            }
          }
        }
      }

      // --- Shared Tooltip Side Window ---
      PanelWindow {
        id: sharedTipWindow
        screen: barPanel.modelData
        property var _active: null
        property bool recentlyActive: false

        on_ActiveChanged: {
          if (_active !== null) {
            recentlyActive = true
            recentTimer.stop()
          } else {
            recentTimer.restart()
          }
        }

        Timer {
          id: recentTimer
          interval: 500
          onTriggered: sharedTipWindow.recentlyActive = false
        }

        visible: _active !== null
        focusable: false
        aboveWindows: true
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        anchors { top: true; bottom: true; left: true }
        margins { left: 46 }
        implicitWidth: _active ? _active.maxWidth : 280

        mask: Region {
          item: tipLoader
        }

        Loader {
          id: tipLoader
          active: sharedTipWindow._active !== null

          property var _src: sharedTipWindow._active
          property real _tgtCenterY: _src && _src.target ? _src.target.mapToItem(null, 0, _src.target.height / 2).y : 0

          x: 0
          y: _active ? Math.round(Math.max(6, Math.min(_tgtCenterY - height / 2, sharedTipWindow.height - height - 6))) : 0
          width: item ? item.width : 0
          height: item ? item.height : 0

          sourceComponent: Component {
            Rectangle {
              id: card
              property var _src: tipLoader._src
              
              x: 0
              y: 0
              width: _src ? _src.maxWidth : 280
              implicitHeight: content.implicitHeight + 24
              height: implicitHeight
              radius: 8
              color: Colors.bgRaised
              antialiasing: true
              border.width: 1
              border.color: Colors.border
              opacity: _src && _src.tipVisible ? 1 : 0
              Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

              Column {
                id: content
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 6

                Row {
                  spacing: 8
                  Text {
                    text: _src ? _src.icon : ""
                    color: _src ? _src.iconColor : Colors.fg
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  Text {
                    text: _src ? _src.title : ""
                    color: Colors.fg
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }

                Rectangle {
                  visible: _src ? _src.details.length > 0 : false
                  width: parent.width
                  height: 1
                  color: Colors.border
                }

                Repeater {
                  model: _src ? _src.details : []
                  delegate: Text {
                    required property var modelData
                    text: modelData
                    color: Colors.fgMid
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
