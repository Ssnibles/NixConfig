import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import QtQml
import "colors.js" as Colors

PanelWindow {
  id: barPanel
  focusable: false
  aboveWindows: true

  anchors { top: true; left: true; right: true }
  height: 30
  exclusionMode: ExclusionMode.Auto
  color: Colors.bg

  property string timeStr: ""

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: {
      var d = new Date();
      barPanel.timeStr = d.getHours().toString().padStart(2,'0') + ":" + d.getMinutes().toString().padStart(2,'0');
    }
  }

  function formatTitle(t) {
    return t
      .replace(/ — Mozilla Firefox$/, "")
      .replace(/ — Zen Browser$/, "Zen")
      .replace(/ - Neovim$/, "Neovim")
      .replace(/ - foot$/, "");
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

  // -- WiFi --
  property var wifiDev: {
    var list = Networking.devices.values;
    for (var i = 0; i < list.length; i++) {
      var d = list[i];
      if (d.type === DeviceType.Wifi) return d;
    }
    return null;
  }
  property var wifiNet: {
    if (!wifiDev) return null;
    var list = wifiDev.networks.values;
    for (var i = 0; i < list.length; i++) {
      var n = list[i];
      if (n.connected) return n;
    }
    return null;
  }
  property string wifiSsid: wifiNet ? wifiNet.name : ""
  property string wifiIcon: {
    if (!wifiNet) return "󰤯";
    var s = wifiNet.signalStrength;
    if (s < 0.2) return "󰤟";
    if (s < 0.4) return "󰤢";
    if (s < 0.6) return "󰤥";
    return "󰤨";
  }

  // -- Media --
  property var mediaPlayers: Mpris.players.values
  property var mediaPlayer: {
    var list = mediaPlayers;
    for (var i = 0; i < list.length; i++) {
      if (list[i].isPlaying) return list[i];
    }
    for (var i = 0; i < list.length; i++) {
      if (list[i].playbackState === MprisPlaybackState.Paused) return list[i];
    }
    return null;
  }
  property string mediaIcon: mediaPlayer
    ? (mediaPlayer.isPlaying ? "" : "") : ""
  property string mediaText: mediaPlayer
    ? (mediaPlayer.trackArtist
      ? mediaPlayer.trackTitle + " — " + mediaPlayer.trackArtist
      : mediaPlayer.trackTitle)
    : ""
  property real mediaProgress: mediaPlayer && mediaPlayer.length > 0
    ? mediaPlayer.position / mediaPlayer.length : 0

  Timer {
    interval: 1000
    running: barPanel.mediaPlayer && barPanel.mediaPlayer.isPlaying
    repeat: true
    onTriggered: { if (barPanel.mediaPlayer) barPanel.mediaPlayer.positionChanged(); }
  }

  IpcHandler {
    target: "bar"
    function toggle(): void { barPanel.visible = !barPanel.visible; }
    function show(): void   { barPanel.visible = true; }
    function hide(): void   { barPanel.visible = false; }
  }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 8
    anchors.rightMargin: 10
    spacing: 6

    Row {
      Layout.alignment: Qt.AlignLeft
      spacing: 3
      Repeater {
        model: Hyprland.workspaces
        delegate: Rectangle {
          required property var modelData
          width: 24; height: 24
          radius: 4
          color: modelData.focused ? Colors.accent : Colors.bgSubtle
          border.color: modelData.focused ? Colors.accent : Colors.border
          border.width: 1
          anchors.verticalCenter: parent.verticalCenter

          Text {
            anchors.centerIn: parent
            text: modelData.id
            color: modelData.focused ? Colors.bg : Colors.fgDim
            font.family: "JetBrains Mono"
            font.pixelSize: 11
            font.bold: true
          }

          MouseArea {
            anchors.fill: parent
            onClicked: modelData.activate()
          }
        }
      }
    }

    Rectangle {
      width: 1; height: 18
      color: Colors.border
      Layout.alignment: Qt.AlignLeft
    }

    Text {
      Layout.fillWidth: true
      text: barPanel.currentTitle
      color: Colors.fgMid
      font.family: "JetBrains Mono"
      font.pixelSize: 12
      elide: Text.ElideRight
      horizontalAlignment: Text.AlignLeft
    }

    Row {
      spacing: 4
      visible: barPanel.mediaText !== ""

      Item {
        width: 60; height: 14
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
          anchors.fill: parent
          radius: 3
          color: Colors.bgSubtle

          Rectangle {
            anchors.top: parent.top; anchors.left: parent.left; anchors.bottom: parent.bottom
            width: parent.width * barPanel.mediaProgress
            radius: 3
            color: Colors.accent
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (barPanel.mediaPlayer && barPanel.mediaPlayer.canSeek)
                barPanel.mediaPlayer.position = mouseX / width * barPanel.mediaPlayer.length;
            }
          }
        }
      }

      Text {
        text: barPanel.mediaIcon + " " + barPanel.mediaText
        color: Colors.fg
        font.family: "JetBrains Mono"
        font.pixelSize: 12
        elide: Text.ElideRight

        MouseArea {
          anchors.fill: parent
          onClicked: {
            if (barPanel.mediaPlayer)
              barPanel.mediaPlayer.togglePlaying();
          }
        }
      }
    }

    Row {
      spacing: 8
      Layout.alignment: Qt.AlignRight

      Text {
        text: barPanel.volMuted ? "MUT" : Math.round(barPanel.volPct * 100) + "%"
        color: barPanel.volMuted ? Colors.red : Colors.fg
        font.family: "JetBrains Mono"
        font.pixelSize: 12
        font.bold: true

        MouseArea {
          anchors.fill: parent
          onClicked: {
            if (barPanel.volInfo)
              barPanel.volInfo.muted = !barPanel.volInfo.muted;
          }
        }
      }

      Text {
        text: barPanel.wifiSsid ? barPanel.wifiSsid + " " + barPanel.wifiIcon : barPanel.wifiIcon
        color: barPanel.wifiNet ? Colors.accent : Colors.fgDim
        font.family: "JetBrains Mono"
        font.pixelSize: 12
      }
    }

    Text {
      text: barPanel.timeStr
      color: Colors.fg
      font.family: "JetBrains Mono"
      font.pixelSize: 13
      font.bold: true
    }
  }
}
