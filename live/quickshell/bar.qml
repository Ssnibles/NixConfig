import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import QtQml

PanelWindow {
  id: barPanel
  Colors { id: colors }
  focusable: false
  aboveWindows: true

  anchors { top: true; left: true; right: true }
  implicitHeight: 30
  exclusionMode: ExclusionMode.Auto
  color: colors.bg

  property string timeStr: ""
  property string uiFont: "JetBrains Mono"

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

  Component.onCompleted: updateTime()

  function formatTitle(t) {
    return t
    .replace(/ — Mozilla Firefox$/, "")
    .replace(/ — Zen Browser$/, "Zen")
    .replace(/ - Neovim$/, "Neovim")
    .replace(/ - foot$/, "");
  }

  function findFirst(list, predicate) {
    for (var i = 0; i < list.length; i++) {
      if (predicate(list[i])) return list[i];
    }
    return null;
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
  property var wifiDev: findFirst(Networking.devices.values, function(d) {
    return d.type === DeviceType.Wifi;
  })
  property var wifiNet: findFirst(wifiDev ? wifiDev.networks.values : [], function(n) {
    return n.connected;
  })
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
  property real mediaProgress: mediaPlayer && mediaPlayer.length > 0
  ? mediaPlayer.position / mediaPlayer.length : 0

  Timer {
    interval: 1000
    running: barPanel.mediaPlayer && barPanel.mediaPlayer.isPlaying
    repeat: true
    onTriggered: { if (barPanel.mediaPlayer) barPanel.mediaPlayer.positionChanged(); }
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
            property real displayProgress: 0
            property real playTransition: barPanel.mediaPlayer && barPanel.mediaPlayer.isPlaying ? 1 : 0

            Behavior on playTransition {
              NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
            }

            NumberAnimation on wavePhase {
              from: 0
              to: Math.PI * 2
              duration: 1500
              loops: Animation.Infinite
              running: barPanel.mediaPlayer && barPanel.mediaPlayer.isPlaying
            }

            Timer {
              interval: 40
              running: barPanel.mediaPlayer !== null
              repeat: true
              onTriggered: {
                if (!barPanel.mediaPlayer || barPanel.mediaPlayer.length <= 0) {
                  mediaWaveform.displayProgress = 0;
                  return;
                }
                var target = barPanel.mediaProgress;
                var diff = target - mediaWaveform.displayProgress;
                if (Math.abs(diff) < 0.0005) {
                  mediaWaveform.displayProgress = target;
                  return;
                }
                mediaWaveform.displayProgress += diff * 0.22;
              }
            }

            Row {
              anchors.verticalCenter: parent.verticalCenter
              spacing: mediaWaveform.barSpacing
              Item {
                id: waveformContainer
                width: mediaWaveform.width
                height: mediaWaveform.height
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                  model: mediaWaveform.barCount
                  delegate: Rectangle {
                    required property int index
                    width: mediaWaveform.barWidth
                    radius: width / 2

                    // Manually calculate x position to replace the Row layout
                    x: index * (mediaWaveform.barWidth + mediaWaveform.barSpacing)

                    // Calculate a stable center line relative to the waveform container
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
                    Behavior on color {
                      ColorAnimation { duration: 200 }
                    }
                  }
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (barPanel.mediaPlayer && barPanel.mediaPlayer.canSeek) {
                  barPanel.mediaPlayer.position = mouseX / width * barPanel.mediaPlayer.length;
                }
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

          Text {
            id: mediaLabel
            text: barPanel.mediaText
            color: colors.fg
            font.family: barPanel.uiFont
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

        Text {
          id: wifiLabel
          text: barPanel.wifiSsid ? barPanel.wifiSsid + " " + barPanel.wifiIcon : barPanel.wifiIcon
          color: barPanel.wifiNet ? colors.accent : colors.fgDim
          font.family: barPanel.uiFont
          font.pixelSize: 12
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }
}
