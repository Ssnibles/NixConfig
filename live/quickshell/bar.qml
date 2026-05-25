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
  implicitHeight: 30
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
  Process { id: volProc; command: ["pavucontrol"] }

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

  Item {
    id: barContent
    anchors.fill: parent
    anchors.leftMargin: 8
    anchors.rightMargin: 10

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
            color: modelData.focused ? Colors.accent : Colors.fgDim
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
        width: 1
        height: barContent.height
        color: Colors.border
      }

      Text {
        text: barPanel.currentTitle
        color: Colors.fgMid
        font.family: "JetBrains Mono"
        font.pixelSize: 12
        font.italic: true
        elide: Text.ElideRight
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Text {
      id: centerTime
      anchors.centerIn: parent
      text: barPanel.timeStr
      color: Colors.fg
      font.family: "JetBrains Mono"
      font.pixelSize: 13
      font.bold: true
    }

    Row {
      id: rightRow
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 6

      Row {
        spacing: 4
        visible: barPanel.mediaText !== ""
        anchors.verticalCenter: parent.verticalCenter

        Item {
          id: mediaProgressBar
          property int barCount: 16
          property int barWidth: 3
          property int barSpacing: 2
          width: barCount * barWidth + (barCount - 1) * barSpacing
          height: 16
          anchors.verticalCenter: parent.verticalCenter

          property real wavePhase: 0
          property real displayProgress: 0
          property real playTransition: 0

          Timer {
            interval: 30
            running: barPanel.mediaPlayer !== null
            repeat: true
            onTriggered: {
              mediaProgressBar.wavePhase += 0.075;
              var target = barPanel.mediaProgress;
              var diff = target - mediaProgressBar.displayProgress;
              if (Math.abs(diff) < 0.0005)
              mediaProgressBar.displayProgress = target;
              else
              mediaProgressBar.displayProgress += diff * 0.35;

              var playing = barPanel.mediaPlayer && barPanel.mediaPlayer.isPlaying;
              var tTarget = playing ? 1 : 0;
              var tDiff = tTarget - mediaProgressBar.playTransition;
              if (Math.abs(tDiff) < 0.005)
              mediaProgressBar.playTransition = tTarget;
              else
              mediaProgressBar.playTransition += tDiff * 0.1;
            }
          }

          Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: mediaProgressBar.barSpacing
            Repeater {
              model: mediaProgressBar.barCount
              delegate: Rectangle {
                required property int index
                width: mediaProgressBar.barWidth
                radius: 1.5
                color: (index + 1) / mediaProgressBar.barCount <= mediaProgressBar.displayProgress ? Colors.accent : Colors.bgSubtle
                y: Math.round((parent.height - height) / 2)
                height: {
                  if (!barPanel.mediaPlayer) return 4
                  var waveHeight = 4 + Math.sin(mediaProgressBar.wavePhase + index * 0.7) * 4 + 4
                  waveHeight = Math.max(4, Math.round(waveHeight))
                  return 4 + (waveHeight - 4) * mediaProgressBar.playTransition
                }
                Behavior on color {
                  ColorAnimation { duration: 200 }
                }
              }
            }
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

        Text {
          text: barPanel.mediaText
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

      Rectangle {
        width: 1
        height: barContent.height
        color: Colors.border
        visible: barPanel.mediaText !== ""
        anchors.verticalCenter: parent.verticalCenter
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
            color: barPanel.volMuted ? Colors.red : Colors.fg
            font.family: "JetBrains Mono"
            font.pixelSize: 12
          }

          Text {
            id: volPct
            text: Math.round(barPanel.volPct * 100) + "%"
            color: barPanel.volMuted ? Colors.red : Colors.fg
            font.family: "JetBrains Mono"
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
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.RightButton

          onEntered: volBg.color = Colors.bgRaised
          onExited: volBg.color = "transparent"

          onClicked: {
            if (mouse.button === Qt.RightButton) {
              volProc.startDetached()
            } else if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
              Pipewire.defaultAudioSink.audio.muted = !barPanel.volMuted
            }
          }

          onWheel: {
            if (!Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio) return
            var step = 0.05
            var dir = wheel.angleDelta.y > 0 ? 1 : -1
            Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1, barPanel.volPct + dir * step))
          }
        }
      }

      Rectangle {
        width: 1
        height: barContent.height
        color: Colors.border
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: barPanel.wifiSsid ? barPanel.wifiSsid + " " + barPanel.wifiIcon : barPanel.wifiIcon
        color: barPanel.wifiNet ? Colors.accent : Colors.fgDim
        font.family: "JetBrains Mono"
        font.pixelSize: 12
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }
}
