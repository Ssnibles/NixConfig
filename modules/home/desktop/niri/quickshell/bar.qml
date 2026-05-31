import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Networking

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

  // ════════════════════════════════════════════════════════════════
  // Helpers
  // ════════════════════════════════════════════════════════════════
  function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }
  function findFirst(list, pred) {
    for (var i = 0; i < list.length; i++) if (pred(list[i])) return list[i];
    return null;
  }

  // ════════════════════════════════════════════════════════════════
  // Niri event stream — event-driven IPC (no polling)
  // ════════════════════════════════════════════════════════════════
  property string activeWindowTitle: ""

  ListModel {
    id: wsModel
  }

  function syncWorkspaces(wsArray) {
    var rebuild = wsModel.count !== wsArray.length;
    if (!rebuild) {
      for (var i = 0; i < wsArray.length; i++) {
        if (wsModel.get(i).idx !== wsArray[i].idx) { rebuild = true; break; }
      }
    }
    if (rebuild) {
      wsModel.clear();
      for (var i = 0; i < wsArray.length; i++) {
        wsModel.append({"idx": wsArray[i].idx, "is_focused": wsArray[i].is_focused});
      }
    } else {
      for (var i = 0; i < wsModel.count; i++) {
        wsModel.setProperty(i, "is_focused", wsArray[i].is_focused);
      }
    }
  }

  Process {
    id: niriMonitor
    command: ["niri", "msg", "--json", "event-stream"]
    running: true

    stdout: StdioCollector {
      property int lastPos: 0
      waitForEnd: false
      onDataChanged: {
        var newText = this.text.substring(lastPos);
        var lines = newText.split("\n");
        var isComplete = newText.endsWith("\n");
        if (isComplete) {
          lastPos = this.text.length;
        } else {
          var lastLineIdx = newText.lastIndexOf("\n");
          if (lastLineIdx >= 0) {
            lastPos = this.text.length - (newText.length - lastLineIdx) + 1;
          }
        }
        for (var i = 0; i < lines.length - (isComplete ? 0 : 1); i++) {
          var line = lines[i].trim();
          if (line === "") continue;
          try {
            var event = JSON.parse(line);

            if (event.WorkspacesChanged !== undefined) {
              var ws = event.WorkspacesChanged.workspaces;
              if (Array.isArray(ws)) {
                ws.sort(function(a, b) { return a.idx - b.idx; });
                syncWorkspaces(ws);
              }
            }

            if (event.WorkspaceActivated !== undefined) {
              workspaceRefresh.running = false;
              workspaceRefresh.running = true;
            }

            if (event.WindowTitleChanged !== undefined) {
              var titleEvent = event.WindowTitleChanged;
              if (titleEvent.title) {
                barPanel.activeWindowTitle = titleEvent.title;
              }
            }

            if (event.WindowsChanged !== undefined) {
              windowTitleRefresh.running = false;
              windowTitleRefresh.running = true;
            }
          } catch(e) {}
        }
      }
    }

    onExited: { restartTimer.start(); }
  }

  Timer {
    id: restartTimer
    interval: 2000
    running: false
    repeat: false
    onTriggered: {
      niriMonitor.stdout.lastPos = 0;
      niriMonitor.running = false;
      niriMonitor.running = true;
    }
  }

  Timer {
    id: initialQuery
    interval: 500
    running: true
    repeat: false
    onTriggered: {
      wsInitQuery.running = true;
      windowTitleQuery.running = true;
    }
  }

  function loadWorkspaces(replyText) {
    try {
      var parsed = JSON.parse(replyText.trim());
      var wsData = null;
      if (Array.isArray(parsed)) {
        wsData = parsed;
      } else if (parsed.Ok) {
        wsData = parsed.Ok.Workspaces || parsed.Ok;
      } else if (parsed.Workspaces) {
        wsData = parsed.Workspaces;
      }
      if (Array.isArray(wsData)) {
        wsData.sort(function(a, b) { return a.idx - b.idx; });
        syncWorkspaces(wsData);
      }
    } catch(e) {}
  }

  function loadActiveTitle(replyText) {
    try {
      var parsed = JSON.parse(replyText.trim());
      var windows = Array.isArray(parsed) ? parsed : (parsed.Ok || []);
      for (var i = 0; i < windows.length; i++) {
        if (windows[i].is_focused && windows[i].title) {
          barPanel.activeWindowTitle = windows[i].title;
          return;
        }
      }
    } catch(e) {}
  }

  Process {
    id: wsInitQuery
    running: false
    command: ["niri", "msg", "--json", "workspaces"]
    stdout: StdioCollector {
      onDataChanged: { loadWorkspaces(this.text); }
    }
  }

  Process {
    id: workspaceRefresh
    running: false
    command: ["niri", "msg", "--json", "workspaces"]
    stdout: StdioCollector {
      onDataChanged: { loadWorkspaces(this.text); }
    }
  }

  Process {
    id: windowTitleQuery
    running: false
    command: ["niri", "msg", "--json", "windows"]
    stdout: StdioCollector {
      onDataChanged: { loadActiveTitle(this.text); }
    }
  }

  Process {
    id: windowTitleRefresh
    running: false
    command: ["niri", "msg", "--json", "windows"]
    stdout: StdioCollector {
      onDataChanged: { loadActiveTitle(this.text); }
    }
  }

  Process {
    id: wsActionProc
    running: false
  }

  // ════════════════════════════════════════════════════════════════
  // Hardware monitoring — lightweight /proc reads
  // ════════════════════════════════════════════════════════════════
  property real cpuPercent: 0
  property real memPercent: 0
  property string netDownStr: "0"
  property string netUpStr: "0"

  Process {
    id: hwMonitor
    command: ["bash", "-c", "cat /proc/stat /proc/meminfo /proc/net/dev"]
    running: false

    stdout: StdioCollector {
      onDataChanged: {
        parseHwData(this.text);
      }
    }
  }

  property string prevCpuLine: ""
  property var prevNetBytes: ({})

  function parseHwData(text) {
    var lines = text.split("\n");

    for (var i = 0; i < lines.length; i++) {
      if (lines[i].indexOf("cpu ") === 0) {
        var parts = lines[i].split(/\s+/);
        var user = parseInt(parts[1]);
        var nice = parseInt(parts[2]);
        var system = parseInt(parts[3]);
        var idle = parseInt(parts[4]);
        var iowait = parseInt(parts[5]) || 0;
        var irq = parseInt(parts[6]) || 0;
        var softirq = parseInt(parts[7]) || 0;
        var steal = parseInt(parts[8]) || 0;

        var total = user + nice + system + idle + iowait + irq + softirq + steal;
        var busy = total - idle - iowait;

        if (barPanel.prevCpuLine !== "") {
          var prevParts = barPanel.prevCpuLine.split(/\s+/);
          var prevUser = parseInt(prevParts[1]);
          var prevNice = parseInt(prevParts[2]);
          var prevSystem = parseInt(prevParts[3]);
          var prevIdle = parseInt(prevParts[4]);
          var prevIowait = parseInt(prevParts[5]) || 0;
          var prevIrq = parseInt(prevParts[6]) || 0;
          var prevSoftirq = parseInt(prevParts[7]) || 0;
          var prevSteal = parseInt(prevParts[8]) || 0;

          var prevTotal = prevUser + prevNice + prevSystem + prevIdle + prevIowait + prevIrq + prevSoftirq + prevSteal;
          var prevBusy = prevTotal - prevIdle - prevIowait;

          var dTotal = total - prevTotal;
          var dBusy = busy - prevBusy;
          if (dTotal > 0) {
            barPanel.cpuPercent = Math.round((dBusy / dTotal) * 100);
          }
        }
        barPanel.prevCpuLine = lines[i];
      }

      if (lines[i].indexOf("MemTotal:") === 0) {
        var memTotal = parseInt(lines[i].split(/\s+/)[1]);
        for (var j = i + 1; j < lines.length && j < i + 5; j++) {
          if (lines[j].indexOf("MemAvailable:") === 0) {
            var memAvail = parseInt(lines[j].split(/\s+/)[1]);
            if (memTotal > 0) {
              barPanel.memPercent = Math.round(((memTotal - memAvail) / memTotal) * 100);
            }
            break;
          }
        }
      }

      if (lines[i].indexOf(":") > 0 && lines[i].indexOf("eth") >= 0 || lines[i].indexOf("wlan") >= 0 || lines[i].indexOf("enp") >= 0 || lines[i].indexOf("wlp") >= 0) {
        var iface = lines[i].split(":")[0].trim();
        var stats = lines[i].split(":")[1].trim().split(/\s+/);
        var rxBytes = parseInt(stats[0]);
        var txBytes = parseInt(stats[8]);

        if (barPanel.prevNetBytes[iface]) {
          var prev = barPanel.prevNetBytes[iface];
          var drx = rxBytes - prev.rx;
          var dtx = txBytes - prev.tx;
          var elapsed = 5;
          barPanel.netDownStr = formatBytes(Math.max(0, drx / elapsed));
          barPanel.netUpStr = formatBytes(Math.max(0, dtx / elapsed));
        }
        var newNet = {};
        newNet[iface] = {rx: rxBytes, tx: txBytes};
        for (var k in barPanel.prevNetBytes) {
          if (k !== iface) newNet[k] = barPanel.prevNetBytes[k];
        }
        barPanel.prevNetBytes = newNet;
      }
    }
  }

  function formatBytes(bytesPerSec) {
    if (bytesPerSec < 1024) return Math.round(bytesPerSec) + "B";
    if (bytesPerSec < 1048576) return Math.round(bytesPerSec / 1024) + "K";
    return (bytesPerSec / 1048576).toFixed(1) + "M";
  }

  Timer {
    id: hwTimer
    interval: 5000
    running: true
    repeat: true
    onTriggered: {
      hwMonitor.running = false;
      hwMonitor.running = true;
    }
  }

  Component.onCompleted: {
    updateTime();
    hwMonitor.running = true;
  }

  // ════════════════════════════════════════════════════════════════
  // Clock
  // ════════════════════════════════════════════════════════════════
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

  // ════════════════════════════════════════════════════════════════
  // WiFi
  // ════════════════════════════════════════════════════════════════
  property var wifiDev: findFirst(Networking.devices.values, function(d) { return d.type === DeviceType.Wifi; })
  property var ethDev: findFirst(Networking.devices.values, function(d) { return d.type === DeviceType.Ethernet; })
  property var wifiNet: findFirst(wifiDev ? wifiDev.networks.values : [], function(n) { return n.connected; })

  property string netIconStr: {
    if (wifiNet) {
      var s = wifiNet.signalStrength;
      if (s < 0.2) return "\u{F091F}";
      if (s < 0.4) return "\u{F0922}";
      if (s < 0.6) return "\u{F0925}";
      return "\u{F0928}";
    }
    if (ethDev && ethDev.state === DeviceState.Activated) return "\u{F0200}";
    return "\u{F092F}";
  }

  // ════════════════════════════════════════════════════════════════
  // Volume
  // ════════════════════════════════════════════════════════════════
  property var volNodes: Pipewire.ready && Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
  PwObjectTracker { objects: barPanel.volNodes }
  property var volInfo: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
  property real volPct: volInfo ? volInfo.volume : 0
  property bool volMuted: volInfo ? volInfo.muted : false

  property string volIconStr: {
    if (barPanel.volMuted) return "\u{F075F}";
    var v = barPanel.volPct;
    if (v <= 0) return "\u{F075F}";
    if (v < 0.33) return "\u{F057F}";
    if (v < 0.66) return "\u{F0580}";
    return "\u{F057E}";
  }

  // ════════════════════════════════════════════════════════════════
  // Media
  // ════════════════════════════════════════════════════════════════
  property var mediaPlayers: Mpris.players.values
  property var mediaPlayer: {
    var playing = findFirst(mediaPlayers, function(p) { return p.isPlaying; });
    return playing ? playing : findFirst(mediaPlayers, function(p) {
        return p.playbackState === MprisPlaybackState.Paused;
    });
  }
  property string mediaText: mediaPlayer
  ? (mediaPlayer.trackArtist
    ? mediaPlayer.trackTitle + " \u2014 " + mediaPlayer.trackArtist
    : mediaPlayer.trackTitle)
  : ""

  // ════════════════════════════════════════════════════════════════
  // Layout
  // ════════════════════════════════════════════════════════════════

  // ── Media indicator (sideways, top) ──
  Text {
    id: mediaLabel
    x: 16
    y: 10
    text: barPanel.mediaText
    color: colors.fg
    font.family: barPanel.uiFont
    font.pixelSize: 10
    font.bold: true
    rotation: -90
    transformOrigin: Item.TopLeft
    elide: Text.ElideRight
    visible: barPanel.mediaText !== ""
    width: barPanel.height - 200
    height: 20
    maximumLineCount: 1
    horizontalAlignment: Text.AlignLeft
    verticalAlignment: Text.AlignVCenter
  }

  // ── Workspace indicators (vertical pills) ──
  Column {
    id: wsColumn
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: barPanel.mediaText !== "" ? 40 : 12
    spacing: 5

    Repeater {
      model: wsModel
      delegate: Rectangle {
        required property var modelData
        property bool isFocused: modelData.is_focused
        property int wsIdx: modelData.idx

        width: 12
        height: isFocused ? 32 : 12
        radius: 6
        color: isFocused ? colors.accent : colors.fgDim
        opacity: isFocused ? 1.0 : 0.45
        anchors.horizontalCenter: parent.horizontalCenter

        Behavior on height {
          SpringAnimation { spring: 5.0; damping: 0.3; epsilon: 0.3; mass: 0.5 }
        }
        Behavior on color  { ColorAnimation { duration: 200 } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            wsActionProc.command = ["niri", "msg", "action", "focus-workspace", String(wsIdx)];
            wsActionProc.startDetached();
          }
        }
      }
    }
  }

  // ── Hardware monitors ──
  Column {
    id: hwColumn
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: clockColumn.top
    anchors.bottomMargin: 12
    spacing: 8

    // CPU
    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 1
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "\u{F04BB}"
        color: barPanel.cpuPercent > 80 ? colors.red : (barPanel.cpuPercent > 50 ? colors.yellow : colors.fgDim)
        font.family: barPanel.uiFont
        font.pixelSize: 13
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: barPanel.cpuPercent + "%"
        color: barPanel.cpuPercent > 80 ? colors.red : colors.fgDim
        font.family: barPanel.uiFont
        font.pixelSize: 8
        font.bold: true
      }
    }

    // Memory
    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 1
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "\u{F035B}"
        color: barPanel.memPercent > 85 ? colors.red : (barPanel.memPercent > 60 ? colors.yellow : colors.fgDim)
        font.family: barPanel.uiFont
        font.pixelSize: 13
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: barPanel.memPercent + "%"
        color: barPanel.memPercent > 85 ? colors.red : colors.fgDim
        font.family: barPanel.uiFont
        font.pixelSize: 8
        font.bold: true
      }
    }

    // Network
    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 1
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "\u{F035D}"
        color: colors.fgDim
        font.family: barPanel.uiFont
        font.pixelSize: 11
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: barPanel.netDownStr
        color: colors.green
        font.family: barPanel.uiFont
        font.pixelSize: 7
        font.bold: true
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: barPanel.netUpStr
        color: colors.purple
        font.family: barPanel.uiFont
        font.pixelSize: 7
        font.bold: true
      }
    }
  }

  // ── Clock ──
  Column {
    id: clockColumn
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: wifiWidget.top
    anchors.bottomMargin: 12
    spacing: -2

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: barPanel.hourStr
      color: colors.fg
      font.family: barPanel.uiFont
      font.pixelSize: 14
      font.bold: true
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: barPanel.minuteStr
      color: colors.accent
      font.family: barPanel.uiFont
      font.pixelSize: 14
      font.bold: true
    }
  }

  // ── WiFi indicator ──
  Item {
    id: wifiWidget
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: volWidget.top
    anchors.bottomMargin: 8
    width: 44
    height: 32

    Rectangle {
      anchors.fill: parent
      radius: 10
      color: wifiHover.containsMouse ? colors.bgRaised : "transparent"
      Behavior on color { ColorAnimation { duration: 120 } }
    }

    Text {
      anchors.centerIn: parent
      text: barPanel.netIconStr
      color: barPanel.wifiNet ? colors.accent : colors.fgDim
      font.family: barPanel.uiFont
      font.pixelSize: 16
    }

    MouseArea {
      id: wifiMouseArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      acceptedButtons: Qt.RightButton
      onClicked: {
        wifiProc.command = ["sh", "-lc", "foot -e nmtui"];
        wifiProc.startDetached();
      }
    }

    HoverHandler { id: wifiHover }
  }

  // ── Volume indicator ──
  Item {
    id: volWidget
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 12
    width: 44
    height: 48

    Rectangle {
      anchors.fill: parent
      radius: 10
      color: volHover.containsMouse ? colors.bgRaised : "transparent"
      Behavior on color { ColorAnimation { duration: 120 } }
    }

    Column {
      anchors.centerIn: parent
      spacing: 2

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: barPanel.volIconStr
        color: barPanel.volMuted ? colors.red : colors.fg
        font.family: barPanel.uiFont
        font.pixelSize: 16
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Math.round(barPanel.volPct * 100) + "%"
        color: barPanel.volMuted ? colors.red : colors.fgDim
        font.family: barPanel.uiFont
        font.pixelSize: 10
        font.bold: true
      }
    }

    MouseArea {
      id: volMouseArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton) {
          volProc.startDetached();
        } else if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
          Pipewire.defaultAudioSink.audio.muted = !barPanel.volMuted;
        }
      }
      onWheel: function(wheel) {
        if (!Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio) return;
        var dir = wheel.angleDelta.y > 0 ? 1 : -1;
        Pipewire.defaultAudioSink.audio.volume = clamp(barPanel.volPct + dir * 0.05, 0, 1);
      }
    }

    HoverHandler { id: volHover }
  }

  Process { id: volProc; command: ["pavucontrol"] }
  Process { id: wifiProc; command: ["sh", "-lc", "foot -e nmtui"] }
}
