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

  property QtObject _p: palette

  QtObject {
    id: palette
    property color fg: controlPanel.root ? controlPanel.root.fg : Colors.fg
    property color fgMid: controlPanel.root ? controlPanel.root.fgMid : Colors.fgMid
    property color fgDim: controlPanel.root ? controlPanel.root.fgDim : Colors.fgDim
    property color bgSubtle: controlPanel.root ? controlPanel.root.bgSubtle : Colors.bgSubtle
    property color border: controlPanel.root ? controlPanel.root.border : Colors.border
    property color accent: controlPanel.root ? controlPanel.root.accent : Colors.accent
    property color red: controlPanel.root ? controlPanel.root.red : Colors.red
    property color green: controlPanel.root ? controlPanel.root.green : Colors.green
    property color yellow: controlPanel.root ? controlPanel.root.yellow : Colors.yellow
    property string uiFont: controlPanel.root ? controlPanel.root.uiFont : "JetBrains Mono"
  }

  // -- Volume --
  property var volNodes: Pipewire.ready && Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
  PwObjectTracker { objects: controlPanel.volNodes }
  property var volInfo: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
  property real volPct: volInfo ? volInfo.volume : 0
  property bool volMuted: volInfo ? volInfo.muted : false

  // -- Microphone --
  property var micNodes: Pipewire.ready && Pipewire.defaultAudioSource ? [Pipewire.defaultAudioSource] : []
  PwObjectTracker { objects: controlPanel.micNodes }
  property var micInfo: Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.audio : null
  property bool micMuted: micInfo ? micInfo.muted : false

  // -- Brightness --
  property string backlightPath: ""
  property real brightnessMax: 0
  property real brightnessPct: 0.8
  property bool brightnessAvailable: true
  property bool brightnessDiscovered: false

  property real panelOpacity: 0
  property real panelSlide: -20

  property bool _isOpen: panelOpacity > 0

  onVisibleChanged: {
    if (visible) {
      fadeInAnim.start();
      if (!controlPanel.brightnessDiscovered) controlPanel.discoverBacklight();
      else if (controlPanel.backlightPath) controlPanel.refreshBrightness();
    }
  }

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
    controlPanel.brightnessPct = Math.max(0.05, Math.min(1, pct));
    brightnessSetProc.command = ["brightnessctl", "set", Math.round(controlPanel.brightnessPct * 100) + "%"];
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
    running: controlPanel._isOpen && controlPanel.brightnessAvailable && controlPanel.backlightPath.length > 0
    repeat: true
    onTriggered: controlPanel.refreshBrightness()
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

  Timer {
    interval: 1000
    running: controlPanel._isOpen && controlPanel.mediaPlayer && controlPanel.mediaPlayer.isPlaying
    repeat: true
    onTriggered: {}
  }

  // -- Quick action processes --
  Process { id: lockProc; command: ["sh", "-c", "if [ -n \"$NIRI_SOCKET\" ]; then swaylock; else hyprlock; fi"] }
  Process { id: logoutProc; command: ["sh", "-c", "if [ -n \"$NIRI_SOCKET\" ]; then niri msg action quit; else hyprctl dispatch exit; fi"] }
  Process { id: sleepProc; command: ["systemctl", "suspend"] }
  Process { id: rebootProc; command: ["systemctl", "reboot"] }
  Process { id: poweroffProc; command: ["systemctl", "poweroff"] }

  visible: false
  focusable: true
  aboveWindows: true
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  anchors { top: true; bottom: true; right: true }
  margins { top: root ? root.topMargin : 54; bottom: root ? root.topMargin : 54; right: root ? root.sideMargin : 24 }

  implicitWidth: 620
  implicitHeight: 700

  function findFirst(list, predicate) {
    for (var i = 0; i < list.length; i++) {
      if (predicate(list[i])) return list[i];
    }
    return null;
  }

  Rectangle {
    anchors.fill: parent
    radius: 16
    color: root ? root.bgRaised : Colors.bgRaised
    border.width: 1
    border.color: _p.border
    opacity: controlPanel.panelOpacity
    transform: Translate { y: controlPanel.panelSlide }

    Rectangle {
      anchors.fill: parent
      anchors.topMargin: 4
      radius: 16
      color: Qt.rgba(0, 0, 0, 0.2)
      z: -1
    }

    Rectangle {
      anchors { top: parent.top; left: parent.left; right: parent.right }
      height: 4
      radius: 2
      gradient: Gradient {
        GradientStop { position: 0.0; color: root ? root.accent : Colors.accent }
        GradientStop { position: 1.0; color: root ? root.purple : Colors.purple }
      }
    }

    Column {
      id: topSection
      anchors { top: parent.top; left: parent.left; right: parent.right }
      anchors.topMargin: 26
      anchors.leftMargin: 20
      anchors.rightMargin: 20
      spacing: 12

      // Header
      RowLayout {
        width: parent.width
        spacing: 14

        Text {
          text: "Command Center"
          color: _p.fg
          font.family: _p.uiFont
          font.pixelSize: 18
          font.bold: true
          font.letterSpacing: 0.5
          verticalAlignment: Text.AlignVCenter
          Layout.fillWidth: true
          Layout.preferredHeight: 32
        }

        Rectangle {
          id: closePanel
          Layout.preferredWidth: 32
          Layout.preferredHeight: 32
          radius: 8
          color: "transparent"
          border.width: 1
          border.color: _p.border
          Behavior on scale { NumberAnimation { duration: 80 } }

          Text {
            anchors.centerIn: parent
            text: "\uDB80\uDD56"
            color: _p.fgMid
            font.family: _p.uiFont
            font.pixelSize: 16
            font.bold: true
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: { closePanel.color = _p.bgSubtle; closePanel.scale = 0.92 }
            onExited: { closePanel.color = "transparent"; closePanel.scale = 1 }
            onClicked: controlPanel.visible = false
          }
        }
      }

      Rectangle { width: parent.width; height: 1; color: _p.border; opacity: 0.6 }

      // ── SYSTEM ──
      Text {
        text: "SYSTEM"
        color: _p.fgMid
        font.family: _p.uiFont
        font.pixelSize: 11
        font.bold: true
        font.letterSpacing: 1.2
      }

      // Volume row
      RowLayout {
        width: parent.width
        height: 48
        spacing: 12

        Rectangle {
          id: volIconBtn
          Layout.preferredWidth: 42; Layout.preferredHeight: 42
          radius: 10
          color: controlPanel.volMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.15) : Qt.rgba(0.149, 0.149, 0.18, 0.5)
          border.width: 1
          border.color: controlPanel.volMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.3) : _p.border

          Text {
            anchors.centerIn: parent
            text: {
              if (controlPanel.volMuted) return "\uDB81\uDD81"
              var v = controlPanel.volPct
              if (v <= 0) return "\uDB81\uDD81"
              if (v < 0.33) return "\uDB81\uDD7F"
              if (v < 0.66) return "\uDB81\uDD80"
              return "\uDB81\uDD7E"
            }
            color: controlPanel.volMuted ? _p.red : _p.fg
            font.family: _p.uiFont
            font.pixelSize: 16
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: volIconBtn.color = controlPanel.volMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.3) : Qt.rgba(0.251, 0.251, 0.314, 0.75)
            onExited: volIconBtn.color = controlPanel.volMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.15) : Qt.rgba(0.149, 0.149, 0.18, 0.5)
            onClicked: {
              if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                Pipewire.defaultAudioSink.audio.muted = !controlPanel.volMuted
              }
            }
          }
        }

        Text {
          text: "Volume"
          color: _p.fg
          font.family: _p.uiFont
          font.pixelSize: 12
          font.bold: true
          verticalAlignment: Text.AlignVCenter
          Layout.preferredWidth: implicitWidth
        }

        SliderControl {
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignVCenter
          value: controlPanel.volPct
          fillColor: controlPanel.volMuted ? _p.red : _p.accent
          onMoved: function(v) {
            if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
              Pipewire.defaultAudioSink.audio.volume = v
            }
          }
        }

        Text {
          text: Math.round(controlPanel.volPct * 100) + "%"
          color: controlPanel.volMuted ? _p.red : _p.fg
          font.family: _p.uiFont
          font.pixelSize: 12
          font.bold: true
          opacity: 0.85
          verticalAlignment: Text.AlignVCenter
          Layout.preferredWidth: implicitWidth
        }
      }

      // Microphone row
      RowLayout {
        width: parent.width
        height: 48
        spacing: 12
        visible: Pipewire.ready && Pipewire.defaultAudioSource !== null

        Rectangle {
          id: micIconBtn
          Layout.preferredWidth: 42; Layout.preferredHeight: 42
          radius: 10
          color: controlPanel.micMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.12) : Qt.rgba(0.498, 0.647, 0.388, 0.12)
          border.width: 1
          border.color: controlPanel.micMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.3) : Qt.rgba(0.498, 0.647, 0.388, 0.3)

          Text {
            anchors.centerIn: parent
            text: controlPanel.micMuted ? "\uDB80\uDD6D" : "\uDB80\uDD6C"
            color: controlPanel.micMuted ? _p.red : _p.green
            font.family: _p.uiFont
            font.pixelSize: 16
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: micIconBtn.color = controlPanel.micMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.3) : Qt.rgba(0.498, 0.647, 0.388, 0.3)
            onExited: micIconBtn.color = controlPanel.micMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.12) : Qt.rgba(0.498, 0.647, 0.388, 0.12)
            onClicked: {
              if (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) {
                Pipewire.defaultAudioSource.audio.muted = !controlPanel.micMuted
              }
            }
          }
        }

        Text {
          text: "Microphone"
          color: _p.fg
          font.family: _p.uiFont
          font.pixelSize: 12
          font.bold: true
          verticalAlignment: Text.AlignVCenter
          Layout.preferredWidth: implicitWidth
        }

        Item {
          Layout.fillWidth: true
          height: 42

          Rectangle {
            id: micTrack
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            width: 52; height: 28
            radius: 14
            color: controlPanel.micMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.2) : Qt.rgba(0.498, 0.647, 0.388, 0.2)
            border.width: 1
            border.color: controlPanel.micMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.3) : Qt.rgba(0.498, 0.647, 0.388, 0.3)
            Behavior on color { ColorAnimation { duration: 200 } }

            Rectangle {
              id: micThumb
              x: controlPanel.micMuted ? 3 : micTrack.width - width - 3
              y: 3
              width: micTrack.height - 6; height: micTrack.height - 6
              radius: width / 2
              color: controlPanel.micMuted ? _p.red : _p.green
              Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
              Behavior on color { ColorAnimation { duration: 200 } }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: micTrack.color = controlPanel.micMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.35) : Qt.rgba(0.498, 0.647, 0.388, 0.35)
              onExited: micTrack.color = controlPanel.micMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.2) : Qt.rgba(0.498, 0.647, 0.388, 0.2)
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
            anchors.leftMargin: 14
            text: controlPanel.micMuted ? "Muted" : "Live"
            color: controlPanel.micMuted ? _p.red : _p.green
            font.family: _p.uiFont
            font.pixelSize: 12
            font.bold: true
            Behavior on color { ColorAnimation { duration: 200 } }
          }
        }
      }

      // Brightness row
      RowLayout {
        width: parent.width
        height: 48
        spacing: 12
        visible: controlPanel.brightnessAvailable

        Rectangle {
          id: brtIconBtn
          Layout.preferredWidth: 42; Layout.preferredHeight: 42
          radius: 10
          color: Qt.rgba(0.953, 0.745, 0.486, 0.1)
          border.width: 1
          border.color: Qt.rgba(0.953, 0.745, 0.486, 0.25)

          Text {
            anchors.centerIn: parent
            text: "\uDB81\uDD99"
            color: _p.yellow
            font.family: _p.uiFont
            font.pixelSize: 16
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: brtIconBtn.color = Qt.rgba(0.953, 0.745, 0.486, 0.25)
            onExited: brtIconBtn.color = Qt.rgba(0.953, 0.745, 0.486, 0.1)
          }
        }

        Text {
          text: "Brightness"
          color: _p.fg
          font.family: _p.uiFont
          font.pixelSize: 12
          font.bold: true
          verticalAlignment: Text.AlignVCenter
          Layout.preferredWidth: implicitWidth
        }

        SliderControl {
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignVCenter
          value: controlPanel.brightnessPct
          fillColor: _p.yellow
          onMoved: function(v) { controlPanel.setBrightness(v) }
        }

        Text {
          text: Math.round(controlPanel.brightnessPct * 100) + "%"
          color: _p.fg
          font.family: _p.uiFont
          font.pixelSize: 12
          font.bold: true
          opacity: 0.85
          verticalAlignment: Text.AlignVCenter
          Layout.preferredWidth: implicitWidth
        }
      }

      Rectangle { width: parent.width; height: 1; color: _p.border; opacity: 0.6 }

      // ── MEDIA ──
      Text {
        text: "MEDIA"
        color: _p.fgMid
        font.family: _p.uiFont
        font.pixelSize: 11
        font.bold: true
        font.letterSpacing: 1.2
      }

      Item {
        width: parent.width
        height: mediaPlayer ? 92 : 24

        Column {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width
          spacing: 10
          visible: mediaPlayer !== null

          RowLayout {
            width: parent.width
            spacing: 10

            Rectangle {
              id: prevBtn
              Layout.preferredWidth: 42; Layout.preferredHeight: 42
              radius: 10
              color: Qt.rgba(0.149, 0.149, 0.18, 0.6)
              border.width: 1
              border.color: _p.border
              Behavior on scale { NumberAnimation { duration: 80 } }

              Text {
                anchors.centerIn: parent
                text: "\uDB81\uDCAE"
                color: _p.fg
                font.family: _p.uiFont
                font.pixelSize: 18
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: { prevBtn.color = _p.bgSubtle; prevBtn.scale = 0.92 }
                onExited: { prevBtn.color = Qt.rgba(0.149, 0.149, 0.18, 0.6); prevBtn.scale = 1 }
                onClicked: { if (controlPanel.mediaPlayer) controlPanel.mediaPlayer.previous() }
              }
            }

            Rectangle {
              id: playBtn
              Layout.preferredWidth: 42; Layout.preferredHeight: 42
              radius: 10
              color: _p.accent
              border.width: 1
              border.color: _p.accent
              Behavior on scale { NumberAnimation { duration: 80 } }

              Text {
                anchors.centerIn: parent
                text: controlPanel.mediaPlayer && controlPanel.mediaPlayer.isPlaying ? "\uDB80\uDFE4" : "\uDB81\uDC0A"
                color: Colors.bg
                font.family: _p.uiFont
                font.pixelSize: 18
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: playBtn.scale = 0.92
                onExited: playBtn.scale = 1
                onClicked: { if (controlPanel.mediaPlayer) controlPanel.mediaPlayer.togglePlaying() }
              }
            }

            Rectangle {
              id: nextBtn
              Layout.preferredWidth: 42; Layout.preferredHeight: 42
              radius: 10
              color: Qt.rgba(0.149, 0.149, 0.18, 0.6)
              border.width: 1
              border.color: _p.border
              Behavior on scale { NumberAnimation { duration: 80 } }

              Text {
                anchors.centerIn: parent
                text: "\uDB81\uDCAD"
                color: _p.fg
                font.family: _p.uiFont
                font.pixelSize: 18
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: { nextBtn.color = _p.bgSubtle; nextBtn.scale = 0.92 }
                onExited: { nextBtn.color = Qt.rgba(0.149, 0.149, 0.18, 0.6); nextBtn.scale = 1 }
                onClicked: { if (controlPanel.mediaPlayer) controlPanel.mediaPlayer.next() }
              }
            }

            Column {
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
              spacing: 2

              Text {
                width: Math.min(implicitWidth, parent.width)
                text: controlPanel.mediaText
                color: _p.fg
                font.family: _p.uiFont
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
              }

              Text {
                width: Math.min(implicitWidth, parent.width)
                text: controlPanel.mediaPlayer ? (controlPanel.mediaPlayer.name || "") : ""
                color: _p.fgDim
                font.family: _p.uiFont
                font.pixelSize: 11
                elide: Text.ElideRight
                visible: text.length > 0
              }
            }
          }

          Item {
            width: parent.width
            height: 6
            visible: controlPanel.mediaPlayer && controlPanel.mediaPlayer.length > 0

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width
              height: 6
              radius: 3
              color: Qt.rgba(0.145, 0.145, 0.18, 0.7)

              Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: parent.width * (controlPanel.mediaPlayer && controlPanel.mediaPlayer.length > 0
                  ? Math.min(1, Math.max(0, controlPanel.mediaPlayer.position / controlPanel.mediaPlayer.length))
                  : 0)
                radius: 3
                color: _p.accent
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.Linear } }
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
          color: _p.fgDim
          font.family: _p.uiFont
          font.pixelSize: 12
          opacity: 0.7
          visible: mediaPlayer === null
        }
      }

      Rectangle { width: parent.width; height: 1; color: _p.border; opacity: 0.6 }

      // ── QUICK ACTIONS ──
      Text {
        text: "QUICK ACTIONS"
        color: _p.fgMid
        font.family: _p.uiFont
        font.pixelSize: 11
        font.bold: true
        font.letterSpacing: 1.2
      }

      Row {
        width: parent.width
        spacing: 8

        Repeater {
          model: [
            { icon: "\uDB80\uDD3E", label: "Lock", proc: lockProc },
            { icon: "\uDB80\uDD43", label: "Logout", proc: logoutProc },
            { icon: "\uDB81\uDD94", label: "Sleep", proc: sleepProc },
            { icon: "\uDB81\uDF09", label: "Reboot", proc: rebootProc },
            { icon: "\uDB81\uDC25", label: "Power Off", proc: poweroffProc },
          ]

          delegate: Rectangle {
            required property var modelData
            width: (parent.width - parent.spacing * 4) / 5
            height: 60
            radius: 12
            color: Qt.rgba(0.149, 0.149, 0.18, 0.5)
            Behavior on scale { NumberAnimation { duration: 80 } }

            Column {
              anchors.centerIn: parent
              spacing: 4
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.icon
                color: _p.fg
                font.family: _p.uiFont
                font.pixelSize: 20
              }
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.label
                color: _p.fgDim
                font.family: _p.uiFont
                font.pixelSize: 10
                font.bold: true
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: { parent.color = Qt.rgba(0.251, 0.251, 0.314, 0.7); parent.scale = 0.95 }
              onExited: { parent.color = Qt.rgba(0.149, 0.149, 0.18, 0.5); parent.scale = 1 }
              onPressed: parent.scale = 0.92
              onReleased: parent.scale = 0.95
              onClicked: { if (modelData.proc) modelData.proc.startDetached() }
            }
          }
        }
      }

      Rectangle { width: parent.width; height: 1; color: _p.border; opacity: 0.6 }

      // ── NOTIFICATIONS ──
      Text {
        text: "NOTIFICATIONS"
        color: _p.fgMid
        font.family: _p.uiFont
        font.pixelSize: 11
        font.bold: true
        font.letterSpacing: 1.2
      }

      Row {
        width: parent.width
        spacing: 10

        Item {
          height: 36
          width: (parent.width - parent.spacing) / 2

          Rectangle {
            id: dndTrack
            anchors.verticalCenter: parent.verticalCenter
            width: 52; height: 28
            radius: 14
            color: (root && root.doNotDisturb) ? Qt.rgba(0.431, 0.580, 0.698, 0.2) : Qt.rgba(0.145, 0.145, 0.18, 0.6)
            border.width: 1
            border.color: (root && root.doNotDisturb) ? _p.accent : _p.border
            Behavior on color { ColorAnimation { duration: 200 } }

            Rectangle {
              id: dndThumb
              x: (root && root.doNotDisturb) ? dndTrack.width - width - 4 : 4
              y: 4
              width: dndTrack.height - 8; height: dndTrack.height - 8
              radius: width / 2
              color: (root && root.doNotDisturb) ? _p.accent : _p.fgMid
              Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
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
            anchors.leftMargin: 12
            text: (root && root.doNotDisturb) ? "Do Not Disturb" : "Allow All"
            color: (root && root.doNotDisturb) ? _p.accent : _p.fgMid
            font.family: _p.uiFont
            font.pixelSize: 12
            font.bold: true
            elide: Text.ElideRight
            width: parent.width - dndTrack.width - anchors.leftMargin - 2
            Behavior on color { ColorAnimation { duration: 200 } }
          }
        }

        Rectangle {
          id: clearAll
          height: 36
          width: (parent.width - parent.spacing) / 2
          radius: 10
          color: Qt.rgba(0.145, 0.145, 0.18, 0.5)

          Text {
            anchors.centerIn: parent
            text: root
              ? "Clear All (" + root.notificationServer.trackedNotifications.values.length + ")"
              : "Clear All"
            color: _p.fg
            font.family: _p.uiFont
            font.pixelSize: 12
            font.bold: true
            opacity: 0.85
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: clearAll.color = Qt.rgba(0.847, 0.392, 0.494, 0.25)
            onExited: clearAll.color = Qt.rgba(0.145, 0.145, 0.18, 0.5)
            onPressed: clearAll.scale = 0.95
            onReleased: clearAll.scale = 1
            onClicked: { if (root) root.clearNotifications(); }
          }
        }
      }

      Text {
        width: parent.width
        text: (root && root.doNotDisturb) ? "Critical alerts will still appear" : "Notifications adapt to urgency and app behavior"
        color: _p.fgDim
        font.family: _p.uiFont
        font.pixelSize: 11
        wrapMode: Text.Wrap
        opacity: 0.6
      }

      Rectangle { width: parent.width; height: 1; color: _p.border; opacity: 0.6 }
    }

    // ── Notification History ──
    ListView {
      id: notificationList
      anchors {
        top: topSection.bottom
        left: parent.left
        right: parent.right
        bottom: parent.bottom
        leftMargin: 20
        rightMargin: 20
        bottomMargin: 20
        topMargin: 8
      }
      spacing: 10
      clip: true
      model: root ? root.notificationServer.trackedNotifications : null

      delegate: Rectangle {
        required property QtObject modelData
        property QtObject notification: modelData

        width: notificationList.width
        implicitHeight: panelCardContent.implicitHeight + 40
        height: implicitHeight
        radius: 12
        color: Qt.rgba(0.145, 0.145, 0.18, 0.5)

        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Component.onCompleted: opacity = 1

        Rectangle {
          anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
          width: 4; radius: 2
          color: notification && notification.urgency === NotificationUrgency.Critical
            ? _p.red : (notification && notification.urgency === NotificationUrgency.Low
              ? _p.fgDim : _p.accent)
          visible: notification !== null
        }

        Column {
          id: panelCardContent
          x: 28; y: 20
          width: parent.width - x - 20
          spacing: root ? root.cardSpacing : 8

          Row {
            width: parent.width
            spacing: 10

            AppIcon {
              notification: modelData
              fallbackBg: root ? root.bgRaised : Colors.bgRaised
            }

            Text {
              text: (notification && notification.appName && notification.appName.length > 0)
                ? notification.appName : "Notification"
              color: _p.accent
              font.family: _p.uiFont
              font.pixelSize: 12
              font.bold: true
              elide: Text.ElideRight
              verticalAlignment: Text.AlignVCenter
              height: 28
              width: Math.max(0, parent.width - dismissBtn.width - parent.spacing - 28 - parent.spacing)
            }

            Rectangle {
              id: dismissBtn
              width: 26; height: 26
              radius: 6
              color: "transparent"
              border.width: 1
              border.color: _p.border

              Text {
                anchors.centerIn: parent
                text: "\uDB80\uDD56"
                color: _p.fgDim
                font.family: _p.uiFont
                font.pixelSize: 13
                font.bold: true
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: { dismissBtn.color = Qt.rgba(0.847, 0.392, 0.494, 0.15); dismissBtn.border.color = _p.red }
                onExited: { dismissBtn.color = "transparent"; dismissBtn.border.color = _p.border }
                onClicked: notification.dismiss()
              }
            }
          }

          Text {
            text: notification ? (root ? root.stripMarkup(notification.summary || "") : notification.summary || "") : ""
            width: parent.width
            color: _p.fg
            font.family: _p.uiFont
            font.pixelSize: 13
            font.bold: true
            wrapMode: Text.Wrap
            textFormat: Text.PlainText
            visible: text.length > 0
          }

          Text {
            text: notification ? (root ? root.stripMarkup(notification.body || "") : notification.body || "") : ""
            width: parent.width
            color: _p.fgMid
            font.family: _p.uiFont
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
        height: 120

        Column {
          anchors.centerIn: parent
          spacing: 10

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "\uDB80\uDC9C"
            color: _p.fgDim
            font.family: _p.uiFont
            font.pixelSize: 32
            opacity: 0.35
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "No notifications"
            color: _p.fgDim
            font.family: _p.uiFont
            font.pixelSize: 13
            font.bold: true
            opacity: 0.6
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "You're all caught up"
            color: _p.fgDim
            font.family: _p.uiFont
            font.pixelSize: 11
            opacity: 0.4
          }
        }
      }
    }
  }
}
