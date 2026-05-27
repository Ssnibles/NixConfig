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
  implicitWidth: 52
  exclusionMode: ExclusionMode.Auto
  color: colors.bg

  property string uiFont: "JetBrains Mono"
  property int barPad: 8
  property int capsuleSpacing: 6

  // ════════════════════════════════════════════════════════════
  // Time
  // ════════════════════════════════════════════════════════════
  property string hourStr: ""
  property string minuteStr: ""

  function updateTime() {
    var d = new Date();
    barPanel.hourStr = Qt.formatTime(d, "hh");
    barPanel.minuteStr = Qt.formatTime(d, "mm");
    timeTimer.interval = 60000 - (d.getSeconds() * 1000 + d.getMilliseconds());
    timeTimer.restart();
  }

  Timer {
    id: timeTimer
    running: true
    repeat: false
    onTriggered: barPanel.updateTime()
  }

  // ════════════════════════════════════════════════════════════
  // Niri state
  // ════════════════════════════════════════════════════════════
  property var workspaces: []
  property string activeWindowTitle: ""
  property string activeWindowAppId: ""

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

    onExited: restartTimer.start()
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
      if (barPanel.activeWindowTitle !== "") winRefreshQuery.exec();
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
            barPanel.activeWindowTitle = focused ? (focused.title || "") : "";
            barPanel.activeWindowAppId = focused ? (focused.app_id || "") : "";
          }
        } catch(e) {
          barPanel.activeWindowTitle = "";
          barPanel.activeWindowAppId = "";
        }
      }
    }
  }

  // ════════════════════════════════════════════════════════════
  // Hardware monitoring
  // ════════════════════════════════════════════════════════════
  property int cpuPct: 0
  property int memPct: 0
  property string netDown: ""
  property string netUp: ""
  property int prevCpuTotal: 0
  property int prevCpuIdle: 0
  property int prevNetRx: 0
  property int prevNetTx: 0
  property int prevNetTime: 0

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
      if (dTotal > 0) barPanel.cpuPct = Math.round((1 - dIdle / dTotal) * 100);
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
    if (total > 0) barPanel.memPct = Math.round((1 - available / total) * 100);
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

  function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }
  function findFirst(list, pred) {
    for (var i = 0; i < list.length; i++) if (pred(list[i])) return list[i];
    return null;
  }

  function formatWindowTitle(t) {
    if (!t) return "";
    return t
      .replace(/ — Mozilla Firefox$/, "")
      .replace(/ — Zen Browser$/, "Zen")
      .replace(/ - Neovim$/, " Neovim")
      .replace(/ - foot$/, "");
  }

  // ════════════════════════════════════════════════════════════
  // Volume
  // ════════════════════════════════════════════════════════════
  property var volNodes: Pipewire.ready && Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
  PwObjectTracker { objects: barPanel.volNodes }
  property var volInfo: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
  property real volPct: volInfo ? volInfo.volume : 0
  property bool volMuted: volInfo ? volInfo.muted : false

  // ════════════════════════════════════════════════════════════
  // WiFi
  // ════════════════════════════════════════════════════════════
  property var wifiDev: findFirst(Networking.devices.values, function(d) { return d.type === DeviceType.Wifi; })
  property var wifiNet: findFirst(wifiDev ? wifiDev.networks.values : [], function(n) { return n.connected; })
  property string wifiIconStr: {
    if (!wifiNet) return "󰤯";
    var s = wifiNet.signalStrength;
    if (s < 0.2) return "󰤟";
    if (s < 0.4) return "󰤢";
    if (s < 0.6) return "󰤥";
    return "󰤨";
  }
  Process { id: wifiProc; command: ["sh", "-lc", "foot -e nmtui"] }

  // ════════════════════════════════════════════════════════════
  // Battery
  // ════════════════════════════════════════════════════════════
  function batDevice() {
    var count = UPower.devices.count;
    for (var i = 0; i < count; i++) {
      var d = UPower.devices.get(i);
      if (d.isLaptopBattery && d.ready) return d;
    }
    return UPower.displayDevice && UPower.displayDevice.ready ? UPower.displayDevice : null;
  }
  readonly property bool batPresent: UPower.devices.count > 0 || (UPower.displayDevice && UPower.displayDevice.ready)
  readonly property int batPct: { var d = batDevice(); return d ? Math.round(d.percentage * 100) : 0; }
  readonly property bool batCharging: { var d = batDevice(); return d && d.state === UPowerDeviceState.Charging; }
  readonly property bool batPlugged: { var d = batDevice(); return d && d.state === UPowerDeviceState.FullyCharged; }
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
  property color batColor: {
    if (!batPresent) return colors.fg;
    if (batCharging || batPlugged) return colors.green;
    if (batPct <= 15) return colors.red;
    if (batPct <= 30) return colors.yellow;
    return colors.fg;
  }

  // ════════════════════════════════════════════════════════════
  // Media
  // ════════════════════════════════════════════════════════════
  property var mediaPlayers: Mpris.players.values
  property var mediaPlayer: {
    var playing = findFirst(mediaPlayers, function(p) { return p.isPlaying; });
    return playing ? playing : findFirst(mediaPlayers, function(p) { return p.playbackState === MprisPlaybackState.Paused; });
  }
  property string mediaTrack: mediaPlayer ? (mediaPlayer.trackTitle || "") : ""
  property string mediaArtist: mediaPlayer ? (mediaPlayer.trackArtist || "") : ""
  property bool mediaPlaying: mediaPlayer ? mediaPlayer.isPlaying : false
  property real mediaProgress: mediaPlayer && mediaPlayer.length > 0 ? mediaPlayer.position / mediaPlayer.length : 0
  property bool mediaVisible: mediaTrack !== ""

  Timer {
    interval: 1000
    running: barPanel.mediaPlayer && barPanel.mediaPlaying
    repeat: true
    onTriggered: { if (barPanel.mediaPlayer) barPanel.mediaPlayer.positionChanged(); }
  }

  // ════════════════════════════════════════════════════════════
  // Content
  // ════════════════════════════════════════════════════════════
  Item {
    id: barContent
    anchors.fill: parent

    Column {
      id: mainColumn
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: barPanel.barPad
      anchors.bottom: parent.bottom
      anchors.bottomMargin: barPanel.barPad
      spacing: barPanel.capsuleSpacing

      // ── Top spacer ──
      Item { width: 1; height: 2 }

      // ── Workspace capsule ──
      Rectangle {
        id: wsCapsule
        anchors.horizontalCenter: parent.horizontalCenter
        width: 38
        height: wsColumn.implicitHeight + 10
        radius: 10
        color: colors.bgRaised
        border.width: 1
        border.color: Qt.alpha(colors.border, 0.3)
        opacity: barPanel.workspaces.length > 0 ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: 200 } }

        Column {
          id: wsColumn
          anchors.centerIn: parent
          spacing: 4

          Repeater {
            model: barPanel.workspaces
            delegate: Rectangle {
              required property var modelData
              property bool isFocused: modelData.is_focused
              property int wsIdx: modelData.idx

              width: isFocused ? 28 : 18
              height: isFocused ? 12 : 10
              radius: height / 2
              color: isFocused ? colors.accent : colors.fgDim
              opacity: isFocused ? 1.0 : 0.45
              anchors.horizontalCenter: parent.horizontalCenter

              Behavior on width  { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
              Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
              Behavior on color  { ColorAnimation { duration: 220 } }
              Behavior on opacity { NumberAnimation { duration: 220 } }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: wsActionProc.switchTo(wsIdx)
              }
            }
          }
        }
      }

      // ── Active window pill ──
      Rectangle {
        id: winCapsule
        anchors.horizontalCenter: parent.horizontalCenter
        width: 38
        height: barPanel.activeWindowTitle !== "" ? 36 : 0
        radius: 10
        color: colors.bgRaised
        border.width: 1
        border.color: Qt.alpha(colors.border, 0.3)
        clip: true
        visible: barPanel.activeWindowTitle !== ""

        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Text {
          anchors.centerIn: parent
          width: parent.width - 8
          text: barPanel.formatWindowTitle(barPanel.activeWindowTitle)
          color: colors.fgMid
          font.family: barPanel.uiFont
          font.pixelSize: 9
          font.italic: true
          elide: Text.ElideRight
          horizontalAlignment: Text.AlignHCenter
          maximumLineCount: 2
          wrapMode: Text.WordWrap
          lineHeight: 0.9
        }
      }

      // ── Center spacer ──
      Item { width: 1; height: 6 }

      // ── Clock capsule ──
      Rectangle {
        id: clockCapsule
        anchors.horizontalCenter: parent.horizontalCenter
        width: 42
        height: clockColumn.implicitHeight + 12
        radius: 12
        color: colors.bgRaised
        border.width: 1
        border.color: Qt.alpha(colors.border, 0.3)

        Column {
          id: clockColumn
          anchors.centerIn: parent
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
            color: colors.accent
            font.family: barPanel.uiFont
            font.pixelSize: 13
          }
        }
      }

      // ── Center spacer ──
      Item { width: 1; height: 6 }

      // ── Media capsule ──
      Rectangle {
        id: mediaCapsule
        anchors.horizontalCenter: parent.horizontalCenter
        width: 38
        height: mediaVisible ? mediaColumn.implicitHeight + 10 : 0
        radius: 10
        color: colors.bgRaised
        border.width: 1
        border.color: Qt.alpha(colors.border, 0.3)
        clip: true
        visible: mediaVisible

        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Column {
          id: mediaColumn
          anchors.centerIn: parent
          spacing: 3

          // Art / icon
          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 22; height: 22
            radius: 6
            color: colors.accent
            Text {
              anchors.centerIn: parent
              text: "󰝚"
              color: colors.bg
              font.family: barPanel.uiFont
              font.pixelSize: 12
            }
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.parent.width - 6
            text: barPanel.mediaTrack
            color: colors.fg
            font.family: barPanel.uiFont
            font.pixelSize: 8
            font.bold: true
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            maximumLineCount: 1
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.parent.width - 6
            text: barPanel.mediaArtist
            color: colors.fgDim
            font.family: barPanel.uiFont
            font.pixelSize: 7
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            maximumLineCount: 1
            visible: text !== ""
          }

          // Play/Pause button
          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 24; height: 24
            radius: 12
            color: mediaBtnHover.containsMouse ? Qt.alpha(colors.accent, 0.3) : "transparent"
            scale: mediaBtnHover.containsMouse ? 0.92 : 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

            Text {
              anchors.centerIn: parent
              text: barPanel.mediaPlaying ? "󰏦" : "󰐊"
              color: colors.fg
              font.family: barPanel.uiFont
              font.pixelSize: 14
            }

            HoverHandler { id: mediaBtnHover }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (barPanel.mediaPlayer) barPanel.mediaPlayer.togglePlaying();
              }
            }
          }

          // Progress bar
          Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 28; height: 3

            Rectangle {
              anchors.fill: parent
              radius: 2
              color: colors.bgSubtle
            }
            Rectangle {
              width: parent.width * barPanel.mediaProgress
              height: parent.height
              radius: 2
              color: colors.accent
              Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.Linear } }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: function(mouse) {
                if (barPanel.mediaPlayer && barPanel.mediaPlayer.canSeek)
                  barPanel.mediaPlayer.position = mouse.x / width * barPanel.mediaPlayer.length;
              }
            }
          }
        }
      }

      // ── Volume capsule ──
      Rectangle {
        id: volCapsule
        anchors.horizontalCenter: parent.horizontalCenter
        width: 38
        height: volColumn.implicitHeight + 10
        radius: 10
        color: colors.bgRaised
        border.width: 1
        border.color: Qt.alpha(colors.border, 0.3)

        Column {
          id: volColumn
          anchors.centerIn: parent
          spacing: 3

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
              if (barPanel.volMuted) return "󰝟"
              var v = barPanel.volPct;
              if (v <= 0) return "󰝟"
              if (v < 0.33) return "󰕿"
              if (v < 0.66) return "󰖀"
              return "󰕾"
            }
            color: barPanel.volMuted ? colors.red : colors.fg
            font.family: barPanel.uiFont
            font.pixelSize: 14
          }

          // Vertical slider
          Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 6; height: 44

            Rectangle {
              anchors.horizontalCenter: parent.horizontalCenter
              width: parent.width; height: parent.height
              radius: 3
              color: colors.bgSubtle

              Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: parent.width
                height: parent.height * barPanel.volPct
                radius: 3
                color: barPanel.volMuted ? colors.red : colors.accent

                Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Behavior on color  { ColorAnimation { duration: 120 } }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: function(mouse) {
                var frac = 1 - mouse.y / height;
                if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio)
                  Pipewire.defaultAudioSink.audio.volume = clamp(frac, 0, 1);
              }
              onWheel: function(wheel) {
                if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                  var step = 0.05;
                  var dir = wheel.angleDelta.y > 0 ? 1 : -1;
                  Pipewire.defaultAudioSink.audio.volume = clamp(barPanel.volPct + dir * step, 0, 1);
                }
              }
            }
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: barPanel.volMuted ? "--%" : Math.round(barPanel.volPct * 100) + "%"
            color: barPanel.volMuted ? colors.red : colors.fgDim
            font.family: barPanel.uiFont
            font.pixelSize: 9
            font.bold: true
          }
        }
      }

      // ── System capsule ──
      Rectangle {
        id: sysCapsule
        anchors.horizontalCenter: parent.horizontalCenter
        width: 38
        height: sysColumn.implicitHeight + 10
        radius: 10
        color: colors.bgRaised
        border.width: 1
        border.color: Qt.alpha(colors.border, 0.3)

        Column {
          id: sysColumn
          anchors.centerIn: parent
          spacing: 3

          // WiFi
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: barPanel.wifiIconStr
            color: barPanel.wifiNet ? colors.accent : colors.fgDim
            font.family: barPanel.uiFont
            font.pixelSize: 14
            visible: barPanel.wifiIconStr !== ""

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              acceptedButtons: Qt.RightButton
              onClicked: {
                wifiProc.running = true;
              }
            }
          }

          // Battery
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: barPanel.batIconStr
            color: barPanel.batColor
            font.family: barPanel.uiFont
            font.pixelSize: 14
            visible: barPanel.batIconStr !== ""
          }

          // Separator
          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 18; height: 1
            radius: 1
            color: Qt.alpha(colors.border, 0.3)
          }

          // CPU bar
          Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 2

            Item {
              anchors.horizontalCenter: parent.horizontalCenter
              width: 28; height: 3

              Rectangle {
                anchors.fill: parent
                radius: 2
                color: colors.bgSubtle

                Rectangle {
                  width: parent.width * (barPanel.cpuPct / 100)
                  height: parent.height
                  radius: 2
                  color: barPanel.cpuPct > 80 ? colors.red : (barPanel.cpuPct > 50 ? colors.yellow : colors.teal)
                  Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.Linear } }
                  Behavior on color { ColorAnimation { duration: 300 } }
                }
              }
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "CPU " + barPanel.cpuPct + "%"
              color: barPanel.cpuPct > 80 ? colors.red : colors.fgDim
              font.family: barPanel.uiFont
              font.pixelSize: 7
            }
          }

          // RAM bar
          Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 2

            Item {
              anchors.horizontalCenter: parent.horizontalCenter
              width: 28; height: 3

              Rectangle {
                anchors.fill: parent
                radius: 2
                color: colors.bgSubtle

                Rectangle {
                  width: parent.width * (barPanel.memPct / 100)
                  height: parent.height
                  radius: 2
                  color: barPanel.memPct > 85 ? colors.red : (barPanel.memPct > 60 ? colors.yellow : colors.purple)
                  Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.Linear } }
                  Behavior on color { ColorAnimation { duration: 300 } }
                }
              }
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "RAM " + barPanel.memPct + "%"
              color: barPanel.memPct > 85 ? colors.red : colors.fgDim
              font.family: barPanel.uiFont
              font.pixelSize: 7
            }
          }

          // Network speeds
          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4

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
      }

      // ── Bottom spacer ──
      Item { width: 1; height: 2 }
    }
  }

  Process {
    id: wsActionProc
    command: ["sh", "-c", "true"]
    property int targetWs: 0

    function switchTo(ws) {
      targetWs = ws;
      command = ["niri", "msg", "action", "focus-workspace", "" + ws];
      running = false;
      running = true;
    }
  }
}
