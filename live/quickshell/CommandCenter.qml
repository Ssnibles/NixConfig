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

  Colors { id: colors }

  property QtObject root: null

  property color _fg: root ? root.fg : colors.fg
  property color _fgMid: root ? root.fgMid : colors.fgMid
  property color _fgDim: root ? root.fgDim : colors.fgDim
  property color _bgSubtle: root ? root.bgSubtle : colors.bgSubtle
  property color _border: root ? root.border : colors.border
  property color _accent: root ? root.accent : colors.accent
  property color _red: root ? root.red : colors.red
  property color _green: root ? root.green : colors.green
  property color _yellow: root ? root.yellow : colors.yellow
  property string _uiFont: root ? root.uiFont : "JetBrains Mono"

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

  readonly property color gradientStart: root ? root.accent : colors.accent
  readonly property color gradientEnd: root ? root.purple : colors.purple

  readonly property int _cardRadius: root ? root.cardRadius : 8
  readonly property int _cardPadding: root ? root.cardPadding : 14
  readonly property int _cardSpacing: root ? root.cardSpacing : 6
  readonly property int _iconSize: root ? root.iconSize : 24

  // ── Base card with glassmorphism ──
  Rectangle {
    anchors.fill: parent
    radius: controlPanel._cardRadius
    color: root ? root.bgRaised : colors.bgRaised
    border.width: 1
    border.color: controlPanel._border
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
      anchors.topMargin: controlPanel._cardPadding + 6
      anchors.leftMargin: controlPanel._cardPadding
      anchors.rightMargin: controlPanel._cardPadding
      spacing: 12

      // ── Header ──
      RowLayout {
        width: parent.width
        spacing: 8

        Text {
          text: "Command Center"
          color: controlPanel._fg
          font.family: controlPanel._uiFont
          font.pixelSize: 15
          font.bold: true
          verticalAlignment: Text.AlignVCenter
          Layout.fillWidth: true
          Layout.preferredHeight: 26
        }

        Rectangle {
          id: closePanel
          Layout.preferredWidth: 26
          Layout.preferredHeight: 26
          radius: 6
          color: "transparent"
          border.width: 1
          border.color: controlPanel._border

          Behavior on scale {
            NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
          }

          Text {
            anchors.centerIn: parent
            text: "\u00d7"
            color: controlPanel._fgDim
            font.family: controlPanel._uiFont
            font.pixelSize: 14
            font.bold: true
          }

          MouseArea {
            id: closeArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
              closePanel.color = controlPanel._bgSubtle;
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
        color: controlPanel._border
        opacity: 0.6
      }

      // ── System section ──
      Text {
        text: "System"
        color: controlPanel._fg
        font.family: controlPanel._uiFont
        font.pixelSize: 11
        font.bold: true
        opacity: 0.7
        bottomPadding: -4
      }

      // Volume
      RowLayout {
        width: parent.width
        height: 36
        spacing: 10

        Rectangle {
          id: volIconBtn
          Layout.preferredWidth: 36
          Layout.preferredHeight: 36
          radius: 8
          color: controlPanel.volMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.2) : Qt.rgba(0.149, 0.149, 0.18, 0.6)
          border.width: 1
          border.color: controlPanel.volMuted ? controlPanel._red : controlPanel._border

          Text {
            anchors.centerIn: parent
            text: {
              if (controlPanel.volMuted) return "\uF09F"
              var v = controlPanel.volPct
              if (v <= 0) return "\uF09F"
              if (v < 0.33) return "\uF15F"
              if (v < 0.66) return "\uF160"
              return "\uF16E"
            }
            color: controlPanel.volMuted ? controlPanel._red : controlPanel._fg
            font.family: controlPanel._uiFont
            font.pixelSize: 14
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: volIconBtn.color = controlPanel.volMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.3) : Qt.rgba(0.251, 0.251, 0.314, 0.8)
            onExited: volIconBtn.color = controlPanel.volMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.2) : Qt.rgba(0.149, 0.149, 0.18, 0.6)
            onClicked: {
              if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                Pipewire.defaultAudioSink.audio.muted = !controlPanel.volMuted
              }
            }
          }
        }

        Text {
          text: "Volume"
          color: controlPanel._fgMid
          font.family: controlPanel._uiFont
          font.pixelSize: 11
          verticalAlignment: Text.AlignVCenter
          Layout.preferredWidth: implicitWidth
        }

        SliderControl {
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignVCenter
          value: controlPanel.volPct
          fillColor: controlPanel.volMuted ? controlPanel._red : controlPanel._accent
          onMoved: function(v) {
            if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
              Pipewire.defaultAudioSink.audio.volume = v
            }
          }
        }

        Text {
          id: volLabel
          text: Math.round(controlPanel.volPct * 100) + "%"
          color: controlPanel.volMuted ? controlPanel._red : controlPanel._fg
          font.family: controlPanel._uiFont
          font.pixelSize: 11
          font.bold: true
          verticalAlignment: Text.AlignVCenter
          Layout.preferredWidth: implicitWidth
        }
      }

      // Microphone
      RowLayout {
        width: parent.width
        height: 36
        spacing: 10
        visible: Pipewire.ready && Pipewire.defaultAudioSource !== null

        Rectangle {
          id: micIconBtn
          Layout.preferredWidth: 36
          Layout.preferredHeight: 36
          radius: 8
          color: controlPanel.micMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.2) : Qt.rgba(0.498, 0.647, 0.388, 0.15)
          border.width: 1
          border.color: controlPanel.micMuted ? controlPanel._red : controlPanel._green

          Text {
            anchors.centerIn: parent
            text: controlPanel.micMuted ? "\uF32D" : "\uF32C"
            color: controlPanel.micMuted ? controlPanel._red : controlPanel._green
            font.family: controlPanel._uiFont
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
          color: controlPanel._fgMid
          font.family: controlPanel._uiFont
          font.pixelSize: 11
          verticalAlignment: Text.AlignVCenter
          Layout.preferredWidth: implicitWidth
        }

        Item {
          Layout.fillWidth: true
          height: 36

          Rectangle {
            id: micTrack
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            width: 44
            height: 24
            radius: 12
            color: controlPanel.micMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.25) : Qt.rgba(0.498, 0.647, 0.388, 0.25)
            border.width: 1
            border.color: controlPanel.micMuted ? controlPanel._red : controlPanel._green

            Behavior on color {
              ColorAnimation { duration: 150 }
            }

            Rectangle {
              id: micThumb
              x: controlPanel.micMuted ? 3 : micTrack.width - width - 3
              y: 3
              width: micTrack.height - 6
              height: micTrack.height - 6
              radius: width / 2
              color: controlPanel.micMuted ? controlPanel._red : controlPanel._green

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
              onEntered: micTrack.color = controlPanel.micMuted ? Qt.rgba(0.847, 0.392, 0.494, 0.35) : Qt.rgba(0.498, 0.647, 0.388, 0.25)
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
            anchors.leftMargin: 16
            text: controlPanel.micMuted ? "Muted" : "Live"
            color: controlPanel.micMuted ? controlPanel._red : controlPanel._green
            font.family: controlPanel._uiFont
            font.pixelSize: 11
            font.bold: true

            Behavior on color {
              ColorAnimation { duration: 150 }
            }
          }
        }
      }

      // Brightness
      RowLayout {
        width: parent.width
        height: 36
        spacing: 10
        visible: controlPanel.brightnessAvailable

        Rectangle {
          id: brtIconBtn
          Layout.preferredWidth: 36
          Layout.preferredHeight: 36
          radius: 8
          color: Qt.rgba(0.953, 0.745, 0.486, 0.12)
          border.width: 1
          border.color: Qt.rgba(0.953, 0.745, 0.486, 0.3)

          Text {
            anchors.centerIn: parent
            text: "\uF0C3"
            color: controlPanel._yellow
            font.family: controlPanel._uiFont
            font.pixelSize: 14
          }
        }

        Text {
          text: "Brightness"
          color: controlPanel._fgMid
          font.family: controlPanel._uiFont
          font.pixelSize: 11
          verticalAlignment: Text.AlignVCenter
          Layout.preferredWidth: implicitWidth
        }

        SliderControl {
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignVCenter
          value: controlPanel.brightnessPct
          fillColor: controlPanel._yellow
          onMoved: function(v) {
            controlPanel.setBrightness(v)
          }
        }

        Text {
          id: brtLabel
          text: Math.round(controlPanel.brightnessPct * 100) + "%"
          color: controlPanel._fg
          font.family: controlPanel._uiFont
          font.pixelSize: 11
          font.bold: true
          verticalAlignment: Text.AlignVCenter
          Layout.preferredWidth: implicitWidth
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: controlPanel._border
        opacity: 0.6
      }

      // ── Media section ──
      Text {
        text: "Media"
        color: controlPanel._fg
        font.family: controlPanel._uiFont
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

          RowLayout {
            width: parent.width
            spacing: 8

            Rectangle {
              id: prevBtn
              Layout.preferredWidth: 34
              Layout.preferredHeight: 34
              radius: 8
              color: Qt.rgba(0.149, 0.149, 0.18, 0.6)
              border.width: 1
              border.color: controlPanel._border

              Behavior on scale {
                NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
              }

              Text {
                anchors.centerIn: parent
                text: "\u23ee"
                color: controlPanel._fg
                font.family: controlPanel._uiFont
                font.pixelSize: 14
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                  prevBtn.color = controlPanel._bgSubtle;
                  prevBtn.scale = 0.92;
                }
                onExited: {
                  prevBtn.color = Qt.rgba(0.149, 0.149, 0.18, 0.6);
                  prevBtn.scale = 1;
                }
                onClicked: {
                  if (controlPanel.mediaPlayer) controlPanel.mediaPlayer.previous()
                }
              }
            }

            Rectangle {
              id: playBtn
              Layout.preferredWidth: 34
              Layout.preferredHeight: 34
              radius: 8
              color: controlPanel._accent
              border.width: 1
              border.color: controlPanel._accent

              Behavior on scale {
                NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
              }

              Text {
                anchors.centerIn: parent
                text: controlPanel.mediaPlayer && controlPanel.mediaPlayer.isPlaying ? "\u23f8" : "\u25b6"
                color: root ? root.bg : colors.bg
                font.family: controlPanel._uiFont
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
              Layout.preferredWidth: 34
              Layout.preferredHeight: 34
              radius: 8
              color: Qt.rgba(0.149, 0.149, 0.18, 0.6)
              border.width: 1
              border.color: controlPanel._border

              Behavior on scale {
                NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
              }

              Text {
                anchors.centerIn: parent
                text: "\u23ed"
                color: controlPanel._fg
                font.family: controlPanel._uiFont
                font.pixelSize: 14
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                  nextBtn.color = controlPanel._bgSubtle;
                  nextBtn.scale = 0.92;
                }
                onExited: {
                  nextBtn.color = Qt.rgba(0.149, 0.149, 0.18, 0.6);
                  nextBtn.scale = 1;
                }
                onClicked: {
                  if (controlPanel.mediaPlayer) controlPanel.mediaPlayer.next()
                }
              }
            }

            Column {
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter

              Text {
                width: parent.width
                text: controlPanel.mediaText
                color: controlPanel._fg
                font.family: controlPanel._uiFont
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight
              }

              Text {
                width: parent.width
                text: controlPanel.mediaPlayer
                  ? controlPanel.mediaPlayer.name || ""
                  : ""
                color: controlPanel._fgDim
                font.family: controlPanel._uiFont
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
              color: Qt.rgba(0.145, 0.145, 0.18, 0.7)

              Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: parent.width * (controlPanel.mediaPlayer && controlPanel.mediaPlayer.length > 0
                  ? Math.min(1, Math.max(0, controlPanel.mediaPlayer.position / controlPanel.mediaPlayer.length))
                  : 0)
                radius: 2
                color: controlPanel._accent

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
          color: controlPanel._fgDim
          font.family: controlPanel._uiFont
          font.pixelSize: 11
          visible: mediaPlayer === null
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: controlPanel._border
        opacity: 0.6
      }

      // ── Quick actions ──
      Text {
        text: "Quick Actions"
        color: controlPanel._fg
        font.family: controlPanel._uiFont
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
            { icon: "\uF0BE", label: "Lock", proc: lockProc },
            { icon: "\uF0C3", label: "Logout", proc: logoutProc },
            { icon: "\uF0E4", label: "Sleep", proc: sleepProc },
            { icon: "\uF0D9", label: "Reboot", proc: rebootProc },
            { icon: "\uF0E5", label: "Power Off", proc: poweroffProc },
          ]

          delegate: Rectangle {
            required property var modelData

            width: (parent.width - parent.spacing * 4) / 5
            height: 46
            radius: 8
            color: Qt.rgba(0.149, 0.149, 0.18, 0.6)
            border.width: 1
            border.color: controlPanel._border

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
                color: controlPanel._fg
                font.family: controlPanel._uiFont
                font.pixelSize: 16
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.label
                color: controlPanel._fgDim
                font.family: controlPanel._uiFont
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
                parent.color = controlPanel._bgSubtle;
                parent.scale = 0.95;
              }
              onExited: {
                parent.color = Qt.rgba(0.149, 0.149, 0.18, 0.6);
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
        color: controlPanel._border
        opacity: 0.6
      }

      // ── Notifications controls ──
      Text {
        text: "Notifications"
        color: controlPanel._fg
        font.family: controlPanel._uiFont
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
            border.color: (root && root.doNotDisturb) ? controlPanel._accent : controlPanel._border

            Behavior on color {
              ColorAnimation { duration: 150 }
            }

            Rectangle {
              id: dndThumb
              x: (root && root.doNotDisturb) ? dndTrack.width - width - 3 : 3
              y: 3
              width: dndTrack.height - 6
              height: dndTrack.height - 6
              radius: width / 2
              color: (root && root.doNotDisturb) ? controlPanel._accent : controlPanel._fgDim

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
            color: (root && root.doNotDisturb) ? controlPanel._accent : controlPanel._fgMid
            font.family: controlPanel._uiFont
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
          border.color: controlPanel._border

          Text {
            anchors.centerIn: parent
            text: root
              ? "Clear All (" + root.notificationServer.trackedNotifications.values.length + ")"
              : "Clear All (0)"
            color: controlPanel._fgMid
            font.family: controlPanel._uiFont
            font.pixelSize: 11
            font.bold: true
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
              clearAll.color = Qt.rgba(0.847, 0.392, 0.494, 0.15);
              clearAll.border.color = controlPanel._red;
            }
            onExited: {
              clearAll.color = "transparent";
              clearAll.border.color = controlPanel._border;
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
        color: controlPanel._fgDim
        font.family: controlPanel._uiFont
        font.pixelSize: 10
        wrapMode: Text.Wrap
        opacity: 0.7
      }

      Rectangle {
        width: parent.width
        height: 1
        color: controlPanel._border
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
        leftMargin: controlPanel._cardPadding
        rightMargin: controlPanel._cardPadding
        bottomMargin: controlPanel._cardPadding
        topMargin: 8
      }
      spacing: 8
      clip: true
      model: root ? root.notificationServer.trackedNotifications : null

      delegate: Rectangle {
        required property QtObject modelData
        property QtObject notification: modelData

        width: notificationList.width
        implicitHeight: panelCardContent.implicitHeight + controlPanel._cardPadding * 2
        height: implicitHeight
        radius: controlPanel._cardRadius
        color: Qt.rgba(0.145, 0.145, 0.18, 0.6)
        border.width: 1
        border.color: notification && notification.urgency === NotificationUrgency.Critical
          ? controlPanel._red
          : controlPanel._border

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
            ? controlPanel._red
            : (notification && notification.urgency === NotificationUrgency.Low
              ? controlPanel._fgDim
              : controlPanel._accent)
          visible: notification !== null
        }

        Column {
          id: panelCardContent
          x: controlPanel._cardPadding + 6
          y: controlPanel._cardPadding
          width: parent.width - x - controlPanel._cardPadding
          spacing: root ? root.cardSpacing : 6

          Row {
            width: parent.width
            spacing: 8

            AppIcon {
              notification: modelData
              fallbackBg: root ? root.bgRaised : colors.bgRaised
            }

            Text {
              text: (notification && notification.appName && notification.appName.length > 0)
                ? notification.appName
                : "Notification"
              color: controlPanel._accent
              font.family: controlPanel._uiFont
              font.pixelSize: 11
              font.bold: true
              elide: Text.ElideRight
              verticalAlignment: Text.AlignVCenter
              height: controlPanel._iconSize
              width: Math.max(0, parent.width - dismissBtn.width - parent.spacing - controlPanel._iconSize - parent.spacing)
            }

            Rectangle {
              id: dismissBtn
              width: root ? root.closeBtnSize : 22
              height: root ? root.closeBtnSize : 22
              radius: 5
              color: "transparent"
              border.width: 1
              border.color: controlPanel._border

              Text {
                anchors.centerIn: parent
                text: "\u00d7"
                color: controlPanel._fgDim
                font.family: controlPanel._uiFont
                font.pixelSize: 13
                font.bold: true
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                  dismissBtn.color = Qt.rgba(0.847, 0.392, 0.494, 0.15);
                  dismissBtn.border.color = controlPanel._red;
                }
                onExited: {
                  dismissBtn.color = "transparent";
                  dismissBtn.border.color = controlPanel._border;
                }
                onClicked: notification.dismiss()
              }
            }
          }

          Text {
            text: notification ? (root ? root.stripMarkup(notification.summary || "") : notification.summary || "") : ""
            width: parent.width
            color: controlPanel._fg
            font.family: controlPanel._uiFont
            font.pixelSize: 13
            font.bold: true
            wrapMode: Text.Wrap
            textFormat: Text.PlainText
            visible: text.length > 0
          }

          Text {
            text: notification ? (root ? root.stripMarkup(notification.body || "") : notification.body || "") : ""
            width: parent.width
            color: controlPanel._fgMid
            font.family: controlPanel._uiFont
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
            text: "\uF09A"
            color: controlPanel._fgDim
            font.family: controlPanel._uiFont
            font.pixelSize: 24
            opacity: 0.5
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "No notifications"
            color: controlPanel._fgDim
            font.family: controlPanel._uiFont
            font.pixelSize: 12
            opacity: 0.7
          }
        }
      }
    }
  }
}
