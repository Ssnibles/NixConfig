import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Networking
import Quickshell.Services.UPower

import QtQuick
import QtQml

PanelWindow {
  id: barPanel
  Colors { id: colors }
  focusable: false
  aboveWindows: true

  anchors { left: true; top: true; bottom: true }
  implicitWidth: barWidth
  exclusionMode: ExclusionMode.Auto
  color: colors.bg

  property string hourStr: ""
  property string minuteStr: ""
  property string uiFont: "JetBrains Mono"
  property int barWidth: 52
  property int tooltipGap: 6
  property int tooltipPadding: 10
  property int tooltipMargin: 6
  property int tooltipMaxWidth: 280

  property var workspaces: []
  property string activeWindowTitle: ""
  property string activeWindowAppId: ""

  property int cpuPct: 0
  property int memPct: 0
  property string netDown: ""
  property string netUp: ""

  property int prevCpuTotal: 0
  property int prevCpuIdle: 0
  property int prevNetRx: 0
  property int prevNetTx: 0
  property int prevNetTime: 0

  function updateTime() {
    var d = new Date();
    barPanel.hourStr = Qt.formatTime(d, "hh");
    barPanel.minuteStr = Qt.formatTime(d, "mm");
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
    initialNiriQuery.exec();
  }

  Process {
    id: initialNiriQuery
    command: ["sh", "-c", "niri msg -j workspaces && echo '---SEP---' && niri msg -j windows"]
    stdout: StdioCollector {
      onDataChanged: {
        try {
          var parts = this.text.split("---SEP---");
          if (parts.length >= 2) {
            var wsData = JSON.parse(parts[0].trim());
            if (Array.isArray(wsData)) {
              wsData.sort(function(a, b) { return a.idx - b.idx; });
              barPanel.workspaces = wsData;
            }
            var winData = JSON.parse(parts[1].trim());
            if (Array.isArray(winData)) {
              for (var i = 0; i < winData.length; i++) {
                if (winData[i].is_focused) {
                  barPanel.activeWindowTitle = winData[i].title || "";
                  barPanel.activeWindowAppId = winData[i].app_id || "";
                  break;
                }
              }
            }
          }
        } catch(e) {}
      }
    }
  }

  Process {
    id: niriMonitor
    command: ["niri", "msg", "--monitor"]
    running: true

    stdout: StdioCollector {
      property int lastPos: 0

      onDataChanged: {
        var newText = this.text.substring(lastPos);
        lastPos = this.text.length;
        var lines = newText.split("\n");
        for (var i = 0; i < lines.length; i++) {
          var line = lines[i].trim();
          if (line === "") continue;
          try {
            var event = JSON.parse(line);
            barPanel.processNiriEvent(event);
          } catch(e) {}
        }
      }
    }

    onExited: {
      restartTimer.start();
    }
  }

  Timer {
    id: restartTimer
    interval: 2000
    repeat: false
    onTriggered: {
      niriMonitor.stdout.lastPos = 0;
      niriMonitor.exec();
    }
  }

  function processNiriEvent(event) {
    if (event.WorkspacesChanged !== undefined) {
      var ws = event.WorkspacesChanged;
      if (Array.isArray(ws)) {
        ws.sort(function(a, b) { return a.idx - b.idx; });
        barPanel.workspaces = ws;
      }
    } else if (event.WindowsChanged !== undefined) {
      var wins = event.WindowsChanged;
      if (Array.isArray(wins)) {
        var focused = null;
        for (var i = 0; i < wins.length; i++) {
          if (wins[i].is_focused) { focused = wins[i]; break; }
        }
        if (focused) {
          barPanel.activeWindowTitle = focused.title || "";
          barPanel.activeWindowAppId = focused.app_id || "";
        } else {
          barPanel.activeWindowTitle = "";
          barPanel.activeWindowAppId = "";
        }
      }
    } else if (event.WindowOpenedOrChanged !== undefined) {
      var w = event.WindowOpenedOrChanged;
      if (w && w.is_focused) {
        barPanel.activeWindowTitle = w.title || "";
        barPanel.activeWindowAppId = w.app_id || "";
      }
    } else if (event.WindowFocusChanged !== undefined) {
      var fc = event.WindowFocusChanged;
      if (fc === null || fc.id === null || fc.id === undefined) {
        barPanel.activeWindowTitle = "";
        barPanel.activeWindowAppId = "";
      }
    } else if (event.WindowClosed !== undefined) {
      if (barPanel.activeWindowTitle !== "") {
        winRefreshQuery.exec();
      }
    }
  }

  Process {
    id: winRefreshQuery
    command: ["sh", "-c", "niri msg -j windows"]
    stdout: StdioCollector {
      onDataChanged: {
        try {
          var data = JSON.parse(this.text);
          if (Array.isArray(data)) {
            var focused = null;
            for (var i = 0; i < data.length; i++) {
              if (data[i].is_focused) { focused = data[i]; break; }
            }
            if (focused) {
              barPanel.activeWindowTitle = focused.title || "";
              barPanel.activeWindowAppId = focused.app_id || "";
            } else {
              barPanel.activeWindowTitle = "";
              barPanel.activeWindowAppId = "";
            }
          }
        } catch(e) {
          barPanel.activeWindowTitle = "";
          barPanel.activeWindowAppId = "";
        }
      }
    }
  }

  // ── Hardware monitoring ──
  Timer {
    id: hwTimer
    interval: 3000
    running: true
    repeat: true
    onTriggered: hwQuery.exec()
  }

  Process {
    id: hwQuery
    command: ["sh", "-c", "head -1 /proc/stat; echo '---'; head -3 /proc/meminfo; echo '---'; cat /proc/net/dev | tail -n +3"]
    stdout: StdioCollector {
      onDataChanged: {
        try {
          var sections = this.text.split("---");
          if (sections.length >= 3) {
            barPanel.parseCpu(sections[0].trim());
            barPanel.parseMem(sections[1].trim());
            barPanel.parseNet(sections[2].trim());
          }
        } catch(e) {}
      }
    }
  }

  function parseCpu(line) {
    var parts = line.split(/\s+/);
    if (parts[0] !== "cpu") return;
    var total = 0;
    for (var i = 1; i < parts.length; i++) total += parseInt(parts[i]);
    var idle = parseInt(parts[4]);
    if (barPanel.prevCpuTotal > 0) {
      var dTotal = total - barPanel.prevCpuTotal;
      var dIdle = idle - barPanel.prevCpuIdle;
      if (dTotal > 0) {
        barPanel.cpuPct = Math.round((1 - dIdle / dTotal) * 100);
      }
    }
    barPanel.prevCpuTotal = total;
    barPanel.prevCpuIdle = idle;
  }

  function parseMem(text) {
    var lines = text.split("\n");
    var total = 0, available = 0;
    for (var i = 0; i < lines.length; i++) {
      var m = lines[i].match(/^(\w+):\s+(\d+)/);
      if (m) {
        if (m[1] === "MemTotal") total = parseInt(m[2]);
        if (m[1] === "MemAvailable") available = parseInt(m[2]);
      }
    }
    if (total > 0) {
      barPanel.memPct = Math.round((1 - available / total) * 100);
    }
  }

  function parseNet(text) {
    var lines = text.split("\n");
    var rx = 0, tx = 0;
    for (var i = 0; i < lines.length; i++) {
      var parts = lines[i].trim().split(/\s+/);
      if (parts.length < 10) continue;
      var iface = parts[0].replace(":", "");
      if (iface === "lo") continue;
      rx += parseInt(parts[1]);
      tx += parseInt(parts[9]);
    }
    var now = Date.now();
    if (barPanel.prevNetTime > 0) {
      var dt = (now - barPanel.prevNetTime) / 1000;
      if (dt > 0) {
        barPanel.netDown = barPanel.formatSpeed((rx - barPanel.prevNetRx) / dt);
        barPanel.netUp = barPanel.formatSpeed((tx - barPanel.prevNetTx) / dt);
      }
    }
    barPanel.prevNetRx = rx;
    barPanel.prevNetTx = tx;
    barPanel.prevNetTime = now;
  }

  function formatSpeed(bytesPerSec) {
    if (bytesPerSec < 1024) return Math.round(bytesPerSec) + "B";
    if (bytesPerSec < 1048576) return Math.round(bytesPerSec / 1024) + "K";
    return (bytesPerSec / 1048576).toFixed(1) + "M";
  }

  // ── Helpers ──
  function findFirst(list, predicate) {
    for (var i = 0; i < list.length; i++) {
      if (predicate(list[i])) return list[i];
    }
    return null;
  }

  function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
  }

  function tooltipY(height) {
    if (!tooltipAnchor) return 0;
    var pos = tooltipAnchor.mapToItem(barContent, 0, 0);
    var y = barContent.y + pos.y + (tooltipAnchor.height - height) / 2;
    return Math.round(clamp(y, tooltipMargin, barPanel.height - height - tooltipMargin));
  }

  function formatWindowTitle(t) {
    if (!t) return "";
    return t
      .replace(/ — Mozilla Firefox$/, "")
      .replace(/ — Zen Browser$/, "Zen")
      .replace(/ - Neovim$/, " Neovim")
      .replace(/ - foot$/, "");
  }

  // ── Volume ──
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

  // ── WiFi ──
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
  property string wifiIconStr: {
    if (!wifiNet) return "󰤯";
    var s = wifiNet.signalStrength;
    if (s < 0.2) return "󰤟";
    if (s < 0.4) return "󰤢";
    if (s < 0.6) return "󰤥";
    return "󰤨";
  }
  Process { id: wifiProc; command: ["sh", "-lc", "foot -e nmtui"] }

  // ── Battery ──
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
  property string batIconStr: {
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

  property string hwTooltip: "CPU: " + barPanel.cpuPct + "%\nRAM: " + barPanel.memPct + "%\nNet: " + barPanel.netDown + "↓ " + barPanel.netUp + "↑"

  // ── Media ──
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
  ? (barPanel.mediaText + "\nPrev / Play / Next\nScroll: volume")
  : ""
  property real mediaProgress: mediaPlayer && mediaPlayer.length > 0
  ? mediaPlayer.position / mediaPlayer.length : 0

  Timer {
    interval: 1000
    running: barPanel.mediaPlayer && barPanel.mediaPlayer.isPlaying
    repeat: true
    onTriggered: { if (barPanel.mediaPlayer) barPanel.mediaPlayer.positionChanged(); }
  }

  // ── Tooltip state ──
  property bool mediaHover: mediaSection.visible && mediaSectionHover.containsMouse
  property bool volHover: volMouse.containsMouse
  property bool wifiHover: wifiHoverHandler.hovered || wifiMouse.containsMouse
  property bool batHover: batPresent && batHoverHandler.hovered
  property bool hwHover: hwWidget.visible && hwHoverHandler.hovered
  property var tooltipAnchor: mediaHover ? mediaSection : (volHover ? volWidget : (wifiHover ? wifiPill : (batHover ? batteryPill : (hwHover ? hwWidget : null))))
  property string tooltipText: mediaHover ? barPanel.mediaTooltip : (volHover ? barPanel.volTooltip : (wifiHover ? barPanel.wifiTooltip : (batHover ? barPanel.batTooltip : (hwHover ? barPanel.hwTooltip : ""))))
  property bool tooltipVisible: tooltipText !== ""
  property int tooltipTop: tooltipAnchor ? tooltipY(100) : 0
  property int tooltipLeft: Math.round(barPanel.barWidth + barPanel.tooltipGap)

  Item {
    id: barContent
    anchors.fill: parent

    Column {
      id: mainColumn
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 12
      spacing: 6

      // ── Workspace indicators ──
      Column {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4

        Repeater {
          model: barPanel.workspaces
          delegate: Rectangle {
            required property var modelData
            property bool isFocused: modelData.is_focused
            width: isFocused ? 14 : 8
            height: isFocused ? 14 : 8
            radius: height / 2
            color: isFocused ? colors.accent : colors.fgDim
            opacity: isFocused ? 1.0 : 0.5
            anchors.horizontalCenter: parent.horizontalCenter

            Behavior on width {
              NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }
            Behavior on height {
              NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }
            Behavior on color {
              ColorAnimation { duration: 200 }
            }
            Behavior on opacity {
              NumberAnimation { duration: 200 }
            }
          }
        }
      }

      // ── Active window title ──
      Item {
        width: barPanel.barWidth - 8
        height: 28
        visible: barPanel.activeWindowTitle !== ""
        anchors.horizontalCenter: parent.horizontalCenter

        Text {
          anchors.centerIn: parent
          width: parent.width
          text: barPanel.formatWindowTitle(barPanel.activeWindowTitle)
          color: colors.fgMid
          font.family: barPanel.uiFont
          font.pixelSize: 9
          font.italic: true
          elide: Text.ElideRight
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.NoWrap
          maximumLineCount: 1
        }
      }

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 20
        height: 1
        color: colors.border
        radius: 1
      }

      // ── Media controls ──
      Column {
        id: mediaSection
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4
        visible: barPanel.mediaText !== ""

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          width: barPanel.barWidth - 12
          text: barPanel.mediaPlayer ? (barPanel.mediaPlayer.trackTitle || "") : ""
          color: colors.fg
          font.family: barPanel.uiFont
          font.pixelSize: 9
          font.bold: true
          elide: Text.ElideRight
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.NoWrap
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          width: barPanel.barWidth - 12
          text: barPanel.mediaPlayer ? (barPanel.mediaPlayer.trackArtist || "") : ""
          color: colors.fgDim
          font.family: barPanel.uiFont
          font.pixelSize: 8
          elide: Text.ElideRight
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.NoWrap
        }

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 2

          Rectangle {
            width: 16
            height: 16
            radius: 4
            color: prevHover.containsMouse ? colors.bgSubtle : "transparent"

            Text {
              anchors.centerIn: parent
              text: ""
              color: colors.fg
              font.family: barPanel.uiFont
              font.pixelSize: 10
            }

            HoverHandler { id: prevHover }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (barPanel.mediaPlayer) barPanel.mediaPlayer.previous();
              }
            }
          }

          Rectangle {
            width: 20
            height: 20
            radius: 10
            color: colors.accent

            Text {
              anchors.centerIn: parent
              text: barPanel.mediaPlayer && barPanel.mediaPlayer.isPlaying ? "" : ""
              color: colors.bg
              font.family: barPanel.uiFont
              font.pixelSize: 10
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (barPanel.mediaPlayer) barPanel.mediaPlayer.togglePlaying();
              }
            }
          }

          Rectangle {
            width: 16
            height: 16
            radius: 4
            color: nextHover.containsMouse ? colors.bgSubtle : "transparent"

            Text {
              anchors.centerIn: parent
              text: ""
              color: colors.fg
              font.family: barPanel.uiFont
              font.pixelSize: 10
            }

            HoverHandler { id: nextHover }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (barPanel.mediaPlayer) barPanel.mediaPlayer.next();
              }
            }
          }
        }

        Item {
          anchors.horizontalCenter: parent.horizontalCenter
          width: 36
          height: 4

          Rectangle {
            anchors.fill: parent
            radius: 2
            color: colors.bgSubtle

            Rectangle {
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.bottom: parent.bottom
              width: parent.width * barPanel.mediaProgress
              radius: 2
              color: colors.accent

              Behavior on width {
                NumberAnimation { duration: 300; easing.type: Easing.Linear }
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: function(mouse) {
              if (barPanel.mediaPlayer && barPanel.mediaPlayer.canSeek) {
                barPanel.mediaPlayer.position = mouse.x / width * barPanel.mediaPlayer.length;
              }
            }
          }
        }

        MouseArea {
          id: mediaSectionHover
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.NoButton
        }
      }

      // ── Clock ──
      Column {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: -2

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: barPanel.hourStr
          color: colors.fg
          font.family: barPanel.uiFont
          font.pixelSize: 20
          font.bold: true
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: barPanel.minuteStr
          color: colors.fgMid
          font.family: barPanel.uiFont
          font.pixelSize: 14
        }
      }

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 20
        height: 1
        color: colors.border
        radius: 1
      }

      // ── Volume ──
      Item {
        id: volWidget
        width: parent.width
        implicitHeight: volLayout.implicitHeight

        Column {
          id: volLayout
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 2

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
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
            font.pixelSize: 14
          }

          Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 6
            height: 48

            Rectangle {
              anchors.horizontalCenter: parent.horizontalCenter
              width: parent.width
              height: parent.height
              radius: 3
              color: colors.bgSubtle

              Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: parent.width
                height: parent.height * barPanel.volPct
                radius: 3
                color: barPanel.volMuted ? colors.red : colors.accent

                Behavior on height {
                  NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
                }
                Behavior on color {
                  ColorAnimation { duration: 150 }
                }
              }
            }
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(barPanel.volPct * 100) + "%"
            color: barPanel.volMuted ? colors.red : colors.fg
            font.family: barPanel.uiFont
            font.pixelSize: 9
            font.bold: true
          }
        }

        MouseArea {
          id: volMouse
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.RightButton

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

      // ── Hardware monitors ──
      Column {
        id: hwWidget
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 3
        visible: true

        HoverHandler { id: hwHoverHandler }

        Column {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 1

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: ""
            color: colors.fgDim
            font.family: barPanel.uiFont
            font.pixelSize: 9
          }

          Item {
            width: 30
            height: 3

            Rectangle {
              width: parent.width
              height: parent.height
              radius: 2
              color: colors.bgSubtle

              Rectangle {
                width: parent.width * (barPanel.cpuPct / 100)
                height: parent.height
                radius: 2
                color: barPanel.cpuPct > 80 ? colors.red : (barPanel.cpuPct > 50 ? colors.yellow : colors.teal)

                Behavior on width {
                  NumberAnimation { duration: 300; easing.type: Easing.Linear }
                }
                Behavior on color {
                  ColorAnimation { duration: 300 }
                }
              }
            }
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: barPanel.cpuPct + "%"
            color: barPanel.cpuPct > 80 ? colors.red : colors.fgDim
            font.family: barPanel.uiFont
            font.pixelSize: 8
          }
        }

        Column {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 1

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: ""
            color: colors.fgDim
            font.family: barPanel.uiFont
            font.pixelSize: 9
          }

          Item {
            width: 30
            height: 3

            Rectangle {
              width: parent.width
              height: parent.height
              radius: 2
              color: colors.bgSubtle

              Rectangle {
                width: parent.width * (barPanel.memPct / 100)
                height: parent.height
                radius: 2
                color: barPanel.memPct > 85 ? colors.red : (barPanel.memPct > 60 ? colors.yellow : colors.purple)

                Behavior on width {
                  NumberAnimation { duration: 300; easing.type: Easing.Linear }
                }
                Behavior on color {
                  ColorAnimation { duration: 300 }
                }
              }
            }
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: barPanel.memPct + "%"
            color: barPanel.memPct > 85 ? colors.red : colors.fgDim
            font.family: barPanel.uiFont
            font.pixelSize: 8
          }
        }

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 2

          Text {
            text: "↓" + barPanel.netDown
            color: colors.teal
            font.family: barPanel.uiFont
            font.pixelSize: 7
          }

          Text {
            text: "↑" + barPanel.netUp
            color: colors.orange
            font.family: barPanel.uiFont
            font.pixelSize: 7
          }
        }
      }

      // ── WiFi ──
      Pill {
        id: wifiPill
        anchors.horizontalCenter: parent.horizontalCenter

        HoverHandler { id: wifiHoverHandler }

        Text {
          anchors.left: parent.left
          anchors.leftMargin: padding
          anchors.verticalCenter: parent.verticalCenter
          text: barPanel.wifiIconStr
          color: barPanel.wifiNet ? colors.accent : colors.fgDim
          font.family: barPanel.uiFont
          font.pixelSize: 14
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

      // ── Battery ──
      Pill {
        id: batteryPill
        anchors.horizontalCenter: parent.horizontalCenter
        visible: barPanel.batPresent

        HoverHandler { id: batHoverHandler }

        Text {
          anchors.left: parent.left
          anchors.leftMargin: padding
          anchors.verticalCenter: parent.verticalCenter
          text: barPanel.batIconStr
          color: barPanel.batColor
          font.family: barPanel.uiFont
          font.pixelSize: 14
        }
      }

      Item { width: parent.width; height: 1 }
    }
  }

  // ── Tooltip ──
  PanelWindow {
    id: tooltipWindow
    visible: barPanel.tooltipVisible
    focusable: false
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    anchors { top: true; left: true }
    margins { top: barPanel.tooltipTop; left: barPanel.tooltipLeft }

    implicitWidth: tooltipCard.implicitWidth + 6
    implicitHeight: tooltipCard.implicitHeight + 3

    Rectangle {
      id: tooltipShadow
      width: tooltipCard.implicitWidth
      implicitHeight: tooltipTextItem.paintedHeight + barPanel.tooltipPadding * 2
      height: implicitHeight
      radius: 10
      color: Qt.rgba(0, 0, 0, 0.25)
      opacity: barPanel.tooltipVisible ? 0.7 : 0
      x: 3
      y: 3
      antialiasing: true

      Behavior on opacity {
        NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
      }
    }

    Rectangle {
      id: tooltipCard
      width: Math.min(barPanel.tooltipMaxWidth, tooltipTextItem.implicitWidth + barPanel.tooltipPadding * 2)
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
}
