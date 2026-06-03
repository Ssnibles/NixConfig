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
  focusable: false
  aboveWindows: true

  anchors { top: true; left: true; right: true }
  implicitHeight: barHeight
  exclusionMode: ExclusionMode.Auto
  color: Colors.bg

  property string uiFont: "JetBrains Mono"
  property int barHeight: 30
  property int tooltipMaxWidth: 320
  property int tooltipMargin: 6

  property string timeStr: ""

  // Update clock display and schedule the next update so it fires exactly
  // at the next minute boundary, keeping the clock perfectly in sync.
  function updateTime() {
    var d = new Date();
    barPanel.timeStr = Qt.formatTime(d, "hh:mm");
    timeTimer.interval = 60000 - (d.getSeconds() * 1000 + d.getMilliseconds());
    timeTimer.restart();
  }

  Timer {
    id: timeTimer
    running: true
    repeat: false
    onTriggered: barPanel.updateTime()
  }

  Component.onCompleted: updateTime()

  // Clean up common window titles so the bar pill isn't cluttered.
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

  function pad2(n) {
    return n < 10 ? "0" + n : "" + n;
  }

  function escapeRegex(value) {
    return String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  }

  // Try to focus the Hyprland window belonging to the current media player.
  // First match by desktop entry / app class, then fall back to window title.
  function focusMediaPlayer() {
    if (!barPanel.mediaPlayer) return;
    var entry = barPanel.mediaPlayer.desktopEntry || barPanel.mediaPlayer.name || "";
    if (entry) {
      var lowerEntry = entry.toLowerCase();
      var toplevels = Hyprland.toplevels.values;
      for (var i = 0; i < toplevels.length; i++) {
        var tl = toplevels[i];
        // lastIpcObject.class is the Hyprland window class (e.g. "firefox", "spotify").
        if (tl.lastIpcObject && tl.lastIpcObject.class) {
          if (tl.lastIpcObject.class.toLowerCase() === lowerEntry) {
            var addr = String(tl.address);
            if (addr.startsWith("0x")) addr = addr.slice(2);
            Hyprland.dispatch("focuswindow address:0x" + addr);
            return;
          }
        }
      }
      // Fallback: focus by class regex if direct address match failed.
      Hyprland.dispatch("focuswindow class:(?i)^" + escapeRegex(entry) + "$");
      return;
    }
    var identity = barPanel.mediaPlayer.identity || "";
    if (identity) {
      var toplevels2 = Hyprland.toplevels.values;
      for (var j = 0; j < toplevels2.length; j++) {
        var tl2 = toplevels2[j];
        if (tl2.title && tl2.title.indexOf(identity) !== -1) {
          var addr2 = String(tl2.address);
          if (addr2.startsWith("0x")) addr2 = addr2.slice(2);
          Hyprland.dispatch("focuswindow address:0x" + addr2);
          return;
        }
      }
      Hyprland.dispatch("focuswindow title:(?i)" + escapeRegex(identity).replace(/\s+/g, "\\s+"));
    }
  }

  property string currentTitle: Hyprland.activeToplevel ? formatTitle(Hyprland.activeToplevel.title) : ""

  function switchWs(id) { Hyprland.dispatch("workspace " + id); }

  // -- Volume --
  // PwObjectTracker is required by Quickshell so property bindings on Pipewire
  // nodes actually update when the underlying object changes.
  property var volNodes: Pipewire.ready && Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
  PwObjectTracker { objects: barPanel.volNodes }
  property var volInfo: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
  property real volPct: volInfo ? volInfo.volume : 0
  property bool volMuted: volInfo ? volInfo.muted : false
  property string volTooltip: {
    var pct = Math.round(barPanel.volPct * 100);
    return (barPanel.volMuted ? "Muted" : ("Volume " + pct + "%")) + "\nLeft click: mute\nRight click: pavucontrol\nScroll: adjust";
  }
  Process { id: volProc; command: ["pavucontrol"] }
  Process { id: controlPanelProc; command: ["qs", "ipc", "call", "controlpanel", "toggle"] }

  // -- WiFi --
  property var wifiDev: findFirst(Networking.devices.values, function(d) { return d.type === DeviceType.Wifi; })
  property var wifiNet: findFirst(wifiDev ? wifiDev.networks.values : [], function(n) { return n.connected; })
  property string wifiSsid: wifiNet ? wifiNet.name : ""
  property string wifiIcon: {
    if (!wifiNet) return "󰤯";
    var s = wifiNet.signalStrength;
    if (s < 0.2) return "󰤟";
    if (s < 0.4) return "󰤢";
    if (s < 0.6) return "󰤥";
    return "󰤨";
  }
  property string wifiTooltip: {
    if (!wifiNet) return "Wi-Fi disconnected\nRight click: nmtui";
    return wifiNet.name + " (" + Math.round(wifiNet.signalStrength * 100) + "%)\nRight click: nmtui";
  }
  Process { id: wifiProc; command: ["sh", "-lc", "foot -e nmtui"] }

  // -- Battery --
  // Look for an actual laptop battery first; if none is found, fall back to UPower's
  // aggregated display device (useful on desktops that report a UPS or display device).
  property var batDevice: {
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
  readonly property int batPct: batDevice ? Math.round(batDevice.percentage * 100) : 0
  readonly property bool batCharging: batDevice && batDevice.state === UPowerDeviceState.Charging
  readonly property bool batPlugged: batDevice && batDevice.state === UPowerDeviceState.FullyCharged
  readonly property int batState: batDevice ? batDevice.state : UPowerDeviceState.Unknown

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
    var state;
    switch (batState) {
      case UPowerDeviceState.Charging:        state = "Charging"; break;
      case UPowerDeviceState.FullyCharged:    state = "Plugged in"; break;
      case UPowerDeviceState.PendingCharge:   state = "Pending charge"; break;
      case UPowerDeviceState.PendingDischarge:state = "Pending discharge"; break;
      case UPowerDeviceState.Empty:           state = "Empty"; break;
      default:                                state = "Discharging"; break;
    }
    return pct + "% · " + state;
  }
  property color batColor: {
    if (!batPresent) return Colors.fg;
    if (batCharging || batPlugged) return Colors.green;
    if (batPct <= 15) return Colors.red;
    if (batPct <= 30) return Colors.yellow;
    return Colors.fg;
  }

  // -- Media --
  // Prefer the currently playing player; if none, show the most recently paused one.
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
  property bool hasMedia: mediaText !== ""
  // mediaTick is incremented on a timer so that mediaProgress (a computed property)
  // re-evaluates and the seek-bar / waveform stay in sync while playing.
  property int mediaTick: 0
  property real mediaLastPosition: 0
  property real mediaLastLength: 0
  property int mediaResetToken: 0
  function resetMediaTiming(pos, len) {
    barPanel.mediaLastPosition = Math.max(0, pos || 0);
    barPanel.mediaLastLength = Math.max(0, len || 0);
    barPanel.mediaTick = 0;
    barPanel.mediaResetToken++;
    if (tickTimer) tickTimer.wavePhase = 0;
  }
  function updateMediaPosition(pos, len) {
    var p = Math.max(0, pos || 0);
    var l = Math.max(0, len || 0);
    if (p + 0.5 < barPanel.mediaLastPosition) {
      barPanel.resetMediaTiming(p, l);
      return;
    }
    barPanel.mediaLastPosition = p;
    barPanel.mediaLastLength = l;
  }
  property real mediaProgress: {
    var _ = barPanel.mediaTick;
    var __ = barPanel.mediaResetToken;
    return mediaPlayer && barPanel.mediaLastLength > 0
      ? Math.min(1, Math.max(0, barPanel.mediaLastPosition / barPanel.mediaLastLength)) : 0;
  }
  onMediaPlayerChanged: {
    if (!mediaPlayer) {
      barPanel.resetMediaTiming(0, 0);
      return;
    }
    barPanel.resetMediaTiming(mediaPlayer.position, mediaPlayer.length);
  }

  Connections {
    target: barPanel.mediaPlayer
    function onPositionChanged() {
      if (!barPanel.mediaPlayer) return;
      barPanel.updateMediaPosition(barPanel.mediaPlayer.position, barPanel.mediaPlayer.length);
    }
    function onLengthChanged() {
      if (!barPanel.mediaPlayer) return;
      barPanel.mediaLastLength = Math.max(0, barPanel.mediaPlayer.length || 0);
    }
    function onTrackChanged() {
      if (!barPanel.mediaPlayer) return;
      barPanel.resetMediaTiming(barPanel.mediaPlayer.position, barPanel.mediaPlayer.length);
    }
  }

  // -- Hover state --
  property bool volHover: volHoverHandler.hovered
  property bool wifiHover: wifiHoverHandler.hovered
  property bool batHover: batPresent && batHoverHandler.hovered
  property bool mediaHover: mediaPillHover.hovered
  property bool tooltipVisible: volHover || wifiHover || batHover

  property string tooltipText: {
    if (volHover) return barPanel.volTooltip;
    if (wifiHover) return barPanel.wifiTooltip;
    if (batHover) return barPanel.batTooltip;
    return "";
  }

  property int tooltipWidth: Math.round(Math.min(barPanel.tooltipMaxWidth, barPanel.width - barPanel.tooltipMargin * 2))

  // Single unified tick for media + waveform
  Timer {
    id: tickTimer
    interval: 500
    running: mediaPlayer && mediaPlayer.isPlaying
    repeat: true
    property real wavePhase: 0
    onTriggered: {
      // Advance sine wave phase by ~72 degrees each tick for the fallback bars.
      wavePhase = (wavePhase + 1.256) % (Math.PI * 2);
      if (barPanel.mediaPlayer) {
        barPanel.updateMediaPosition(barPanel.mediaPlayer.position, barPanel.mediaPlayer.length);
      }
      barPanel.mediaTick++;
    }
    onRunningChanged: { if (!running) wavePhase = 0; }
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

      Repeater {
        model: Hyprland.workspaces
        delegate: Rectangle {
          required property var modelData
          visible: !String(modelData.name).startsWith("special")
          width: modelData.focused ? 28 : 12
          height: 12
          radius: height / 2
          color: modelData.focused ? Colors.accent : Colors.fgDim
          anchors.verticalCenter: parent.verticalCenter

          Behavior on width {
            SpringAnimation { spring: 4.5; damping: 0.28 }
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

      Rectangle {
        id: titlePill
        anchors.verticalCenter: parent.verticalCenter
        height: 22
        radius: height / 2
        color: Colors.bgRaised
        width: Math.min(titleLabel.implicitWidth, 400) + 16

        Text {
          id: titleLabel
          text: barPanel.currentTitle
          color: Colors.fgMid
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
      color: Colors.fg
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
        visible: barPanel.hasMedia
        HoverHandler { id: mediaPillHover }

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

            // GLSL shader version of the waveform; falls back to plain Rectangles below
            // if the shader hasn't compiled or the player is paused.
            ShaderEffect {
              id: waveformShader
              anchors.fill: parent
              visible: status === ShaderEffect.Ready && mediaPlayer && mediaPlayer.isPlaying
              fragmentShader: "shaders/waveform.frag.qsb"

              property real barCount: mediaWaveform.barCount
              property real barWidth: mediaWaveform.barWidth
              property real barSpacing: mediaWaveform.barSpacing
              property real heightPx: mediaWaveform.height
              property real phase: tickTimer.wavePhase
              property real play: 1.0
              property real progress: barPanel.mediaProgress
              property color colorStart: Colors.purple
              property color colorEnd: Colors.teal
              property color bgColor: Colors.bgSubtle
            }

            // CPU-drawn fallback bars when the shader isn't available or music is paused.
            Repeater {
              id: waveformBars
              model: mediaWaveform.barCount
              visible: !waveformShader.visible
              delegate: Rectangle {
                required property int index
                width: mediaWaveform.barWidth
                radius: width / 2
                x: index * (mediaWaveform.barWidth + mediaWaveform.barSpacing)
                y: (mediaWaveform.height - height) / 2
                height: {
                  if (!barPanel.mediaPlayer || !barPanel.mediaPlayer.isPlaying) return 3
                  return 3 + Math.sin(tickTimer.wavePhase + index * 0.55) * 4 + 3
                }
                color: {
                  if (!barPanel.mediaPlayer || !barPanel.mediaPlayer.isPlaying) return Colors.bgSubtle
                  var frac = (index + 1) / mediaWaveform.barCount
                  if (frac > barPanel.mediaProgress) return Colors.bgSubtle
                  var t = frac / Math.max(barPanel.mediaProgress, 0.01)
                  return Qt.rgba(
                    Colors.purple.r + (Colors.teal.r - Colors.purple.r) * t,
                    Colors.purple.g + (Colors.teal.g - Colors.purple.g) * t,
                    Colors.purple.b + (Colors.teal.b - Colors.purple.b) * t,
                    1
                  )
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              onClicked: function(mouse) {
                if (!barPanel.mediaPlayer) return;
                if (mouse.button === Qt.RightButton) {
                  barPanel.focusMediaPlayer();
                } else {
                  if (barPanel.mediaPlayer.canTogglePlaying)
                    barPanel.mediaPlayer.togglePlaying();
                }
              }
              onWheel: function(wheel) {
                if (!barPanel.mediaPlayer) return;
                if (wheel.angleDelta.y > 0) {
                  if (barPanel.mediaPlayer.canGoNext) barPanel.mediaPlayer.next();
                } else if (wheel.angleDelta.y < 0) {
                  if (barPanel.mediaPlayer.canGoPrevious) barPanel.mediaPlayer.previous();
                }
                wheel.accepted = true;
              }
            }
          }

          Text {
            id: mediaTimeLabel
            text: {
              if (!barPanel.mediaPlayer) return ""
              var _ = barPanel.mediaTick;
              var __ = barPanel.mediaResetToken;
              var p = Math.round(barPanel.mediaLastPosition)
              var l = Math.round(barPanel.mediaLastLength)
              if (l <= 0) return ""
              return Math.floor(p/60) + ":" + pad2(p%60)
                + " / " + Math.floor(l/60) + ":" + pad2(l%60)
            }
            color: Colors.fgMid
            font.family: barPanel.uiFont
            font.pixelSize: 9
            anchors.verticalCenter: parent.verticalCenter
            visible: barPanel.mediaPlayer !== null
          }

          // Marquee scroll: if the media title is too long, scroll it back and forth.
          Item {
            id: mediaTextContainer
            property int marqueeMaxWidth: 200
            implicitWidth: Math.min(mediaLabelText.implicitWidth, marqueeMaxWidth)
            height: parent.height
            clip: true

            Text {
              id: mediaLabelText
              text: barPanel.mediaText
              color: Colors.fg
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
              running: mediaPill.visible && mediaLabelText.overflow
              loops: Animation.Infinite
              PauseAnimation { duration: 2000 }
              PropertyAnimation {
                target: mediaLabelText; property: "x"
                to: mediaTextContainer.width - mediaLabelText.implicitWidth
                duration: Math.max((mediaLabelText.implicitWidth - mediaTextContainer.width) * 30, 1000)
                easing.type: Easing.Linear
              }
              PauseAnimation { duration: 2000 }
              PropertyAnimation {
                target: mediaLabelText; property: "x"
                to: 0
                duration: Math.max((mediaLabelText.implicitWidth - mediaTextContainer.width) * 30, 1000)
                easing.type: Easing.Linear
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              onClicked: function(mouse) {
                if (!barPanel.mediaPlayer) return;
                if (mouse.button === Qt.RightButton) {
                  barPanel.focusMediaPlayer();
                } else {
                  controlPanelProc.startDetached();
                }
              }
              onWheel: function(wheel) {
                if (!barPanel.mediaPlayer) return;
                if (wheel.angleDelta.y > 0) {
                  if (barPanel.mediaPlayer.canGoNext) barPanel.mediaPlayer.next();
                } else if (wheel.angleDelta.y < 0) {
                  if (barPanel.mediaPlayer.canGoPrevious) barPanel.mediaPlayer.previous();
                }
                wheel.accepted = true;
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

        HoverHandler { id: volHoverHandler }

        Rectangle {
          id: volBg
          anchors.fill: parent
          radius: 4
          color: volHoverHandler.hovered ? Colors.bgRaised : "transparent"
          Behavior on color { ColorAnimation { duration: 100 } }
        }

        Row {
          id: volLayout
          anchors.verticalCenter: parent.verticalCenter
          anchors.left: parent.left
          anchors.leftMargin: 4
          spacing: 4

          Text {
            text: {
              if (barPanel.volMuted) return "󰝟"
              var v = barPanel.volPct
              if (v <= 0) return "󰝟"
              if (v < 0.33) return "󰕿"
              if (v < 0.66) return "󰖀"
              return "󰕾"
            }
            color: barPanel.volMuted ? Colors.red : Colors.fg
            font.family: barPanel.uiFont
            font.pixelSize: 12
          }

          Text {
            text: Math.round(barPanel.volPct * 100) + "%"
            color: barPanel.volMuted ? Colors.red : Colors.fg
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
              color: Colors.bgSubtle
              Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: parent.width * barPanel.volPct
                radius: 4
                color: barPanel.volMuted ? Colors.red : Colors.accent
                Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
                Behavior on color { ColorAnimation { duration: 150 } }
              }
            }
          }
        }

        MouseArea {
          id: volMouse
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) { volProc.startDetached(); }
            else if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
              Pipewire.defaultAudioSink.audio.muted = !barPanel.volMuted;
            }
          }
          onWheel: function(wheel) {
            if (!Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio) return;
            var step = 0.05;
            var dir = wheel.angleDelta.y > 0 ? 1 : -1;
            Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1, barPanel.volPct + dir * step));
          }
        }
      }

      Pill {
        id: wifiPill
        HoverHandler { id: wifiHoverHandler }
        Text {
          text: barPanel.wifiSsid ? barPanel.wifiSsid + " " + barPanel.wifiIcon : barPanel.wifiIcon
          color: barPanel.wifiNet ? Colors.accent : Colors.fgDim
          font.family: barPanel.uiFont
          font.pixelSize: 12
          anchors.verticalCenter: parent.verticalCenter
        }
        MouseArea {
          anchors.fill: parent
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

  // Lazy-loaded tooltip: avoids creating a PanelWindow until a bar widget is hovered.
  Loader {
    id: tooltipLoader
    active: barPanel.tooltipVisible

    // Center the tooltip horizontally above the hovered pill, clamped to screen bounds.
    function computeX(targetW) {
      var anchor = { volWidget: 1, wifiPill: 1, batteryPill: 1 };
      var pill;
      if (volHover) pill = volWidget;
      else if (wifiHover) pill = wifiPill;
      else pill = batteryPill;
      if (!pill) return 0;
      var pos = pill.mapToItem(barContent, 0, 0);
      var x = barContent.x + pos.x + (pill.width - targetW) / 2;
      return Math.round(clamp(x, barPanel.tooltipMargin, barPanel.width - targetW - barPanel.tooltipMargin));
    }

    sourceComponent: Component {
      PanelWindow {
        id: tooltipWindow
        focusable: false
        aboveWindows: true
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        anchors { top: true; left: true }
        margins { top: barPanel.barHeight + 10; left: 0 }
        implicitWidth: barPanel.width
        implicitHeight: tooltipCard.implicitHeight + 3

        Rectangle {
          id: tooltipCard
          x: tooltipLoader.computeX(barPanel.tooltipWidth)
          width: barPanel.tooltipWidth
          implicitHeight: tipText.paintedHeight + 20
          height: implicitHeight
          radius: 10
          color: Colors.bgRaised
          antialiasing: true
          border.width: 1
          border.color: Colors.border
          opacity: barPanel.tooltipVisible ? 1 : 0
          Behavior on opacity { NumberAnimation { duration: 80 } }

          Rectangle {
            anchors.fill: parent
            radius: 10
            color: Qt.rgba(0, 0, 0, 0.25)
            opacity: barPanel.tooltipVisible ? 0.7 : 0
            y: 3
            z: -1
            Behavior on opacity { NumberAnimation { duration: 80 } }
          }

          Text {
            id: tipText
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 10
            width: parent.width - 20
            text: barPanel.tooltipText
            color: Colors.fg
            font.family: barPanel.uiFont
            font.pixelSize: 13
            lineHeight: 1.2
            wrapMode: Text.Wrap
          }
        }
      }
    }
  }

}
