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
  implicitWidth: 48
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
  // Niri workspaces
  // ════════════════════════════════════════════════════════════════
  property var workspaces: []

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

            // Workspace list changed (add/remove/focus shift)
            if (event.WorkspacesChanged !== undefined) {
              var ws = event.WorkspacesChanged;
              if (Array.isArray(ws)) {
                ws.sort(function(a, b) { return a.idx - b.idx; });
                barPanel.workspaces = ws;
              }
            }

            // Workspace focus changed — re-query full list
            if (event.WorkspaceActivated !== undefined ||
                event.WorkspaceActiveOk !== undefined) {
              workspaceRefresh.running = false;
              workspaceRefresh.running = true;
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
    }
  }

  Process {
    id: wsInitQuery
    running: false
    command: ["sh", "-c", "niri msg -j workspaces"]
    stdout: StdioCollector {
      onDataChanged: {
        try {
          var wsData = JSON.parse(this.text.trim());
          if (Array.isArray(wsData)) {
            wsData.sort(function(a, b) { return a.idx - b.idx; });
            barPanel.workspaces = wsData;
          }
        } catch(e) {}
      }
    }
  }

  Process {
    id: workspaceRefresh
    running: false
    command: ["sh", "-c", "niri msg -j workspaces"]
    stdout: StdioCollector {
      onDataChanged: {
        try {
          var wsData = JSON.parse(this.text.trim());
          if (Array.isArray(wsData)) {
            wsData.sort(function(a, b) { return a.idx - b.idx; });
            barPanel.workspaces = wsData;
          }
        } catch(e) {}
      }
    }
  }

  Process {
    id: wsActionProc
    running: false
    command: ["sh", "-c", "true"]
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
      if (s < 0.2) return "󰤟";
      if (s < 0.4) return "󰤢";
      if (s < 0.6) return "󰤥";
      return "󰤨";
    }
    if (ethDev && ethDev.state === DeviceState.Activated) return "󰈀";
    return "󰤯";
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
    if (barPanel.volMuted) return "󰝟";
    var v = barPanel.volPct;
    if (v <= 0) return "󰝟";
    if (v < 0.33) return "󰕿";
    if (v < 0.66) return "󰖀";
    return "󰕾";
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
      ? mediaPlayer.trackTitle + " — " + mediaPlayer.trackArtist
      : mediaPlayer.trackTitle)
    : ""

  // ════════════════════════════════════════════════════════════════
  // Layout
  // ════════════════════════════════════════════════════════════════
  Component.onCompleted: updateTime()

  // ── Media indicator (sideways, top) ──
  Text {
    id: mediaLabel
    x: 14
    y: 10
    text: barPanel.mediaText
    color: colors.fg
    font.family: barPanel.uiFont
    font.pixelSize: 11
    font.bold: true
    rotation: -90
    transformOrigin: Item.TopLeft
    elide: Text.ElideRight
    visible: barPanel.mediaText !== ""
    width: barPanel.height - 50
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
      model: barPanel.workspaces
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

        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
        Behavior on color  { ColorAnimation { duration: 200 } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            wsActionProc.command = ["sh", "-c", "niri msg action focus-workspace " + wsIdx];
            wsActionProc.startDetached();
          }
        }
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
    width: 40
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
    width: 40
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
