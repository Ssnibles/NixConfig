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
      fadeInAnim.start();
      if (!controlPanel.brightnessDiscovered) {
        controlPanel.discoverBacklight();
      } else if (controlPanel.backlightPath) {
        controlPanel.refreshBrightness();
      }
    }
  }

  property real panelOpacity: 0
  property real panelSlide: -20

  SequentialAnimation {
    id: fadeInAnim
    ParallelAnimation {
      NumberAnimation { target: controlPanel; property: "panelOpacity"; to: 1; duration: 250; easing.type: Easing.OutCubic }
      NumberAnimation { target: controlPanel; property: "panelSlide"; to: 0; duration: 250; easing.type: Easing.OutCubic }
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

  // -- Gradient helpers --
  readonly property color gradientStart: root ? root.accent : "#6e94b2"
  readonly property color gradientEnd: root ? root.purple : "#bb9dbd"

  // ── Base card with glassmorphism ──
  Rectangle {
    anchors.fill: parent
    radius: root ? root.cardRadius : 8
    color: root ? root.bgRaised : "#1c1c24"
    border.width: 1
    border.color: root ? root.border : "#252530"
    opacity: controlPanel.panelOpacity
    transform: Translate { y: controlPanel.panelSlide }

    Behavior on opacity {
      NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    // Gradient accent bar at the top
    Rectangle {
      anchors { top: parent.top; left: parent.left; right: parent.right }
      height: 3
      radius: 3
      gradient: Gradient {
        GradientStop { position: 0.0; color: controlPanel.gradientStart }
        GradientStop { position: 1.0; color: controlPanel.gradientEnd }
      }
    }

    Column {
      id: topSection
      anchors { top: parent.top; left: parent.left; right: parent.right }
      anchors.topMargin: controlPanel.cardPadding + 6
      anchors.leftMargin: controlPanel.cardPadding
      anchors.rightMargin: controlPanel.cardPadding
      spacing: 12

      // ── Header ──
      Row {
        width: parent.width
        spacing: 8

        Text {
          text: "Command Center"
          color: root ? root.fg : "#cdcdcd"
          font.family: root ? root.uiFont : "monospace"
          font.pixelSize: 15
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
            border.color: root ? root.border : "#252530"

            Behavior on scale {
              NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
            }

            Text {
              anchors.centerIn: parent
              text: "\u00d7"
              color: root ? root.fgDim : "#606079"
              font.family: root ? root.uiFont : "monospace"
              font.pixelSize: 14
              font.bold: true
            }

            MouseArea {
              id: closeArea
              anchors.fill: parent
              hoverEnabled: true
              onEntered: {
                closePanel.color = root ? root.bgSubtle : "#252530";
                closePanel.scale = 0.9;
              }
              onExited: {
                closePanel.color = "transparent";
                closePanel.scale = 1;
              }
              onClicked: controlPanel.visible = false
            }
          }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: root ? root.border : "#252530"
        opacity: 0.6
      }

      // ── System section ──
      Text {
        text: "System"
        color: root ? root.fg : "#cdcdcd"
        font.family: root ? root.uiFont : "monospace"
        font.pixelSize: 11
        font.bold: true
        opacity: 0.7
        bottomPadding: -4
      }

      // Volume
      Item {
        width: parent.width
        height: 36

        Row {
          anchors.verticalCenter: parent.verticalCenter
          spacing: 10

          Rectangle {
            id: volIconBtn
            width: 36
            height: 36
            radius: 8
            color: controlPanel.volMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.2) : (root ? Qt.rgba(0.149, 0.149, 0.18, 0.6) : "#262626")
            border.width: 1
            border.color: controlPanel.volMuted ? (root ? root.red : "#d8647e") : (root ? root.border : "#252530")

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
              color: controlPanel.volMuted ? (root ? root.red : "#d8647e") : (root ? root.fg : "#cdcdcd")
              font.family: root ? root.uiFont : "monospace"
              font.pixelSize: 14
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: volIconBtn.color = controlPanel.volMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.3) : (root ? Qt.rgba(0.251, 0.251, 0.314, 0.8) : "#3a3a3a")
              onExited: volIconBtn.color = controlPanel.volMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.2) : (root ? Qt.rgba(0.149, 0.149, 0.18, 0.6) : "#262626")
              onClicked: {
                if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                  Pipewire.defaultAudioSink.audio.muted = !controlPanel.volMuted
                }
              }
            }
          }

          Text {
            text: "Volume"
            color: root ? root.fgMid : "#878787"
            font.family: root ? root.uiFont : "monospace"
            font.pixelSize: 11
            verticalAlignment: Text.AlignVCenter
            height: 36
            width: 52
          }

          // Slider
          Item {
            width: parent.parent.width - volIconBtn.width - 52 - volLabel.width - 30
            height: 36
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width
              height: 20
              radius: 10
              color: root ? Qt.rgba(0.145, 0.145, 0.18, 0.7) : "#252525"

              Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: parent.width * controlPanel.volPct
                radius: 10
                color: controlPanel.volMuted ? (root ? root.red : "#d8647e") : (root ? root.accent : "#6e94b2")

                Behavior on width {
                  NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                }
                Behavior on color {
                  ColorAnimation { duration: 150 }
                }
              }

              // Slider thumb
              Rectangle {
                id: volThumb
                x: parent.width * controlPanel.volPct - width / 2
                y: (parent.height - height) / 2
                width: volMouse.containsMouse || volMouse.dragging ? 22 : 0
                height: volMouse.containsMouse || volMouse.dragging ? 22 : 0
                radius: 11
                color: controlPanel.volMuted ? (root ? root.red : "#d8647e") : (root ? root.accent : "#6e94b2")
                opacity: volMouse.containsMouse || volMouse.dragging ? 1 : 0
                border.width: 2
                border.color: root ? root.bg : "#141415"

                Behavior on width {
                  NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                }
                Behavior on height {
                  NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                }
                Behavior on opacity {
                  NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                }
              }

              MouseArea {
                id: volMouse
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
                onExited: { if (!dragging) dragging = false }
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
            color: controlPanel.volMuted ? (root ? root.red : "#d8647e") : (root ? root.fg : "#cdcdcd")
            font.family: root ? root.uiFont : "monospace"
            font.pixelSize: 11
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            height: 36
          }
        }
      }

      // Microphone
      Item {
        width: parent.width
        height: 36
        visible: Pipewire.ready && Pipewire.defaultAudioSource !== null

        Row {
          anchors.verticalCenter: parent.verticalCenter
          spacing: 10

          Rectangle {
            id: micIconBtn
            width: 36
            height: 36
            radius: 8
            color: controlPanel.micMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.2) : Qt.rgba(0.498, 0.647, 0.388, 0.15)
            border.width: 1
            border.color: controlPanel.micMuted ? (root ? root.red : "#d8647e") : (root ? root.green : "#7fa563")

            Text {
              anchors.centerIn: parent
              text: controlPanel.micMuted ? "󰍭" : "󰍬"
              color: controlPanel.micMuted ? (root ? root.red : "#d8647e") : (root ? root.green : "#7fa563")
              font.family: root ? root.uiFont : "monospace"
              font.pixelSize: 14
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: micIconBtn.color = controlPanel.micMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.35) : Qt.rgba(0.498, 0.647, 0.388, 0.25)
              onExited: micIconBtn.color = controlPanel.micMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.2) : Qt.rgba(0.498, 0.647, 0.388, 0.15)
              onClicked: {
                if (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) {
                  Pipewire.defaultAudioSource.audio.muted = !controlPanel.micMuted
                }
              }
            }
          }

          Text {
            text: "Microphone"
            color: root ? root.fgMid : "#878787"
            font.family: root ? root.uiFont : "monospace"
            font.pixelSize: 11
            verticalAlignment: Text.AlignVCenter
            height: 36
            width: 52
          }

          // Toggle switch
          Item {
            width: parent.parent.width - micIconBtn.width - 52 - 30
            height: 36
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
              id: micTrack
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              width: 44
              height: 24
              radius: 12
              color: controlPanel.micMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.25) : Qt.rgba(0.498, 0.647, 0.388, 0.25)
              border.width: 1
              border.color: controlPanel.micMuted ? (root ? root.red : "#d8647e") : (root ? root.green : "#7fa563")

              Behavior on color {
                ColorAnimation { duration: 150 }
              }

              Rectangle {
                id: micThumb
                x: controlPanel.micMuted ? 3 : micTrack.width - height + 3
                y: 3
                width: micTrack.height - 6
                height: micTrack.height - 6
                radius: width / 2
                color: controlPanel.micMuted ? (root ? root.red : "#d8647e") : (root ? root.green : "#7fa563")

                Behavior on x {
                  NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                }
                Behavior on color {
                  ColorAnimation { duration: 150 }
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: micTrack.color = controlPanel.micMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.35) : Qt.rgba(0.498, 0.647, 0.388, 0.35)
                onExited: micTrack.color = controlPanel.micMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.25) : Qt.rgba(0.498, 0.647, 0.388, 0.25)
                onClicked: {
                  if (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) {
                    Pipewire.defaultAudioSource.audio.muted = !controlPanel.micMuted
                  }
                }
              }
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: micTrack.right
              anchors.leftMargin: 10
              text: controlPanel.micMuted ? "Muted" : "Live"
              color: controlPanel.micMuted ? (root ? root.red : "#d8647e") : (root ? root.green : "#7fa563")
              font.family: root ? root.uiFont : "monospace"
              font.pixelSize: 11
              font.bold: true

              Behavior on color {
                ColorAnimation { duration: 150 }
              }
            }
          }
        }
      }

      // Brightness
      Item {
        width: parent.width
        height: 36
        visible: controlPanel.brightnessAvailable

        Row {
          anchors.verticalCenter: parent.verticalCenter
          spacing: 10

          Rectangle {
            id: brtIconBtn
            width: 36
            height: 36
            radius: 8
            color: Qt.rgba(0.953, 0.745, 0.486, 0.12)
            border.width: 1
            border.color: root ? Qt.rgba(0.953, 0.745, 0.486, 0.3) : "#5a5a3e"

            Text {
              anchors.centerIn: parent
              text: "󰃠"
              color: root ? root.yellow : "#f3be7c"
              font.family: root ? root.uiFont : "monospace"
              font.pixelSize: 14
            }
          }

          Text {
            text: "Brightness"
            color: root ? root.fgMid : "#878787"
            font.family: root ? root.uiFont : "monospace"
            font.pixelSize: 11
            verticalAlignment: Text.AlignVCenter
            height: 36
            width: 52
          }

          Item {
            width: parent.parent.width - brtIconBtn.width - 52 - brtLabel.width - 30
            height: 36
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width
              height: 20
              radius: 10
              color: root ? Qt.rgba(0.145, 0.145, 0.18, 0.7) : "#252525"

              Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: parent.width * controlPanel.brightnessPct
                radius: 10
                color: root ? root.yellow : "#f3be7c"

                Behavior on width {
                  NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                }
              }

              Rectangle {
                id: brtThumb
                x: parent.width * controlPanel.brightnessPct - width / 2
                y: (parent.height - height) / 2
                width: brtMouse.containsMouse || brtMouse.dragging ? 22 : 0
                height: brtMouse.containsMouse || brtMouse.dragging ? 22 : 0
                radius: 11
                color: root ? root.yellow : "#f3be7c"
                opacity: brtMouse.containsMouse || brtMouse.dragging ? 1 : 0
                border.width: 2
                border.color: root ? root.bg : "#141415"

                Behavior on width {
                  NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                }
                Behavior on height {
                  NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                }
                Behavior on opacity {
                  NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                }
              }

              MouseArea {
                id: brtMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                property bool dragging: false

                onPressed: function(mouse) {
                  dragging = true
                  controlPanel.setBrightness(mouse.x / width)
                }
                onReleased: dragging = false
                onExited: { if (!dragging) dragging = false }
                onPositionChanged: function(mouse) {
                  if (dragging) controlPanel.setBrightness(mouse.x / width)
                }
              }
            }
          }

          Text {
            id: brtLabel
            text: Math.round(controlPanel.brightnessPct * 100) + "%"
            color: root ? root.fg : "#cdcdcd"
            font.family: root ? root.uiFont : "monospace"
            font.pixelSize: 11
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            height: 36
          }
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: root ? root.border : "#252530"
        opacity: 0.6
      }

      // ── Media section ──
      Text {
        text: "Media"
        color: root ? root.fg : "#cdcdcd"
        font.family: root ? root.uiFont : "monospace"
        font.pixelSize: 11
        font.bold: true
        opacity: 0.7
        bottomPadding: -4
      }

      Item {
        width: parent.width
        height: mediaPlayer ? 70 : 20

        Column {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width
          spacing: 8
          visible: mediaPlayer !== null

          Row {
            width: parent.width
            spacing: 8

            Rectangle {
              id: prevBtn
              width: 34
              height: 34
              radius: 8
              color: root ? Qt.rgba(0.149, 0.149, 0.18, 0.6) : "#262626"
              border.width: 1
              border.color: root ? root.border : "#252530"

              Behavior on scale {
                NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
              }

              Text {
                anchors.centerIn: parent
                text: "\u23ee"
                color: root ? root.fg : "#cdcdcd"
                font.family: root ? root.uiFont : "monospace"
                font.pixelSize: 14
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                  prevBtn.color = root ? root.bgSubtle : "#3a3a3a";
                  prevBtn.scale = 0.92;
                }
                onExited: {
                  prevBtn.color = root ? Qt.rgba(0.149, 0.149, 0.18, 0.6) : "#262626";
                  prevBtn.scale = 1;
                }
                onClicked: {
                  if (controlPanel.mediaPlayer) controlPanel.mediaPlayer.previous()
                }
              }
            }

            Rectangle {
              id: playBtn
              width: 34
              height: 34
              radius: 8
              color: root ? root.accent : "#6e94b2"
              border.width: 1
              border.color: root ? root.accent : "#6e94b2"

              Behavior on scale {
                NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
              }

              Text {
                anchors.centerIn: parent
                text: controlPanel.mediaPlayer && controlPanel.mediaPlayer.isPlaying ? "\u23f8" : "\u25b6"
                color: root ? root.bg : "#141415"
                font.family: root ? root.uiFont : "monospace"
                font.pixelSize: 14
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: playBtn.scale = 0.92
                onExited: playBtn.scale = 1
                onClicked: {
                  if (controlPanel.mediaPlayer) controlPanel.mediaPlayer.togglePlaying()
                }
              }
            }

            Rectangle {
              id: nextBtn
              width: 34
              height: 34
              radius: 8
              color: root ? Qt.rgba(0.149, 0.149, 0.18, 0.6) : "#262626"
              border.width: 1
              border.color: root ? root.border : "#252530"

              Behavior on scale {
                NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
              }

              Text {
                anchors.centerIn: parent
                text: "\u23ed"
                color: root ? root.fg : "#cdcdcd"
                font.family: root ? root.uiFont : "monospace"
                font.pixelSize: 14
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                  nextBtn.color = root ? root.bgSubtle : "#3a3a3a";
                  nextBtn.scale = 0.92;
                }
                onExited: {
                  nextBtn.color = root ? Qt.rgba(0.149, 0.149, 0.18, 0.6) : "#262626";
                  nextBtn.scale = 1;
                }
                onClicked: {
                  if (controlPanel.mediaPlayer) controlPanel.mediaPlayer.next()
                }
              }
            }

            Column {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width - prevBtn.width - playBtn.width - nextBtn.width - 24

              Text {
                width: parent.width
                text: controlPanel.mediaText
                color: root ? root.fg : "#cdcdcd"
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
                color: root ? root.fgDim : "#606079"
                font.family: root ? root.uiFont : "monospace"
                font.pixelSize: 10
                elide: Text.ElideRight
                visible: text.length > 0
              }
            }
          }

          // Media progress bar
          Item {
            width: parent.width
            height: 4
            visible: controlPanel.mediaPlayer && controlPanel.mediaPlayer.length > 0

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width
              height: 4
              radius: 2
              color: root ? Qt.rgba(0.145, 0.145, 0.18, 0.7) : "#252525"

              Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: parent.width * (controlPanel.mediaPlayer && controlPanel.mediaPlayer.length > 0
                  ? Math.min(1, Math.max(0, controlPanel.mediaPlayer.position / controlPanel.mediaPlayer.length))
                  : 0)
                radius: 2
                color: root ? root.accent : "#6e94b2"

                Behavior on width {
                  NumberAnimation { duration: 300; easing.type: Easing.Linear }
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: function(mouse) {
                  if (controlPanel.mediaPlayer && controlPanel.mediaPlayer.canSeek) {
                    controlPanel.mediaPlayer.position = mouse.x / width * controlPanel.mediaPlayer.length;
                  }
                }
              }
            }
          }
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "No media playing"
          color: root ? root.fgDim : "#606079"
          font.family: root ? root.uiFont : "monospace"
          font.pixelSize: 11
          visible: mediaPlayer === null
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: root ? root.border : "#252530"
        opacity: 0.6
      }

      // ── Quick actions ──
      Text {
        text: "Quick Actions"
        color: root ? root.fg : "#cdcdcd"
        font.family: root ? root.uiFont : "monospace"
        font.pixelSize: 11
        font.bold: true
        opacity: 0.7
        bottomPadding: -4
      }

      Row {
        width: parent.width
        spacing: 6

        Repeater {
          model: [
            { icon: "󰌾", label: "Lock", proc: lockProc },
            { icon: "󰍃", label: "Logout", proc: logoutProc },
            { icon: "󰤄", label: "Sleep", proc: sleepProc },
            { icon: "󰜉", label: "Reboot", proc: rebootProc },
            { icon: "󰐥", label: "Power Off", proc: poweroffProc },
          ]

          delegate: Rectangle {
            required property var modelData

            width: (parent.width - parent.spacing * 4) / 5
            height: 46
            radius: 8
            color: root ? Qt.rgba(0.149, 0.149, 0.18, 0.6) : "#262626"
            border.width: 1
            border.color: root ? root.border : "#252530"

            Behavior on color {
              ColorAnimation { duration: 100 }
            }

            Behavior on scale {
              NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
            }

            Column {
              anchors.centerIn: parent
              spacing: 2

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.icon
                color: root ? root.fg : "#cdcdcd"
                font.family: root ? root.uiFont : "monospace"
                font.pixelSize: 16
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.label
                color: root ? root.fgDim : "#606079"
                font.family: root ? root.uiFont : "monospace"
                font.pixelSize: 9
                visible: ma.containsMouse
              }
            }

            MouseArea {
              id: ma
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor

              onEntered: {
                parent.color = root ? root.bgSubtle : "#3a3a3a";
                parent.scale = 0.95;
              }
              onExited: {
                parent.color = root ? Qt.rgba(0.149, 0.149, 0.18, 0.6) : "#262626";
                parent.scale = 1;
              }
              onPressed: parent.scale = 0.9
              onReleased: parent.scale = 0.95
              onClicked: { if (modelData.proc) modelData.proc.startDetached() }
            }
          }
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: root ? root.border : "#252530"
        opacity: 0.6
      }

      // ── Notifications controls ──
      Text {
        text: "Notifications"
        color: root ? root.fg : "#cdcdcd"
        font.family: root ? root.uiFont : "monospace"
        font.pixelSize: 11
        font.bold: true
        opacity: 0.7
        bottomPadding: -4
      }

      Row {
        width: parent.width
        spacing: 8

        // DND Toggle
        Item {
          height: 32
          width: (parent.width - parent.spacing) / 2

          Rectangle {
            id: dndTrack
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            height: 24
            radius: 12
            color: (root && root.doNotDisturb) ? Qt.rgba(0.431, 0.580, 0.698, 0.25) : Qt.rgba(0.145, 0.145, 0.18, 0.7)
            border.width: 1
            border.color: (root && root.doNotDisturb) ? (root ? root.accent : "#6e94b2") : (root ? root.border : "#252530")

            Behavior on color {
              ColorAnimation { duration: 150 }
            }

            Rectangle {
              id: dndThumb
              x: (root && root.doNotDisturb) ? dndTrack.width - height + 3 : 3
              y: 3
              width: dndTrack.height - 6
              height: dndTrack.height - 6
              radius: width / 2
              color: (root && root.doNotDisturb) ? (root ? root.accent : "#6e94b2") : (root ? root.fgDim : "#606079")

              Behavior on x {
                NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: { if (root) root.doNotDisturb = !root.doNotDisturb; }
            }
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: dndTrack.right
            anchors.leftMargin: 10
            text: (root && root.doNotDisturb) ? "Do Not Disturb" : "Allow Notifications"
            color: (root && root.doNotDisturb) ? (root ? root.accent : "#6e94b2") : (root ? root.fgMid : "#878787")
            font.family: root ? root.uiFont : "monospace"
            font.pixelSize: 11
            font.bold: true
            elide: Text.ElideRight
            width: parent.width - dndTrack.width - anchors.leftMargin - 2

            Behavior on color {
              ColorAnimation { duration: 150 }
            }
          }
        }

        // Clear All
        Rectangle {
          id: clearAll
          height: 32
          width: (parent.width - parent.spacing) / 2
          radius: 8
          color: "transparent"
          border.width: 1
          border.color: root ? root.border : "#252530"

          Text {
            anchors.centerIn: parent
            text: root
              ? "Clear All (" + root.notificationServer.trackedNotifications.values.length + ")"
              : "Clear All (0)"
            color: root ? root.fgMid : "#878787"
            font.family: root ? root.uiFont : "monospace"
            font.pixelSize: 11
            font.bold: true
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
              clearAll.color = root ? Qt.rgba(0.847, 0.392, 0.494, 0.15) : "#3a2020";
              clearAll.border.color = root ? root.red : "#d8647e";
            }
            onExited: {
              clearAll.color = "transparent";
              clearAll.border.color = root ? root.border : "#252530";
            }
            onClicked: { if (root) root.clearNotifications(); }
          }
        }
      }

      Text {
        width: parent.width
        text: (root && root.doNotDisturb)
          ? "Do Not Disturb is enabled. Critical alerts still appear."
          : "Popup timeout adapts to notification urgency and app hints."
        color: root ? root.fgDim : "#606079"
        font.family: root ? root.uiFont : "monospace"
        font.pixelSize: 10
        wrapMode: Text.Wrap
        opacity: 0.7
      }

      Rectangle {
        width: parent.width
        height: 1
        color: root ? root.border : "#252530"
        opacity: 0.6
      }
    }

    // ── Notification List ──
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
        topMargin: 8
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
        color: root ? Qt.rgba(0.145, 0.145, 0.18, 0.6) : "#262626"
        border.width: 1
        border.color: notification && notification.urgency === NotificationUrgency.Critical
          ? (root ? root.red : "#d8647e")
          : (root ? root.border : "#252530")

        opacity: 0
        Behavior on opacity {
          NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Component.onCompleted: opacity = 1

        // Urgency accent bar
        Rectangle {
          anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
          width: 3
          radius: 2
          color: notification && notification.urgency === NotificationUrgency.Critical
            ? (root ? root.red : "#d8647e")
            : (notification && notification.urgency === NotificationUrgency.Low
              ? (root ? root.fgDim : "#606079")
              : (root ? root.accent : "#6e94b2"))
          visible: notification !== null
        }

        Column {
          id: panelCardContent
          x: root ? root.cardPadding + 6 : 20
          y: root ? root.cardPadding : 14
          width: parent.width - x - (root ? root.cardPadding : 14)
          spacing: root ? root.cardSpacing : 6

          Row {
            width: parent.width
            spacing: 8

            AppIcon { notification: modelData; fallbackBg: root ? root.bgRaised : "#1c1c24" }

            Text {
              text: (notification && notification.appName && notification.appName.length > 0)
                ? notification.appName
                : "Notification"
              color: root ? root.accent : "#6e94b2"
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
              radius: 5
              color: "transparent"
              border.width: 1
              border.color: root ? root.border : "#252530"

              Text {
                anchors.centerIn: parent
                text: "\u00d7"
                color: root ? root.fgDim : "#606079"
                font.family: root ? root.uiFont : "monospace"
                font.pixelSize: 13
                font.bold: true
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                  dismissBtn.color = root ? Qt.rgba(0.847, 0.392, 0.494, 0.15) : "#3a2020";
                  dismissBtn.border.color = root ? root.red : "#d8647e";
                }
                onExited: {
                  dismissBtn.color = "transparent";
                  dismissBtn.border.color = root ? root.border : "#252530";
                }
                onClicked: notification.dismiss()
              }
            }
          }

          Text {
            text: notification ? (root ? root.stripMarkup(notification.summary || "") : notification.summary || "") : ""
            width: parent.width
            color: root ? root.fg : "#cdcdcd"
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
            color: root ? root.fgMid : "#878787"
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

        Column {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 8

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "󰂚"
            color: root ? root.fgDim : "#606079"
            font.family: root ? root.uiFont : "monospace"
            font.pixelSize: 24
            opacity: 0.5
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "No notifications"
            color: root ? root.fgDim : "#606079"
            font.family: root ? root.uiFont : "monospace"
            font.pixelSize: 12
            opacity: 0.7
          }
        }
      }
    }
  }

  property int cardPadding: root ? root.cardPadding : 14

  // ── Shared components ──
  component AppIcon: Item {
    property var notification: null
    property color fallbackBg: root ? root.bgSubtle : "#252530"

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
      radius: 5
      color: fallbackBg
      border.width: 1
      border.color: root ? root.border : "#252530"
      visible: !iconImg.visible

      Text {
        anchors.centerIn: parent
        text: (notification && notification.appName && notification.appName.length > 0)
          ? notification.appName[0].toUpperCase()
          : "N"
        color: root ? root.teal : "#b4d4cf"
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
        border.color: root ? root.border : "#252530"
        width: btnLabel.implicitWidth + 20

        Behavior on scale {
          NumberAnimation { duration: 60; easing.type: Easing.OutQuad }
        }

        Text {
          id: btnLabel
          anchors.centerIn: parent
          text: modelData.text
          color: root ? root.fgMid : "#878787"
          font.family: root ? root.uiFont : "monospace"
          font.pixelSize: 11
          textFormat: Text.PlainText
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: {
            parent.color = root ? root.bgSubtle : "#252530";
            parent.scale = 0.96;
          }
          onExited: {
            parent.color = "transparent";
            parent.scale = 1;
          }
          onPressed: parent.scale = 0.93
          onReleased: parent.scale = 0.96
          onClicked: {
            modelData.invoke();
            actionInvoked();
          }
        }
      }
    }
  }
}
