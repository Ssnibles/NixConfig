import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import QtQml

PanelWindow {
  id: controlPanel

  property QtObject root: null

  // -- Volume control --
  property var volNodes: Pipewire.ready && Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
  PwObjectTracker { objects: controlPanel.volNodes }
  property var volInfo: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
  property real volPct: volInfo ? volInfo.volume : 0
  property bool volMuted: volInfo ? volInfo.muted : false

  // -- Microphone control --
  property var micNodes: Pipewire.ready && Pipewire.defaultAudioSource ? [Pipewire.defaultAudioSource] : []
  PwObjectTracker { objects: controlPanel.micNodes }
  property var micInfo: Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.audio : null
  property bool micMuted: micInfo ? micInfo.muted : false

  // -- Brightness control --
  property string backlightPath: ""
  property real brightnessMax: 0
  property real brightnessPct: 0.8
  property bool brightnessAvailable: true
  property bool brightnessDiscovered: false
  onVisibleChanged: {
    if (visible) {
      if (!controlPanel.brightnessDiscovered) {
        controlPanel.discoverBacklight();
      } else if (controlPanel.backlightPath) {
        controlPanel.refreshBrightness();
      }
    }
  }

  function discoverBacklight() {
    controlPanel.brightnessDiscovered = true;
    backlightDiscoverProc.exec(["sh", "-c", "ls -1 /sys/class/backlight/ 2>/dev/null || true"]);
  }

  function tryBacklightDirs(dirs) {
    var base = "/sys/class/backlight/";
    for (var i = 0; i < dirs.length; i++) {
      try {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "file://" + base + dirs[i] + "/max_brightness", false);
        xhr.send();
        if (xhr.status === 0 || xhr.status === 200) {
          var maxVal = parseInt(xhr.responseText.trim());
          if (!isNaN(maxVal) && maxVal > 0) {
            controlPanel.backlightPath = base + dirs[i];
            controlPanel.brightnessMax = maxVal;
            controlPanel.refreshBrightness();
            return;
          }
        }
      } catch(e) {}
    }
    controlPanel.brightnessAvailable = false;
  }

  function refreshBrightness() {
    if (!controlPanel.backlightPath) return;
    brightnessReadProc.exec(["brightnessctl", "get"]);
  }

  function setBrightness(pct) {
    var clamped = Math.max(0.05, Math.min(1, pct));
    controlPanel.brightnessPct = clamped;
    brightnessSetProc.command = ["brightnessctl", "set", Math.round(clamped * 100) + "%"];
    brightnessSetProc.startDetached();
  }

  Process { id: brightnessSetProc }
  Process {
    id: brightnessReadProc
    stdout: StdioCollector {
      onDataChanged: {
        var val = parseInt(this.text.trim());
        if (!isNaN(val) && controlPanel.brightnessMax > 0) {
          controlPanel.brightnessPct = Math.max(0, Math.min(1, val / controlPanel.brightnessMax));
        }
      }
    }
  }
  Process {
    id: backlightDiscoverProc
    stdout: StdioCollector {
      onDataChanged: {
        var dirs = this.text.trim().split('\n').filter(function(d) { return d.length > 0; });
        controlPanel.tryBacklightDirs(dirs);
      }
    }
  }

  Timer {
    interval: 500
    running: controlPanel.visible && controlPanel.brightnessAvailable && controlPanel.backlightPath.length > 0
    repeat: true
    onTriggered: controlPanel.refreshBrightness()
  }

  // -- Media player --
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

  Timer {
    interval: 1000
    running: controlPanel.mediaPlayer && controlPanel.mediaPlayer.isPlaying
    repeat: true
    onTriggered: { if (controlPanel.mediaPlayer) controlPanel.mediaPlayer.positionChanged(); }
  }

  // -- Quick action processes --
  Process { id: lockProc; command: ["hyprlock"] }
  Process { id: logoutProc; command: ["hyprctl", "dispatch", "exit"] }
  Process { id: sleepProc; command: ["systemctl", "suspend"] }
  Process { id: rebootProc; command: ["systemctl", "reboot"] }
  Process { id: poweroffProc; command: ["systemctl", "poweroff"] }

  visible: false
  focusable: true
  aboveWindows: true
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  anchors { top: true; right: true }
  margins { top: root ? root.topMargin : 54; right: root ? root.sideMargin : 24 }

  implicitWidth: root ? root.panelWidth : 520
  implicitHeight: 700

  function findFirst(list, predicate) {
    for (var i = 0; i < list.length; i++) {
      if (predicate(list[i])) return list[i];
    }
    return null;
  }

  component AppIcon: Item {
    property var notification: null
    property color fallbackBg: root ? root.bgSubtle : "#333333"

    width: root ? root.iconSize : 24
    height: root ? root.iconSize : 24

    Image {
      id: iconImg
      anchors.fill: parent
      source: root ? root.appIconSource(notification) : ""
      sourceSize.width: root ? root.iconSize : 24
      sourceSize.height: root ? root.iconSize : 24
      fillMode: Image.PreserveAspectFit
      visible: status === Image.Ready
    }

    Rectangle {
      anchors.fill: parent
      radius: 4
      color: fallbackBg
      border.width: 1
      border.color: root ? root.border : "#555555"
      visible: !iconImg.visible

      Text {
        anchors.centerIn: parent
        text: (notification && notification.appName && notification.appName.length > 0)
          ? notification.appName[0].toUpperCase()
          : "N"
        color: root ? root.teal : "#00bcd4"
        font.family: root ? root.uiFont : "monospace"
        font.pixelSize: 11
        font.bold: true
      }
    }
  }

  component ActionRow: Row {
    property var actions: []
    signal actionInvoked()

    spacing: root ? root.cardSpacing : 6
    visible: actions && actions.length > 0

    Repeater {
      model: actions

      Rectangle {
        required property QtObject modelData

        height: root ? root.actionBtnHeight : 26
        radius: 6
        color: "transparent"
        border.width: 1
        border.color: root ? root.border : "#555555"
        width: btnLabel.implicitWidth + 20

        Text {
          id: btnLabel
          anchors.centerIn: parent
          text: modelData.text
          color: root ? root.fgMid : "#aaaaaa"
          font.family: root ? root.uiFont : "monospace"
          font.pixelSize: 11
          textFormat: Text.PlainText
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          onEntered: parent.color = root ? root.bgSubtle : "#333333"
          onExited:  parent.color = "transparent"
          onClicked: {
            modelData.invoke();
            actionInvoked();
          }
        }
      }
    }
  }

  component ActionBtn: Rectangle {
    property string icon: ""
    property var cmdProc: null

    height: 34
    width: (parent.width - parent.spacing * 4) / 5
    radius: 6
    color: "transparent"
    border.width: 1
    border.color: root ? root.border : "#555555"

    Text {
      anchors.centerIn: parent
      text: icon
      color: root ? root.fgMid : "#aaaaaa"
      font.family: root ? root.uiFont : "monospace"
      font.pixelSize: 12
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onEntered: parent.color = root ? root.bgSubtle : "#333333"
      onExited:  parent.color = "transparent"
      onClicked: { if (cmdProc) cmdProc.startDetached() }
    }
  }

  property int cardPadding: root ? root.cardPadding : 14

  Rectangle {
    anchors.fill: parent
    radius: root ? root.cardRadius : 8
    color: root ? root.bgRaised : "#1e1e2e"
    border.width: 1
    border.color: root ? root.border : "#555555"

    Column {
      id: topSection
      anchors { top: parent.top; left: parent.left; right: parent.right }
      anchors.topMargin: controlPanel.cardPadding
      anchors.leftMargin: controlPanel.cardPadding
      anchors.rightMargin: controlPanel.cardPadding
      spacing: 10

      // ── Header ──
      Row {
        width: parent.width
        spacing: 8

        Text {
          text: "Command Center"
          color: root ? root.fg : "#ffffff"
          font.family: root ? root.uiFont : "monospace"
          font.pixelSize: 14
          font.bold: true
          verticalAlignment: Text.AlignVCenter
          height: 26
          width: parent.width - closePanel.width - parent.spacing
        }

        Rectangle {
          id: closePanel
          width: 26
          height: 26
          radius: 6
          color: "transparent"
          border.width: 1
          border.color: root ? root.border : "#555555"

          Text {
            anchors.centerIn: parent
            text: "\u00d7"
            color: root ? root.fgDim : "#777777"
            font.family: root ? root.uiFont : "monospace"
            font.pixelSize: 14
            font.bold: true
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: closePanel.color = root ? root.bgSubtle : "#333333"
            onExited:  closePanel.color = "transparent"
            onClicked: controlPanel.visible = false
          }
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: root ? root.border : "#555555"
      }

      // ── System section ──
      Text {
        text: "System"
        color: root ? root.fg : "#ffffff"
        font.family: root ? root.uiFont : "monospace"
        font.pixelSize: 12
        font.bold: true
      }

      // Volume
      Item {
        width: parent.width
        height: 32

        Row {
          anchors.verticalCenter: parent.verticalCenter
          spacing: 8

          Rectangle {
            id: volIconBtn
            width: 32
            height: 32
            radius: 6
            color: controlPanel.volMuted ? (root ? root.red : "#ef4444") : (root ? root.bgSubtle : "#2a2a3e")
            border.width: 1
            border.color: controlPanel.volMuted ? (root ? root.red : "#ef4444") : (root ? root.border : "#555555")

            Text {
              anchors.centerIn: parent
              text: {
                if (controlPanel.volMuted) return "󰝟"
                var v = controlPanel.volPct
                if (v <= 0) return "󰝟"
                if (v < 0.33) return "󰕿"
                if (v < 0.66) return "󰖀"
                return "󰕾"
              }
              color: controlPanel.volMuted ? (root ? root.bg : "#141415") : (root ? root.fg : "#ffffff")
              font.family: root ? root.uiFont : "monospace"
              font.pixelSize: 14
            }

            MouseArea {
              anchors.fill: parent
              onClicked: {
                if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                  Pipewire.defaultAudioSink.audio.muted = !controlPanel.volMuted
                }
              }
            }
          }

          Text {
            text: "Volume"
            color: root ? root.fgMid : "#aaaaaa"
            font.family: root ? root.uiFont : "monospace"
            font.pixelSize: 11
            verticalAlignment: Text.AlignVCenter
            height: 32
            width: 52
          }

          Item {
            width: parent.parent.width - volIconBtn.width - 52 - volLabel.width - 24
            height: 32
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width
              height: 12
              radius: 6
              color: root ? root.bgSubtle : "#2a2a3e"

              Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: parent.width * controlPanel.volPct
                radius: 6
                color: controlPanel.volMuted ? (root ? root.red : "#ef4444") : (root ? root.accent : "#6e94b2")

                Behavior on width {
                  NumberAnimation { duration: 100; easing.type: Easing.InOutQuad }
                }
                Behavior on color {
                  ColorAnimation { duration: 100 }
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                property bool dragging: false

                onPressed: function(mouse) {
                  dragging = true
                  if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                    Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1, mouse.x / width))
                  }
                }

                onReleased: dragging = false
                onExited: dragging = false
                onPositionChanged: function(mouse) {
                  if (dragging && Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                    Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1, mouse.x / width))
                  }
                }
              }
            }
          }

          Text {
            id: volLabel
            text: Math.round(controlPanel.volPct * 100) + "%"
            color: controlPanel.volMuted ? (root ? root.red : "#ef4444") : (root ? root.fg : "#ffffff")
            font.family: root ? root.uiFont : "monospace"
            font.pixelSize: 11
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            height: 32
          }
        }
      }

      // Microphone mute
      Item {
        width: parent.width
        height: 32
        visible: Pipewire.ready && Pipewire.defaultAudioSource !== null

        Row {
          anchors.verticalCenter: parent.verticalCenter
          spacing: 8

          Rectangle {
            id: micIconBtn
            width: 32
            height: 32
            radius: 6
            color: controlPanel.micMuted ? (root ? root.red : "#ef4444") : (root ? root.bgSubtle : "#2a2a3e")
            border.width: 1
            border.color: controlPanel.micMuted ? (root ? root.red : "#ef4444") : (root ? root.border : "#555555")

            Text {
              anchors.centerIn: parent
              text: controlPanel.micMuted ? "󰍭" : "󰍬"
              color: controlPanel.micMuted ? (root ? root.bg : "#141415") : (root ? root.fg : "#ffffff")
              font.family: root ? root.uiFont : "monospace"
              font.pixelSize: 14
            }

            MouseArea {
              anchors.fill: parent
              onClicked: {
                if (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) {
                  Pipewire.defaultAudioSource.audio.muted = !controlPanel.micMuted
                }
              }
            }
          }

          Text {
            text: "Microphone"
            color: root ? root.fgMid : "#aaaaaa"
            font.family: root ? root.uiFont : "monospace"
            font.pixelSize: 11
            verticalAlignment: Text.AlignVCenter
            height: 32
            width: 52
          }

          Rectangle {
            id: micToggleBtn
            height: 26
            width: parent.parent.width - micIconBtn.width - 52 - micIconBtn.anchors.leftMargin - 16
            radius: 6
            color: controlPanel.micMuted ? "transparent" : (root ? root.green : "#7fa563")
            border.width: 1
            border.color: controlPanel.micMuted ? (root ? root.red : "#ef4444") : (root ? root.green : "#7fa563")

            Text {
              anchors.centerIn: parent
              text: controlPanel.micMuted ? "Muted" : "Live"
              color: controlPanel.micMuted ? (root ? root.red : "#ef4444") : (root ? root.bg : "#141415")
              font.family: root ? root.uiFont : "monospace"
              font.pixelSize: 11
              font.bold: true
            }

            MouseArea {
              anchors.fill: parent
              onClicked: {
                if (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) {
                  Pipewire.defaultAudioSource.audio.muted = !controlPanel.micMuted
                }
              }
            }
          }
        }
      }

      // Brightness
      Item {
        width: parent.width
        height: 32
        visible: controlPanel.brightnessAvailable

        Row {
          anchors.verticalCenter: parent.verticalCenter
          spacing: 8

          Rectangle {
            id: brtIconBtn
            width: 32
            height: 32
            radius: 6
            color: root ? root.bgSubtle : "#2a2a3e"
            border.width: 1
            border.color: root ? root.border : "#555555"

            Text {
              anchors.centerIn: parent
              text: "󰃠"
              color: root ? root.fg : "#ffffff"
              font.family: root ? root.uiFont : "monospace"
              font.pixelSize: 14
            }
          }

          Text {
            text: "Brightness"
            color: root ? root.fgMid : "#aaaaaa"
            font.family: root ? root.uiFont : "monospace"
            font.pixelSize: 11
            verticalAlignment: Text.AlignVCenter
            height: 32
            width: 52
          }

          Item {
            width: parent.parent.width - brtIconBtn.width - 52 - brtLabel.width - 24
            height: 32
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width
              height: 12
              radius: 6
              color: root ? root.bgSubtle : "#2a2a3e"

              Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: parent.width * controlPanel.brightnessPct
                radius: 6
                color: root ? root.yellow : "#f3be7c"

                Behavior on width {
                  NumberAnimation { duration: 100; easing.type: Easing.InOutQuad }
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                property bool dragging: false

                onPressed: function(mouse) {
                  dragging = true
                  controlPanel.setBrightness(mouse.x / width)
                }

                onReleased: dragging = false
                onExited: dragging = false
                onPositionChanged: function(mouse) {
                  if (dragging) controlPanel.setBrightness(mouse.x / width)
                }
              }
            }
          }

          Text {
            id: brtLabel
            text: Math.round(controlPanel.brightnessPct * 100) + "%"
            color: root ? root.fg : "#ffffff"
            font.family: root ? root.uiFont : "monospace"
            font.pixelSize: 11
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            height: 32
          }
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: root ? root.border : "#555555"
      }

      // ── Media section ──
      Text {
        text: "Media"
        color: root ? root.fg : "#ffffff"
        font.family: root ? root.uiFont : "monospace"
        font.pixelSize: 12
        font.bold: true
      }

      Item {
        width: parent.width
        height: mediaPlayer ? 40 : 20

        Row {
          anchors.verticalCenter: parent.verticalCenter
          spacing: 6
          visible: mediaPlayer !== null

          Rectangle {
            id: prevBtn
            width: 32
            height: 32
            radius: 6
            color: root ? root.bgSubtle : "#2a2a3e"
            border.width: 1
            border.color: root ? root.border : "#555555"

            Text {
              anchors.centerIn: parent
              text: "\u23ee"
              color: root ? root.fg : "#ffffff"
              font.family: root ? root.uiFont : "monospace"
              font.pixelSize: 14
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onEntered: prevBtn.color = root ? root.bgRaised : "#1e1e2e"
              onExited:  prevBtn.color = root ? root.bgSubtle : "#2a2a3e"
              onClicked: {
                if (controlPanel.mediaPlayer) controlPanel.mediaPlayer.previous()
              }
            }
          }

          Rectangle {
            id: playBtn
            width: 32
            height: 32
            radius: 6
            color: root ? root.accent : "#6e94b2"
            border.width: 1
            border.color: root ? root.accent : "#6e94b2"

            Text {
              anchors.centerIn: parent
              text: controlPanel.mediaPlayer && controlPanel.mediaPlayer.isPlaying ? "\u23f8" : "\u25b6"
              color: root ? root.bg : "#141415"
              font.family: root ? root.uiFont : "monospace"
              font.pixelSize: 14
            }

            MouseArea {
              anchors.fill: parent
              onClicked: {
                if (controlPanel.mediaPlayer) controlPanel.mediaPlayer.togglePlaying()
              }
            }
          }

          Rectangle {
            id: nextBtn
            width: 32
            height: 32
            radius: 6
            color: root ? root.bgSubtle : "#2a2a3e"
            border.width: 1
            border.color: root ? root.border : "#555555"

            Text {
              anchors.centerIn: parent
              text: "\u23ed"
              color: root ? root.fg : "#ffffff"
              font.family: root ? root.uiFont : "monospace"
              font.pixelSize: 14
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onEntered: nextBtn.color = root ? root.bgRaised : "#1e1e2e"
              onExited:  nextBtn.color = root ? root.bgSubtle : "#2a2a3e"
              onClicked: {
                if (controlPanel.mediaPlayer) controlPanel.mediaPlayer.next()
              }
            }
          }

          Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.parent.width - prevBtn.width - playBtn.width - nextBtn.width - 24

            Text {
              width: parent.width
              text: controlPanel.mediaText
              color: root ? root.fg : "#ffffff"
              font.family: root ? root.uiFont : "monospace"
              font.pixelSize: 12
              font.bold: true
              elide: Text.ElideRight
            }

            Text {
              width: parent.width
              text: controlPanel.mediaPlayer
                ? controlPanel.mediaPlayer.name || ""
                : ""
              color: root ? root.fgDim : "#777777"
              font.family: root ? root.uiFont : "monospace"
              font.pixelSize: 10
              elide: Text.ElideRight
              visible: text.length > 0
            }
          }
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "No media playing"
          color: root ? root.fgDim : "#777777"
          font.family: root ? root.uiFont : "monospace"
          font.pixelSize: 11
          visible: mediaPlayer === null
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: root ? root.border : "#555555"
      }

      // ── Quick actions ──
      Row {
        width: parent.width
        spacing: 6

        ActionBtn {
          icon: "󰌾"
          cmdProc: lockProc
        }

        ActionBtn {
          icon: "󰍃"
          cmdProc: logoutProc
        }

        ActionBtn {
          icon: "󰤄"
          cmdProc: sleepProc
        }

        ActionBtn {
          icon: "󰜉"
          cmdProc: rebootProc
        }

        ActionBtn {
          icon: "󰐥"
          cmdProc: poweroffProc
        }
      }

      Row {
        width: parent.width
        spacing: 6

        Text {
          text: "Lock"
          color: root ? root.fgDim : "#777777"
          font.family: root ? root.uiFont : "monospace"
          font.pixelSize: 10
          horizontalAlignment: Text.AlignHCenter
          width: (parent.width - parent.spacing * 4) / 5
        }

        Text {
          text: "Logout"
          color: root ? root.fgDim : "#777777"
          font.family: root ? root.uiFont : "monospace"
          font.pixelSize: 10
          horizontalAlignment: Text.AlignHCenter
          width: (parent.width - parent.spacing * 4) / 5
        }

        Text {
          text: "Sleep"
          color: root ? root.fgDim : "#777777"
          font.family: root ? root.uiFont : "monospace"
          font.pixelSize: 10
          horizontalAlignment: Text.AlignHCenter
          width: (parent.width - parent.spacing * 4) / 5
        }

        Text {
          text: "Reboot"
          color: root ? root.fgDim : "#777777"
          font.family: root ? root.uiFont : "monospace"
          font.pixelSize: 10
          horizontalAlignment: Text.AlignHCenter
          width: (parent.width - parent.spacing * 4) / 5
        }

        Text {
          text: "Power Off"
          color: root ? root.fgDim : "#777777"
          font.family: root ? root.uiFont : "monospace"
          font.pixelSize: 10
          horizontalAlignment: Text.AlignHCenter
          width: (parent.width - parent.spacing * 4) / 5
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: root ? root.border : "#555555"
      }

      // ── Notifications controls ──
      Row {
        width: parent.width
        spacing: 8

        Rectangle {
          id: dndToggle
          height: 30
          width: (parent.width - parent.spacing) / 2
          radius: 6
          color: (root && root.doNotDisturb) ? root.accent : (root ? root.bgSubtle : "#2a2a3e")
          border.width: 1
          border.color: (root && root.doNotDisturb) ? root.accent : (root ? root.border : "#555555")

          Text {
            anchors.centerIn: parent
            text: (root && root.doNotDisturb) ? "DND: ON" : "DND: OFF"
            color: (root && root.doNotDisturb) ? root.bg : (root ? root.fg : "#ffffff")
            font.family: root ? root.uiFont : "monospace"
            font.pixelSize: 11
            font.bold: true
          }

          MouseArea {
            anchors.fill: parent
            onClicked: { if (root) root.doNotDisturb = !root.doNotDisturb; }
          }
        }

        Rectangle {
          id: clearAll
          height: 30
          width: (parent.width - parent.spacing) / 2
          radius: 6
          color: "transparent"
          border.width: 1
          border.color: root ? root.border : "#555555"

          Text {
            anchors.centerIn: parent
            text: root
              ? "Clear All (" + root.notificationServer.trackedNotifications.values.length + ")"
              : "Clear All (0)"
            color: root ? root.fgMid : "#aaaaaa"
            font.family: root ? root.uiFont : "monospace"
            font.pixelSize: 11
            font.bold: true
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: clearAll.color = root ? root.bgSubtle : "#333333"
            onExited:  clearAll.color = "transparent"
            onClicked: { if (root) root.clearNotifications(); }
          }
        }
      }

      Text {
        width: parent.width
        text: (root && root.doNotDisturb)
          ? "Do Not Disturb is enabled. Critical alerts still appear."
          : "Popup timeout adapts to notification urgency and app hints."
        color: root ? root.fgDim : "#777777"
        font.family: root ? root.uiFont : "monospace"
        font.pixelSize: 11
        wrapMode: Text.Wrap
      }

      Rectangle {
        width: parent.width
        height: 1
        color: root ? root.border : "#555555"
      }
    }

    ListView {
      id: notificationList
      anchors {
        top: topSection.bottom
        left: parent.left
        right: parent.right
        bottom: parent.bottom
        leftMargin: controlPanel.cardPadding
        rightMargin: controlPanel.cardPadding
        bottomMargin: controlPanel.cardPadding
      }
      spacing: 8
      clip: true
      model: root ? root.notificationServer.trackedNotifications : null

      delegate: Rectangle {
        required property QtObject modelData
        property QtObject notification: modelData

        width: notificationList.width
        implicitHeight: panelCardContent.implicitHeight + (root ? root.cardPadding : 14) * 2
        height: implicitHeight
        radius: root ? root.cardRadius : 8
        color: root ? root.bgSubtle : "#2a2a3e"
        border.width: 1
        border.color: notification && notification.urgency === NotificationUrgency.Critical
          ? (root ? root.red : "#ef4444")
          : (root ? root.border : "#555555")

        Column {
          id: panelCardContent
          x: root ? root.cardPadding : 14
          y: root ? root.cardPadding : 14
          width: parent.width - (root ? root.cardPadding : 14) * 2
          spacing: root ? root.cardSpacing : 6

          Row {
            width: parent.width
            spacing: 8

            AppIcon { notification: modelData; fallbackBg: root ? root.bgRaised : "#1e1e2e" }

            Text {
              text: (notification && notification.appName && notification.appName.length > 0)
                ? notification.appName
                : "Notification"
              color: root ? root.accent : "#7c3aed"
              font.family: root ? root.uiFont : "monospace"
              font.pixelSize: 11
              font.bold: true
              elide: Text.ElideRight
              verticalAlignment: Text.AlignVCenter
              height: root ? root.iconSize : 24
              width: Math.max(0, parent.width - dismissBtn.width - parent.spacing - (root ? root.iconSize : 24) - parent.spacing)
            }

            Rectangle {
              id: dismissBtn
              width: root ? root.closeBtnSize : 22
              height: root ? root.closeBtnSize : 22
              radius: 4
              color: "transparent"
              border.width: 1
              border.color: root ? root.border : "#555555"

              Text {
                anchors.centerIn: parent
                text: "\u00d7"
                color: root ? root.fgDim : "#777777"
                font.family: root ? root.uiFont : "monospace"
                font.pixelSize: 13
                font.bold: true
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: dismissBtn.color = root ? root.bgRaised : "#1e1e2e"
                onExited:  dismissBtn.color = "transparent"
                onClicked: notification.dismiss()
              }
            }
          }

          Text {
            text: notification ? (root ? root.stripMarkup(notification.summary || "") : notification.summary || "") : ""
            width: parent.width
            color: root ? root.fg : "#ffffff"
            font.family: root ? root.uiFont : "monospace"
            font.pixelSize: 13
            font.bold: true
            wrapMode: Text.Wrap
            textFormat: Text.PlainText
            visible: text.length > 0
          }

          Text {
            text: notification ? (root ? root.stripMarkup(notification.body || "") : notification.body || "") : ""
            width: parent.width
            color: root ? root.fgMid : "#aaaaaa"
            font.family: root ? root.uiFont : "monospace"
            font.pixelSize: 12
            wrapMode: Text.Wrap
            textFormat: Text.PlainText
            visible: text.length > 0
          }

          ActionRow {
            width: parent.width
            actions: notification && notification.actions ? notification.actions : []
          }
        }
      }

      Item {
        anchors.centerIn: parent
        visible: notificationList.count === 0
        width: parent.width

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "No notifications"
          color: root ? root.fgDim : "#777777"
          font.family: root ? root.uiFont : "monospace"
          font.pixelSize: 12
        }
      }
    }
  }
}
