import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Networking
import Quickshell.Services.UPower

import QtQuick
import QtQuick.Layouts
import QtQml

PanelWindow {
  id: barPanel
  Colors { id: colors }
  focusable: false
  aboveWindows: true

  anchors { top: true; left: true; right: true }
  implicitHeight: barHeight
  exclusionMode: ExclusionMode.Auto
  color: colors.bg

  property string timeStr: ""
  property string uiFont: "JetBrains Mono"
  property int barHeight: 30
  property int tooltipGap: 10
  property int tooltipPadding: 10
  property int tooltipMargin: 6
  property int tooltipMaxWidth: 320

  function updateTime() {
    var d = new Date();
    barPanel.timeStr = Qt.formatTime(d, "hh:mm");
    var ms = 60000 - (d.getSeconds() * 1000 + d.getMilliseconds());
    timeTimer.interval = ms;
    timeTimer.restart();
  }

  Timer {
    id: timeTimer
    running: true
    repeat: false
    onTriggered: barPanel.updateTime()
  }

  Component.onCompleted: {
    updateTime();
  }

  function formatTitle(t) {
    return t
    .replace(/ — Mozilla Firefox$/, "")
    .replace(/ — Zen Browser$/, "Zen")
    .replace(/ - nvim$/, "Neovim")
    .replace(/ - foot$/, "");
  }

  function findFirst(list, predicate) {
    for (var i = 0; i < list.length; i++) {
      if (predicate(list[i])) return list[i];
    }
    return null;
  }

  function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
  }

  function tooltipX(width) {
    if (!tooltipAnchor) return 0;
    var pos = tooltipAnchor.mapToItem(barContent, 0, 0);
    var x = barContent.x + pos.x + (tooltipAnchor.width - width) / 2;
    return Math.round(clamp(x, tooltipMargin, barPanel.width - width - tooltipMargin));
  }

  function escapeRegex(value) {
    return String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  }

  function focusMediaPlayer() {
    if (!barPanel.mediaPlayer) return;

    var entry = barPanel.mediaPlayer.desktopEntry || barPanel.mediaPlayer.name || "";
    if (entry) {
      var lowerEntry = entry.toLowerCase();
      var toplevels = Hyprland.toplevels.values;
      for (var i = 0; i < toplevels.length; i++) {
        var tl = toplevels[i];
        if (tl.lastIpcObject && tl.lastIpcObject.class) {
          if (tl.lastIpcObject.class.toLowerCase() === lowerEntry) {
            Hyprland.dispatch("focuswindow address:0x" + tl.address);
            return;
          }
        }
      }
      Hyprland.dispatch("focuswindow class:(?i)^" + escapeRegex(entry) + "$");
      return;
    }

    var identity = barPanel.mediaPlayer.identity || "";
    if (identity) {
      var toplevels = Hyprland.toplevels.values;
      for (var i = 0; i < toplevels.length; i++) {
        var tl = toplevels[i];
        if (tl.title && tl.title.indexOf(identity) !== -1) {
          Hyprland.dispatch("focuswindow address:0x" + tl.address);
          return;
        }
      }
      var pattern = escapeRegex(identity).replace(/\s+/g, "\\s+");
      Hyprland.dispatch("focuswindow title:(?i)" + pattern);
    }
  }

  property string currentTitle: Hyprland.activeToplevel ? formatTitle(Hyprland.activeToplevel.title) : ""

  function switchWs(id) {
    Hyprland.dispatch("workspace " + id);
  }

  // -- Volume --
  property var volNodes: Pipewire.ready && Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
  PwObjectTracker { objects: barPanel.volNodes }
  property var volInfo: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
  property real volPct: volInfo ? volInfo.volume : 0
  property bool volMuted: volInfo ? volInfo.muted : false
  property string volTooltip: {
    var pct = Math.round(barPanel.volPct * 100);
    var state = barPanel.volMuted ? "Muted" : ("Volume " + pct + "%");
    return state + "\nLeft click: mute\nRight click: pavucontrol\nScroll: adjust";
  }
  Process { id: volProc; command: ["pavucontrol"] }

  // -- WiFi --
  property var wifiDev: findFirst(Networking.devices.values, function(d) {
      return d.type === DeviceType.Wifi;
  })
  property var wifiNet: findFirst(wifiDev ? wifiDev.networks.values : [], function(n) {
      return n.connected;
  })
  property string wifiSsid: wifiNet ? wifiNet.name : ""
  property string wifiTooltip: {
    if (!wifiNet) return "Wi-Fi disconnected\nRight click: nmtui";
    var strength = Math.round(wifiNet.signalStrength * 100);
    return wifiNet.name + " (" + strength + "%)\nRight click: nmtui";
  }
  property string wifiIcon: {
    if (!wifiNet) return "󰤯";
    var s = wifiNet.signalStrength;
    if (s < 0.2) return "󰤟";
    if (s < 0.4) return "󰤢";
    if (s < 0.6) return "󰤥";
    return "󰤨";
  }
  Process { id: wifiProc; command: ["sh", "-lc", "foot -e nmtui"] }

  // -- Battery (UPower) --
  function batDevice() {
    var count = UPower.devices.count;
    for (var i = 0; i < count; i++) {
      var d = UPower.devices.get(i);
      if (d.isLaptopBattery && d.ready) return d;
    }
    return UPower.displayDevice && UPower.displayDevice.ready ? UPower.displayDevice : null;
  }

  readonly property bool batPresent: {
    var count = UPower.devices.count;
    if (count > 0) return true;
    return UPower.displayDevice && UPower.displayDevice.ready;
  }
  readonly property int batPct: {
    var d = batDevice();
    return d ? Math.round(d.percentage * 100) : 0;
  }
  readonly property bool batCharging: {
    var d = batDevice();
    return d && d.state === UPowerDeviceState.Charging;
  }
  readonly property bool batPlugged: {
    var d = batDevice();
    return d && d.state === UPowerDeviceState.FullyCharged;
  }
  readonly property int batState: batDevice() ? batDevice().state : UPowerDeviceState.Unknown
  property string batIcon: {
    if (!batPresent) return "";
    if (batCharging) return "󰂄";
    if (batPlugged) return "󰚥";
    var p = batPct;
    if (p <= 10) return "󰁺";
    if (p <= 20) return "󰁻";
    if (p <= 30) return "󰁼";
    if (p <= 40) return "󰁽";
    if (p <= 50) return "󰁾";
    if (p <= 60) return "󰁿";
    if (p <= 70) return "󰂀";
    if (p <= 80) return "󰁂";
    if (p <= 90) return "󰂂";
    return "󰁹";
  }
  property string batTooltip: {
    if (!batPresent) return "";
    var pct = Math.round(batPct);
    var states = {
      [UPowerDeviceState.Charging]: "Charging",
      [UPowerDeviceState.FullyCharged]: "Plugged in",
      [UPowerDeviceState.PendingCharge]: "Pending charge",
      [UPowerDeviceState.PendingDischarge]: "Pending discharge",
      [UPowerDeviceState.Empty]: "Empty",
    };
    var state = states[batState] || "Discharging";
    return pct + "% · " + state;
  }
  property color batColor: {
    if (!batPresent) return colors.fg;
    if (batCharging || batPlugged) return colors.green;
    if (batPct <= 15) return colors.red;
    if (batPct <= 30) return colors.yellow;
    return colors.fg;
  }

  // -- Media --
  property var mediaPlayers: Mpris.players.values
  property var mediaPlayer: {
    var playing = findFirst(mediaPlayers, function(p) { return p.isPlaying; });
    return playing ? playing : findFirst(mediaPlayers, function(p) {
        return p.playbackState === MprisPlaybackState.Paused;
    });
  }
  property string mediaText: mediaPlayer
  ? (mediaPlayer.trackArtist
    ? mediaPlayer.trackTitle + " — " + mediaPlayer.trackArtist
    : mediaPlayer.trackTitle)
  : ""
  property string mediaTooltip: mediaPlayer
  ? (barPanel.mediaText + "\nLeft click: playback controls\nRight click: focus app")
  : ""
  property bool mediaHover: mediaPill.visible && (mediaWaveArea.containsMouse || mediaLabelArea.containsMouse)
  property bool volHover: volMouse.containsMouse
  property bool wifiHover: wifiHoverHandler.hovered || wifiMouse.containsMouse
  property bool batHover: batPresent && batHoverHandler.hovered
  property var tooltipAnchor: volHover ? volWidget : (wifiHover ? wifiPill : (batHover ? batteryPill : null))
  property string tooltipText: volHover ? barPanel.volTooltip : (wifiHover ? barPanel.wifiTooltip : (batHover ? barPanel.batTooltip : ""))
  property bool tooltipVisible: tooltipText !== ""
  property int tooltipWidth: Math.round(Math.min(barPanel.tooltipMaxWidth, barPanel.width - barPanel.tooltipMargin * 2))
  property int tooltipLeft: tooltipAnchor ? tooltipX(tooltipWidth) : 0
  property int tooltipTop: Math.round(barPanel.barHeight + barPanel.tooltipGap)
  property real mediaProgress: mediaPlayer && mediaPlayer.length > 0
  ? mediaPlayer.position / mediaPlayer.length : 0
  property bool mediaPopupVisible: false
  property bool popupHovered: false
  property bool popupClosed: false

  onMediaTextChanged: { if (!mediaText) mediaPopupVisible = false; }

  Timer {
    interval: 1000
    running: barPanel.mediaPlayer && barPanel.mediaPlayer.isPlaying && mediaPill.visible
    repeat: true
    onTriggered: { if (barPanel.mediaPlayer) barPanel.mediaPlayer.positionChanged(); }
  }

  Timer {
    id: popupCloseTimer
    interval: 150
    onTriggered: {
      if (!popupHovered && !mediaHover) {
        mediaPopupVisible = false;
      }
    }
  }

  Item {
    id: barContent
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.leftMargin: 8
    anchors.rightMargin: 10
    height: barPanel.barHeight

    Row {
      id: leftRow
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      spacing: 6

      Row {
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
          model: Hyprland.workspaces
          delegate: Rectangle {
            required property var modelData
            visible: !String(modelData.name).startsWith("special")
            width: modelData.focused ? 28 : 12
            height: 12
            radius: height / 2
            color: modelData.focused ? colors.accent : colors.fgDim
            anchors.verticalCenter: parent.verticalCenter

            Behavior on width {
              NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }
            Behavior on color {
              ColorAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }

            MouseArea {
              anchors.fill: parent
              onClicked: modelData.activate()
            }
          }
        }
      }

      Rectangle {
        id: titlePill
        anchors.verticalCenter: parent.verticalCenter
        height: 22
        radius: height / 2
        color: colors.bgRaised
        width: Math.min(titleLabel.implicitWidth, 400) + 16

        Text {
          id: titleLabel
          text: barPanel.currentTitle
          color: colors.fgMid
          font.family: barPanel.uiFont
          font.pixelSize: 12
          font.italic: true
          elide: Text.ElideRight
          x: 8
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - 16
        }
      }
    }

    Text {
      id: centerTime
      anchors.centerIn: parent
      text: barPanel.timeStr
      color: colors.fg
      font.family: barPanel.uiFont
      font.pixelSize: 13
      font.bold: true
    }

    Row {
      id: rightRow
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 6

      Pill {
        id: mediaPill
        visible: barPanel.mediaText !== ""

        Row {
          anchors.verticalCenter: parent.verticalCenter
          spacing: 6

          Item {
            id: mediaWaveform
            property int barCount: 20
            property int barWidth: 2
            property int barSpacing: 2
            width: barCount * barWidth + (barCount - 1) * barSpacing
            height: 16
            anchors.verticalCenter: parent.verticalCenter

            property real wavePhase: 0
            property real displayProgress: barPanel.mediaProgress
            property real playTransition: barPanel.mediaPlayer && barPanel.mediaPlayer.isPlaying ? 1 : 0
            property bool useGpuWaveform: true

            Behavior on playTransition {
              NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
            }

            Timer {
              interval: 200
              running: barPanel.mediaPlayer && barPanel.mediaPlayer.isPlaying && mediaPill.visible
              repeat: true
              onTriggered: mediaWaveform.wavePhase = (mediaWaveform.wavePhase + 1.256) % (Math.PI * 2)
            }

            ShaderEffect {
              id: waveformShader
              anchors.fill: parent
              visible: mediaWaveform.useGpuWaveform && status === ShaderEffect.Ready
              fragmentShader: "shaders/waveform.frag.qsb"

              property real barCount: mediaWaveform.barCount
              property real barWidth: mediaWaveform.barWidth
              property real barSpacing: mediaWaveform.barSpacing
              property real heightPx: mediaWaveform.height
              property real phase: mediaWaveform.wavePhase
              property real play: mediaWaveform.playTransition
              property real progress: mediaWaveform.displayProgress
              property color colorStart: Qt.rgba(0.769, 0.655, 0.906, 1)
              property color colorEnd: Qt.rgba(0.612, 0.812, 0.847, 1)
              property color bgColor: colors.bgSubtle
            }

            Loader {
              id: waveformFallback
              active: !waveformShader.visible
              width: mediaWaveform.width
              height: mediaWaveform.height
              anchors.verticalCenter: parent.verticalCenter

              sourceComponent: Component {
                Item {
                  width: mediaWaveform.width
                  height: mediaWaveform.height

                  Repeater {
                    model: mediaWaveform.barCount
                    delegate: Rectangle {
                      required property int index
                      width: mediaWaveform.barWidth
                      radius: width / 2
                      x: index * (mediaWaveform.barWidth + mediaWaveform.barSpacing)
                      y: (mediaWaveform.height - height) / 2

                      height: {
                        if (!barPanel.mediaPlayer) return 3
                        var waveHeight = 3 + Math.sin(mediaWaveform.wavePhase + index * 0.55) * 4 + 3
                        return 3 + (waveHeight - 3) * mediaWaveform.playTransition
                      }
                      color: {
                        if (!barPanel.mediaPlayer) return colors.bgSubtle
                        var frac = (index + 1) / mediaWaveform.barCount
                        if (frac > mediaWaveform.displayProgress) return colors.bgSubtle
                        var t = frac / Math.max(mediaWaveform.displayProgress, 0.01)
                        return Qt.rgba(
                          0.769 - 0.157 * t,
                          0.655 + 0.157 * t,
                          0.906 - 0.059 * t,
                          1
                        )
                      }
                    }
                  }
                }
              }
            }

            MouseArea {
              id: mediaWaveArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                  barPanel.focusMediaPlayer();
                  return;
                }
                barPanel.mediaPopupVisible = !barPanel.mediaPopupVisible;
              }
            }
          }

          Text {
            id: mediaTimeLabel
            text: {
              if (!barPanel.mediaPlayer) return ""
              var p = Math.round(barPanel.mediaPlayer.position)
              var l = Math.round(barPanel.mediaPlayer.length)
              if (l <= 0) return ""
              return Math.floor(p/60) + ":" + (p%60).toString().padStart(2,'0')
              + " / " + Math.floor(l/60) + ":" + (l%60).toString().padStart(2,'0')
            }
            color: colors.fgMid
            font.family: barPanel.uiFont
            font.pixelSize: 9
            anchors.verticalCenter: parent.verticalCenter
            visible: barPanel.mediaPlayer !== null
          }

          Item {
            id: mediaTextContainer
            property int marqueeMaxWidth: 200
            implicitWidth: Math.min(mediaLabelText.implicitWidth, marqueeMaxWidth)
            height: parent.height
            clip: true

            Text {
              id: mediaLabelText
              text: barPanel.mediaText
              color: colors.fg
              font.family: barPanel.uiFont
              font.pixelSize: 12

              property bool overflow: implicitWidth > mediaTextContainer.width + 2

              onTextChanged: {
                x = 0
                if (overflow) scrollAnim.restart()
              }
            }

            SequentialAnimation {
              id: scrollAnim
              running: mediaLabelText.overflow
              loops: Animation.Infinite

              PauseAnimation { duration: 2000 }

              PropertyAnimation {
                target: mediaLabelText
                property: "x"
                to: mediaTextContainer.width - mediaLabelText.implicitWidth
                duration: Math.max((mediaLabelText.implicitWidth - mediaTextContainer.width) * 30, 1000)
                easing.type: Easing.Linear
              }

              PauseAnimation { duration: 2000 }

              PropertyAnimation {
                target: mediaLabelText
                property: "x"
                to: 0
                duration: Math.max((mediaLabelText.implicitWidth - mediaTextContainer.width) * 30, 1000)
                easing.type: Easing.Linear
              }
            }

            MouseArea {
              id: mediaLabelArea
              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                  barPanel.focusMediaPlayer();
                  return;
                }
                barPanel.mediaPopupVisible = !barPanel.mediaPopupVisible;
              }
            }
          }
        }
      }

      Item {
        id: volWidget
        width: volLayout.width + 8
        height: parent.height
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
          id: volBg
          anchors.fill: parent
          radius: 4
          color: "transparent"

          Behavior on color {
            ColorAnimation { duration: 100 }
          }
        }

        Row {
          id: volLayout
          anchors.verticalCenter: parent.verticalCenter
          anchors.left: parent.left
          anchors.leftMargin: 4
          spacing: 4

          Text {
            id: volIcon
            text: {
              if (barPanel.volMuted) return "󰝟"
              var v = barPanel.volPct
              if (v <= 0) return "󰝟"
              if (v < 0.33) return "󰕿"
              if (v < 0.66) return "󰖀"
              return "󰕾"
            }
            color: barPanel.volMuted ? colors.red : colors.fg
            font.family: barPanel.uiFont
            font.pixelSize: 12
          }

          Text {
            id: volPct
            text: Math.round(barPanel.volPct * 100) + "%"
            color: barPanel.volMuted ? colors.red : colors.fg
            font.family: barPanel.uiFont
            font.pixelSize: 12
            font.bold: true
          }

          Item {
            width: 32
            height: parent.height

            Rectangle {
              anchors.centerIn: parent
              width: parent.width
              height: 8
              radius: 4
              color: colors.bgSubtle

              Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: parent.width * barPanel.volPct
                radius: 4
                color: barPanel.volMuted ? colors.red : colors.accent

                Behavior on width {
                  NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
                }
                Behavior on color {
                  ColorAnimation { duration: 150 }
                }
              }
            }
          }
        }

        MouseArea {
          id: volMouse
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.RightButton

          onEntered: volBg.color = colors.bgRaised
          onExited: volBg.color = "transparent"

          onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
              volProc.startDetached()
            } else if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
              Pipewire.defaultAudioSink.audio.muted = !barPanel.volMuted
            }
          }

          onWheel: function(wheel) {
            if (!Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio) return
            var step = 0.05
            var dir = wheel.angleDelta.y > 0 ? 1 : -1
            Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1, barPanel.volPct + dir * step))
          }
        }
      }

      Pill {
        id: wifiPill

        HoverHandler { id: wifiHoverHandler }

        Text {
          id: wifiLabel
          text: barPanel.wifiSsid ? barPanel.wifiSsid + " " + barPanel.wifiIcon : barPanel.wifiIcon
          color: barPanel.wifiNet ? colors.accent : colors.fgDim
          font.family: barPanel.uiFont
          font.pixelSize: 12
          anchors.verticalCenter: parent.verticalCenter
        }

        MouseArea {
          id: wifiMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.RightButton
          onClicked: wifiProc.startDetached()
        }
      }

      Pill {
        id: batteryPill
        visible: barPanel.batPresent

        HoverHandler { id: batHoverHandler }

        Text {
          text: barPanel.batIcon + " " + Math.round(barPanel.batPct) + "%"
          color: barPanel.batColor
          font.family: barPanel.uiFont
          font.pixelSize: 12
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }

  PanelWindow {
    id: tooltipWindow
    visible: barPanel.tooltipVisible
    focusable: false
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    anchors { top: true; left: true }
    margins { top: barPanel.tooltipTop; left: 0 }

    implicitWidth: barPanel.width
    implicitHeight: tooltipCard.implicitHeight + 3

    Rectangle {
      id: tooltipShadow
      x: barPanel.tooltipLeft
      width: barPanel.tooltipWidth
      implicitHeight: tooltipTextItem.paintedHeight + barPanel.tooltipPadding * 2
      height: implicitHeight
      radius: 10
      color: Qt.rgba(0, 0, 0, 0.25)
      opacity: barPanel.tooltipVisible ? 0.7 : 0
      y: 3
      antialiasing: true

      Behavior on opacity {
        NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
      }
    }

    Rectangle {
      id: tooltipCard
      x: barPanel.tooltipLeft
      width: barPanel.tooltipWidth
      implicitHeight: tooltipTextItem.paintedHeight + barPanel.tooltipPadding * 2
      height: implicitHeight
      radius: 10
      color: colors.bgRaised
      antialiasing: true
      border.width: 1
      border.color: colors.border
      opacity: barPanel.tooltipVisible ? 1 : 0

      Behavior on opacity {
        NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
      }

      Text {
        id: tooltipTextItem
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: barPanel.tooltipPadding
        width: parent.width - barPanel.tooltipPadding * 2
        text: barPanel.tooltipText
        color: colors.fg
        font.family: barPanel.uiFont
        font.pixelSize: 13
        lineHeightMode: Text.ProportionalHeight
        lineHeight: 1.2
        wrapMode: Text.Wrap
      }
    }
  }

  PanelWindow {
    id: mediaPopup
    visible: barPanel.mediaPopupVisible && barPanel.mediaPlayer !== null
    focusable: false
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    anchors { top: true; left: true }
    margins { top: mediaPopup.popupMarginTop; left: 0 }

    implicitWidth: barPanel.width
    implicitHeight: 160

    property int popupWidth: 300
    property int popupX: {
      var pillW = mediaPill.width;
      var pillX = rightRow.x + mediaPill.x;
      var x = barContent.x + pillX + (pillW - popupWidth) / 2;
      return Math.round(barPanel.clamp(x, barPanel.tooltipMargin, barPanel.width - popupWidth - barPanel.tooltipMargin));
    }
    property int popupMarginTop: {
      var pillY = rightRow.y + mediaPill.y;
      return barContent.y + pillY + mediaPill.height + 4;
    }

    Rectangle {
      id: popupShadow
      x: mediaPopup.popupX
      y: 3
      width: mediaPopup.popupWidth
      implicitHeight: popupCard.implicitHeight
      height: implicitHeight
      radius: 12
      color: Qt.rgba(0, 0, 0, 0.25)
      opacity: 0.7
      antialiasing: true
    }

    Rectangle {
      id: popupCard
      x: mediaPopup.popupX
      width: mediaPopup.popupWidth
      implicitHeight: popupContent.implicitHeight + 28
      height: implicitHeight
      radius: 12
      color: colors.bgRaised
      antialiasing: true
      border.width: 1
      border.color: colors.border

      Rectangle {
        id: closeBtn
        x: parent.width - 28
        y: 8
        width: 20
        height: 20
        radius: 10
        color: colors.bgSubtle

        Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

        Text {
          anchors.centerIn: parent
          text: "\uDB80\uDD56"
          color: colors.fgDim
          font.family: barPanel.uiFont
          font.pixelSize: 11
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: closeBtn.color = colors.border
          onExited: closeBtn.color = colors.bgSubtle
          onClicked: barPanel.mediaPopupVisible = false
        }
      }

      Column {
        id: popupContent
        anchors { left: parent.left; top: parent.top; right: parent.right }
        anchors.margins: 14
        spacing: 8

        Row {
          spacing: 12
          width: parent.width

          Item {
            id: artContainer
            width: 64
            height: 64
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
              anchors.fill: parent
              radius: 12
              color: colors.bgSubtle
              clip: true

              Image {
                id: artImage
                anchors.fill: parent
                source: barPanel.mediaPlayer ? (barPanel.mediaPlayer.trackArtUrl || "") : ""
                fillMode: Image.PreserveAspectCrop
                smooth: true
                visible: status === Image.Ready || status === Image.Loading
              }

              Text {
                anchors.centerIn: parent
                text: "\uDB80\uDDE2"
                color: colors.fgDim
                font.family: barPanel.uiFont
                font.pixelSize: 24
                visible: artImage.status !== Image.Ready && artImage.status !== Image.Loading
              }
            }

            Rectangle {
              anchors.fill: parent
              radius: 12
              color: "transparent"
              border.width: 1.5
              border.color: colors.border
            }
          }

          Column {
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - artContainer.width - parent.spacing - closeBtn.width - 8

            Text {
              width: parent.width
              text: barPanel.mediaText
              color: colors.fg
              font.family: barPanel.uiFont
              font.pixelSize: 13
              font.bold: true
              elide: Text.ElideRight
            }

            Text {
              width: parent.width
              text: {
                var parts = [];
                if (barPanel.mediaPlayer && barPanel.mediaPlayer.trackAlbum) parts.push(barPanel.mediaPlayer.trackAlbum);
                if (barPanel.mediaPlayer && barPanel.mediaPlayer.name) parts.push(barPanel.mediaPlayer.name);
                return parts.join(" \u2014 ");
              }
              color: colors.fgDim
              font.family: barPanel.uiFont
              font.pixelSize: 11
              elide: Text.ElideRight
              visible: text.length > 0
            }
          }
        }

        Item {
          width: parent.width
          height: 32

          Rectangle {
            id: mPrevBtn
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            height: 32
            radius: 8
            color: Qt.rgba(0.149, 0.149, 0.18, 0.6)
            border.width: 1
            border.color: colors.border

            Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

            Text {
              anchors.centerIn: parent
              text: "\uDB81\uDCAE"
              color: colors.fg
              font.family: barPanel.uiFont
              font.pixelSize: 14
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: { mPrevBtn.color = colors.bgSubtle; mPrevBtn.scale = 0.92 }
              onExited: { mPrevBtn.color = Qt.rgba(0.149, 0.149, 0.18, 0.6); mPrevBtn.scale = 1 }
              onClicked: { if (barPanel.mediaPlayer) barPanel.mediaPlayer.previous() }
            }
          }

          Rectangle {
            id: mPlayBtn
            anchors.left: mPrevBtn.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            height: 32
            radius: 8
            color: colors.accent
            border.width: 1
            border.color: colors.accent

            Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

            Text {
              anchors.centerIn: parent
              text: barPanel.mediaPlayer && barPanel.mediaPlayer.isPlaying ? "\uDB80\uDFE4" : "\uDB81\uDC0A"
              color: colors.bg
              font.family: barPanel.uiFont
              font.pixelSize: 14
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: mPlayBtn.scale = 0.92
              onExited: mPlayBtn.scale = 1
              onClicked: { if (barPanel.mediaPlayer) barPanel.mediaPlayer.togglePlaying() }
            }
          }

          Rectangle {
            id: mNextBtn
            anchors.left: mPlayBtn.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            height: 32
            radius: 8
            color: Qt.rgba(0.149, 0.149, 0.18, 0.6)
            border.width: 1
            border.color: colors.border

            Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

            Text {
              anchors.centerIn: parent
              text: "\uDB81\uDCAD"
              color: colors.fg
              font.family: barPanel.uiFont
              font.pixelSize: 14
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: { mNextBtn.color = colors.bgSubtle; mNextBtn.scale = 0.92 }
              onExited: { mNextBtn.color = Qt.rgba(0.149, 0.149, 0.18, 0.6); mNextBtn.scale = 1 }
              onClicked: { if (barPanel.mediaPlayer) barPanel.mediaPlayer.next() }
            }
          }

          Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: {
              if (!barPanel.mediaPlayer) return ""
              var p = Math.round(barPanel.mediaPlayer.position)
              var l = Math.round(barPanel.mediaPlayer.length)
              if (l <= 0) return ""
              return Math.floor(p/60) + ":" + (p%60).toString().padStart(2,'0')
              + " / " + Math.floor(l/60) + ":" + (l%60).toString().padStart(2,'0')
            }
            color: colors.fgMid
            font.family: barPanel.uiFont
            font.pixelSize: 10
          }
        }

        Item {
          width: parent.width
          height: 6
          visible: barPanel.mediaPlayer && barPanel.mediaPlayer.length > 0

          Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: 3
            color: Qt.rgba(0.145, 0.145, 0.18, 0.7)

            Rectangle {
              anchors.top: parent.top
              anchors.left: parent.left
              anchors.bottom: parent.bottom
              width: parent.width * (barPanel.mediaPlayer && barPanel.mediaPlayer.length > 0
                ? Math.min(1, Math.max(0, barPanel.mediaPlayer.position / barPanel.mediaPlayer.length))
                : 0)
              radius: 3
              color: colors.accent

              Behavior on width {
                NumberAnimation { duration: 300; easing.type: Easing.Linear }
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: function(mouse) {
                if (barPanel.mediaPlayer && barPanel.mediaPlayer.canSeek) {
                  barPanel.mediaPlayer.position = mouse.x / width * barPanel.mediaPlayer.length;
                }
              }
            }
          }
        }
      }
    }
  }
}
