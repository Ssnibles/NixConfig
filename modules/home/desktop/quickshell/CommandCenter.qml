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
    property color fg:        (controlPanel.root || Colors).fg
    property color fgMid:     (controlPanel.root || Colors).fgMid
    property color fgDim:     (controlPanel.root || Colors).fgDim
    property color bgSubtle:  (controlPanel.root || Colors).bgSubtle
    property color border:    (controlPanel.root || Colors).border
    property color accent:    (controlPanel.root || Colors).accent
    property color red:       (controlPanel.root || Colors).red
    property color green:     (controlPanel.root || Colors).green
    property color yellow:    (controlPanel.root || Colors).yellow
    property color purple:    (controlPanel.root || Colors).purple
    property color orange:    (controlPanel.root || Colors).orange
    property color teal:      (controlPanel.root || Colors).teal
    property string uiFont:   (controlPanel.root || { uiFont: "JetBrains Mono" }).uiFont
  }

  // ── Volume ──
  property var volNodes: Pipewire.ready && Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
  PwObjectTracker { objects: controlPanel.volNodes }
  property var volInfo: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
  property real volPct: volInfo ? volInfo.volume : 0
  property bool volMuted: volInfo ? volInfo.muted : false

  // ── Microphone ──
  // Pipewire.defaultAudioSource is broken on some systems (resolves to sink)
  // so we manually find the first non-monitor audio source node
  property var micNode: controlPanel.findMicNode()
  property var micNodes: controlPanel.micNode ? [controlPanel.micNode] : []
  PwObjectTracker { objects: controlPanel.micNodes }
  property var micInfo: controlPanel.micNode ? controlPanel.micNode.audio : null
  property bool micMuted: micInfo ? micInfo.muted : false

  // ── Brightness ──
  property string backlightPath: ""
  property real brightnessMax: 0
  property real brightnessPct: 0.8
  property bool brightnessAvailable: true
  property bool brightnessDiscovered: false
  property string brightnessBackend: ""  // "sysfs", "brightnessctl", "ddcutil", or ""
  property bool brightnessDragging: false

  // ── Media ──
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
  property string mediaSubtext: {
    if (!mediaPlayer) return "";
    var parts = [];
    if (mediaPlayer.trackAlbum) parts.push(mediaPlayer.trackAlbum);
    parts.push(mediaPlayer.name || "");
    return parts.join(" \u2014 ");
  }
  property int _mediaTick: 0
  property real mediaProgress: {
    var _ = controlPanel._mediaTick;
    return mediaPlayer && mediaPlayer.length > 0
      ? Math.min(1, Math.max(0, mediaPlayer.position / mediaPlayer.length)) : 0;
  }

  Timer {
    interval: 500
    running: controlPanel.visible && controlPanel.mediaPlayer && controlPanel.mediaPlayer.isPlaying
    repeat: true
    onTriggered: controlPanel._mediaTick++
  }

  // ── Animation state ──
  property real panelOpacity: 0
  property real panelSlide: 60
  property bool _isOpen: panelOpacity > 0
  property bool _closeRequested: false
  property bool _surfacePrerendered: false

  Component.onCompleted: {
    _surfacePrerendered = true;
    discoverBacklight();
  }

  onVisibleChanged: {
    if (visible) {
      controlPanel._closeRequested = false;
      fadeOutAnim.stop();
      panelOpacity = 0;
      panelSlide = 60;
      fadeInAnim.start();
      // Only refresh fast backends on show; ddcutil is updated by timer
      if (controlPanel.brightnessBackend === "sysfs" || controlPanel.brightnessBackend === "brightnessctl") {
        controlPanel.refreshBrightness();
      }
    } else {
      panelOpacity = 0;
      panelSlide = 60;
      controlPanel._closeRequested = false;
    }
  }

  SequentialAnimation {
    id: fadeInAnim
    PauseAnimation { duration: 1 }
    ParallelAnimation {
      NumberAnimation { target: controlPanel; property: "panelOpacity"; to: 1; duration: 300; easing.type: Easing.OutCubic }
      NumberAnimation { target: controlPanel; property: "panelSlide";   to: 0; duration: 300; easing.type: Easing.OutCubic }
    }
  }

  SequentialAnimation {
    id: fadeOutAnim
    ParallelAnimation {
      NumberAnimation { target: controlPanel; property: "panelOpacity"; to: 0; duration: 200; easing.type: Easing.OutCubic }
      NumberAnimation { target: controlPanel; property: "panelSlide";   to: 60; duration: 200; easing.type: Easing.OutCubic }
    }
    onFinished: {
      if (controlPanel._closeRequested) {
        controlPanel.visible = false;
        controlPanel._closeRequested = false;
      }
    }
  }

  function requestHide() {
    if (controlPanel.visible && !controlPanel._closeRequested) {
      controlPanel._closeRequested = true;
      fadeOutAnim.start();
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
            controlPanel.brightnessBackend = "sysfs";
            controlPanel.brightnessAvailable = true;
            controlPanel.refreshBrightness();
            return;
          }
        }
      } catch(e) {}
    }
    // No sysfs backlight found — try brightnessctl fallback
    brightnessFallbackProc.exec(["sh", "-c", "echo $(brightnessctl get 2>/dev/null) $(brightnessctl max 2>/dev/null)"]);
  }

  function refreshBrightness() {
    if (controlPanel.brightnessBackend === "sysfs" && controlPanel.backlightPath) {
      brightnessReadProc.exec(["brightnessctl", "get"]);
    } else if (controlPanel.brightnessBackend === "brightnessctl") {
      brightnessFallbackProc.exec(["sh", "-c", "echo $(brightnessctl get 2>/dev/null) $(brightnessctl max 2>/dev/null)"]);
    } else if (controlPanel.brightnessBackend === "ddcutil") {
      ddcutilReadProc.exec(["ddcutil", "--sleep-multiplier", "0.1", "getvcp", "10", "--brief"]);
    }
  }

  function setBrightness(pct) {
    controlPanel.brightnessPct = Math.max(0.05, Math.min(1, pct));
    if (controlPanel.brightnessBackend === "sysfs" || controlPanel.brightnessBackend === "brightnessctl") {
      brightnessSetProc.command = ["brightnessctl", "set", Math.round(controlPanel.brightnessPct * 100) + "%"];
      brightnessSetProc.startDetached();
    } else if (controlPanel.brightnessBackend === "ddcutil") {
      var val = Math.round(controlPanel.brightnessPct * controlPanel.brightnessMax);
      ddcutilSetProc.command = [
        "ddcutil", "--sleep-multiplier", "0.1", "setvcp", "--noverify", "10", "" + val
      ];
      ddcutilSetProc.startDetached();
    }
  }

  function findFirst(list, predicate) {
    for (var i = 0; i < list.length; i++) {
      if (predicate(list[i])) return list[i];
    }
    return null;
  }

  function findMicNode() {
    if (!Pipewire.ready) return null;
    var nodes = Pipewire.nodes;
    var arr = nodes && nodes.values ? nodes.values : nodes;
    for (var i = 0; i < arr.length; i++) {
      var n = arr[i];
      if (n && n.audio && !n.isSink) {
        var name = n.name || "";
        if (name.indexOf("monitor") !== -1) continue;
        return n;
      }
    }
    return null;
  }

  function formatTime(seconds) {
    var s = Math.round(seconds);
    if (s < 0) s = 0;
    var m = Math.floor(s / 60);
    s = s % 60;
    return m + ":" + (s < 10 ? "0" : "") + s;
  }

  function coverArtUrl() {
    if (!controlPanel.mediaPlayer) return "";
    var url = controlPanel.mediaPlayer.trackArtUrl;
    if (url) {
      url = String(url).trim();
      if (url.charAt(0) === '"' && url.charAt(url.length - 1) === '"') url = url.slice(1, -1);
      return url;
    }
    var meta = controlPanel.mediaPlayer.metadata;
    if (meta) {
      var raw = meta["mpris:artUrl"];
      if (raw) {
        url = String(raw).trim();
        if (url.charAt(0) === '"' && url.charAt(url.length - 1) === '"') url = url.slice(1, -1);
        return url;
      }
    }
    return "";
  }

  Process { id: brightnessSetProc }
  Process { id: ddcutilSetProc }
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
    id: brightnessFallbackProc
    stdout: StdioCollector {
      onDataChanged: {
        var parts = this.text.trim().split(/\s+/).filter(function(s) { return s.length > 0; });
        if (parts.length >= 2) {
          var cur = parseInt(parts[0]);
          var max = parseInt(parts[1]);
          if (!isNaN(cur) && !isNaN(max) && max > 1) {
            controlPanel.brightnessMax = max;
            controlPanel.brightnessPct = Math.max(0, Math.min(1, cur / max));
            controlPanel.brightnessAvailable = true;
            controlPanel.brightnessBackend = "brightnessctl";
            return;
          }
        }
        // brightnessctl fallback failed — try ddcutil for desktop monitors
        ddcutilDiscoverProc.exec(["ddcutil", "--sleep-multiplier", "0.1", "getvcp", "10", "--brief"]);
      }
    }
  }
  Process {
    id: ddcutilDiscoverProc
    stdout: StdioCollector {
      onDataChanged: {
        var parts = this.text.trim().split(/\s+/).filter(function(s) { return s.length > 0; });
        // Format: VCP 10 C <current> <max>
        if (parts.length >= 5 && parts[0] === "VCP" && parts[1] === "10") {
          var cur = parseInt(parts[3]);
          var max = parseInt(parts[4]);
          if (!isNaN(cur) && !isNaN(max) && max > 0) {
            controlPanel.brightnessMax = max;
            controlPanel.brightnessPct = Math.max(0, Math.min(1, cur / max));
            controlPanel.brightnessAvailable = true;
            controlPanel.brightnessBackend = "ddcutil";
            return;
          }
        }
        controlPanel.brightnessAvailable = false;
        controlPanel.brightnessBackend = "";
      }
    }
  }
  Process {
    id: ddcutilReadProc
    stdout: StdioCollector {
      onDataChanged: {
        var parts = this.text.trim().split(/\s+/).filter(function(s) { return s.length > 0; });
        if (parts.length >= 5 && parts[0] === "VCP" && parts[1] === "10") {
          var cur = parseInt(parts[3]);
          var max = parseInt(parts[4]);
          if (!isNaN(cur) && !isNaN(max) && max > 0) {
            controlPanel.brightnessMax = max;
            if (!controlPanel.brightnessDragging) {
              controlPanel.brightnessPct = Math.max(0, Math.min(1, cur / max));
            }
          }
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
    running: controlPanel._isOpen && controlPanel.brightnessAvailable && controlPanel.brightnessBackend.length > 0 && !controlPanel.brightnessDragging
    repeat: true
    onTriggered: controlPanel.refreshBrightness()
  }

  // ── Volume debounce (batch rapid slider updates) ──
  Timer {
    id: volSetTimer
    interval: 80
    repeat: false
    property real target: 0
    onTriggered: {
      var pct = Math.round(target * 100);
      volSetProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", pct + "%"];
      volSetProc.startDetached();
    }
  }
  Process { id: volSetProc }

  // ── Brightness debounce (batch rapid slider updates) ──
  Timer {
    id: brightnessSetTimer
    interval: 80
    repeat: false
    property real target: 0
    onTriggered: controlPanel.setBrightness(target)
  }

  // ── Quick action processes ──
  Process { id: lockProc;    command: ["hyprlock"] }
  Process { id: logoutProc;  command: ["hyprctl", "dispatch", "exit"] }
  Process { id: sleepProc;   command: ["systemctl", "suspend"] }
  Process { id: rebootProc;  command: ["systemctl", "reboot"] }
  Process { id: poweroffProc; command: ["systemctl", "poweroff"] }

  // ── Caffeinate (idle inhibit) ──
  property bool caffeinated: false

  Process {
    id: caffeinateStartProc
    command: ["sh", "-c", "systemd-inhibit --what=idle:sleep --why='Quickshell caffeinate' --who=quickshell sleep infinity & echo $! > /tmp/quickshell-caffeine.pid"]
  }
  Process {
    id: caffeinateStopProc
    command: ["sh", "-c", "kill $(cat /tmp/quickshell-caffeine.pid 2>/dev/null) 2>/dev/null; rm -f /tmp/quickshell-caffeine.pid"]
  }
  Timer {
    interval: 3000
    running: true
    repeat: true
    onTriggered: {
      caffeinateCheckProc.exec(["sh", "-c", "kill -0 $(cat /tmp/quickshell-caffeine.pid 2>/dev/null) 2>/dev/null && echo active || echo inactive"]);
    }
  }
  Process {
    id: caffeinateCheckProc
    stdout: StdioCollector {
      onDataChanged: {
        controlPanel.caffeinated = (this.text.trim() === "active");
      }
    }
  }

  visible: false
  focusable: false
  aboveWindows: true
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  anchors { top: true; bottom: true; right: true }
  margins { top: root ? root.topMargin : 54; bottom: root ? root.topMargin : 54; right: root ? root.sideMargin : 24 }

  implicitWidth: 520
  implicitHeight: 700

  Rectangle {
    anchors.fill: parent
    radius: 28
    color: Colors.bg
    border.width: 1
    border.color: _p.border
    opacity: controlPanel.panelOpacity
    transform: Translate { x: controlPanel.panelSlide }

    Flickable {
      id: flickable
      anchors { top: parent.top; left: parent.left; right: parent.right; bottom: parent.bottom }
      anchors.margins: 20
      anchors.topMargin: 18
      contentHeight: contentColumn.height + 20
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: contentColumn
        width: parent.width
        spacing: 20

        // ════════════════ HEADER ════════════════
        RowLayout {
          width: parent.width
          spacing: 12

          Column {
            Layout.fillWidth: true
            spacing: 2

            Text {
              id: headerTime
              text: Qt.formatDateTime(new Date(), "hh:mm")
              color: _p.fg
              font.family: _p.uiFont
              font.pixelSize: 32
              font.bold: true

              Timer {
                interval: 1000
                running: controlPanel.visible
                repeat: true
                onTriggered: headerTime.text = Qt.formatDateTime(new Date(), "hh:mm")
              }
            }

            Text {
              text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
              color: _p.fgDim
              font.family: _p.uiFont
              font.pixelSize: 13
            }
          }

        }

        // ════════════════ MEDIA CARD ════════════════
        Rectangle {
          width: parent.width
          radius: 20
          color: Colors.bgRaised
          border.width: 1
          border.color: _p.border
          visible: mediaPlayer !== null
          implicitHeight: mediaCardCol.implicitHeight + 40

          Column {
            id: mediaCardCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
            spacing: 16

            RowLayout {
              width: parent.width
              spacing: 16

              Rectangle {
                id: mediaArtContainer
                Layout.preferredWidth: 88
                Layout.preferredHeight: 88
                radius: 16
                color: Colors.bgSubtle
                clip: true

                Image {
                  id: mediaArtImage
                  anchors.fill: parent
                  source: controlPanel.coverArtUrl()
                  fillMode: Image.PreserveAspectCrop
                  smooth: true
                  visible: status === Image.Ready || status === Image.Loading
                }

                Text {
                  anchors.centerIn: parent
                  text: "\uDB80\uDDE2"
                  color: _p.fgDim
                  font.family: _p.uiFont
                  font.pixelSize: 28
                  visible: mediaArtImage.status !== Image.Ready && mediaArtImage.status !== Image.Loading
                }
              }

              Column {
                Layout.fillWidth: true
                spacing: 3

                Item {
                  width: parent.width
                  height: mediaTitleText.implicitHeight
                  clip: true

                  Text {
                    id: mediaTitleText
                    text: controlPanel.mediaText
                    width: implicitWidth
                    color: _p.fg
                    font.family: _p.uiFont
                    font.pixelSize: 14
                    font.bold: true
                    property bool overflow: implicitWidth > parent.width + 2
                    onTextChanged: { x = 0; if (overflow) mediaScroll1.restart() }
                  }

                  SequentialAnimation {
                    id: mediaScroll1
                    running: mediaTitleText.overflow
                    loops: Animation.Infinite
                    PauseAnimation { duration: 2000 }
                    PropertyAnimation {
                      target: mediaTitleText; property: "x"
                      to: mediaTitleText.parent.width - mediaTitleText.implicitWidth
                      duration: Math.max((mediaTitleText.implicitWidth - mediaTitleText.parent.width) * 30, 1000)
                      easing.type: Easing.Linear
                    }
                    PauseAnimation { duration: 2000 }
                    PropertyAnimation {
                      target: mediaTitleText; property: "x"
                      to: 0
                      duration: Math.max((mediaTitleText.implicitWidth - mediaTitleText.parent.width) * 30, 1000)
                      easing.type: Easing.Linear
                    }
                  }
                }

                Text {
                  text: controlPanel.mediaSubtext
                  width: Math.min(implicitWidth, parent.width)
                  color: _p.fgDim
                  font.family: _p.uiFont
                  font.pixelSize: 11
                  elide: Text.ElideRight
                  visible: text.length > 0
                }
              }
            }

            // Seek bar
            RowLayout {
              width: parent.width
              spacing: 8
              visible: controlPanel.mediaPlayer && controlPanel.mediaPlayer.length > 0

              Text {
                text: {
                  var _ = controlPanel._mediaTick;
                  return controlPanel.formatTime(controlPanel.mediaPlayer ? controlPanel.mediaPlayer.position : 0)
                }
                color: _p.fgMid
                font.family: _p.uiFont
                font.pixelSize: 10
                Layout.preferredWidth: implicitWidth
              }

              Item {
                Layout.fillWidth: true
                height: 28

                Rectangle {
                  anchors.verticalCenter: parent.verticalCenter
                  width: parent.width
                  height: 8
                  radius: 4
                  color: Colors.bgSubtle

                  Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    width: parent.width * controlPanel.mediaProgress
                    radius: 4
                    color: _p.accent
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: function(mouse) {
                    if (controlPanel.mediaPlayer && controlPanel.mediaPlayer.canSeek) {
                      controlPanel.mediaPlayer.position = mouse.x / width * controlPanel.mediaPlayer.length;
                    }
                  }
                }
              }

              Text {
                text: controlPanel.formatTime(controlPanel.mediaPlayer ? controlPanel.mediaPlayer.length : 0)
                color: _p.fgMid
                font.family: _p.uiFont
                font.pixelSize: 10
                Layout.preferredWidth: implicitWidth
              }
            }

            // Controls
            Row {
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: 20

              Rectangle {
                width: 40; height: 40; radius: 20
                color: Colors.bgSubtle
                border.width: 1
                border.color: _p.border
                Behavior on scale { NumberAnimation { duration: 100 } }

                Text {
                  anchors.centerIn: parent
                  text: "\uDB81\uDCAE"
                  color: _p.fg
                  font.family: _p.uiFont
                  font.pixelSize: 16
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: parent.scale = 0.92
                  onExited:  parent.scale = 1
                  onClicked: { if (controlPanel.mediaPlayer) controlPanel.mediaPlayer.previous() }
                }
              }

              Rectangle {
                width: 48; height: 48; radius: 24
                color: _p.accent
                Behavior on scale { NumberAnimation { duration: 100 } }

                Text {
                  anchors.centerIn: parent
                  text: controlPanel.mediaPlayer && controlPanel.mediaPlayer.isPlaying ? "\uDB80\uDFE4" : "\uDB81\uDC0A"
                  color: Colors.bg
                  font.family: _p.uiFont
                  font.pixelSize: 20
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: parent.scale = 0.92
                  onExited:  parent.scale = 1
                  onClicked: { if (controlPanel.mediaPlayer) controlPanel.mediaPlayer.togglePlaying() }
                }
              }

              Rectangle {
                width: 40; height: 40; radius: 20
                color: Colors.bgSubtle
                border.width: 1
                border.color: _p.border
                Behavior on scale { NumberAnimation { duration: 100 } }

                Text {
                  anchors.centerIn: parent
                  text: "\uDB81\uDCAD"
                  color: _p.fg
                  font.family: _p.uiFont
                  font.pixelSize: 16
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: parent.scale = 0.92
                  onExited:  parent.scale = 1
                  onClicked: { if (controlPanel.mediaPlayer) controlPanel.mediaPlayer.next() }
                }
              }
            }
          }
        }

        // ════════════════ SYSTEM CARD ════════════════
        Rectangle {
          width: parent.width
          radius: 20
          color: Colors.bgRaised
          border.width: 1
          border.color: _p.border
          implicitHeight: systemCol.implicitHeight + 40

          Column {
            id: systemCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
            spacing: 18

            RowLayout {
              width: parent.width
              spacing: 10

              Rectangle {
                width: 6; height: 16; radius: 3
                color: _p.accent
                Layout.alignment: Qt.AlignVCenter
              }

              Text {
                text: "System"
                color: _p.fgMid
                font.family: _p.uiFont
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 1.2
                Layout.alignment: Qt.AlignVCenter
              }

              Item { Layout.fillWidth: true }
            }

            // Volume
            RowLayout {
              width: parent.width
              spacing: 12

              Rectangle {
                id: volIconBox
                Layout.preferredWidth: 38; Layout.preferredHeight: 38
                radius: 12
                color: controlPanel.volMuted ? Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.12) : Colors.bgSubtle
                border.width: 1
                border.color: controlPanel.volMuted ? Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.25) : _p.border

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
                  onEntered: volIconBox.color = controlPanel.volMuted ? Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.25) : Qt.rgba(0.28, 0.28, 0.36, 1)
                  onExited:  volIconBox.color = controlPanel.volMuted ? Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.12) : Colors.bgSubtle
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
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: implicitWidth
              }

              SliderControl {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                value: controlPanel.volPct
                fillColor: controlPanel.volMuted ? _p.red : _p.accent
                snapPercent: 5
                onMoved: function(v) {
                  volSetTimer.target = v;
                  volSetTimer.restart();
                }
              }

              Text {
                text: Math.round(controlPanel.volPct * 100) + "%"
                color: controlPanel.volMuted ? _p.red : _p.fg
                font.family: _p.uiFont
                font.pixelSize: 12
                font.bold: true
                opacity: 0.8
                Layout.preferredWidth: implicitWidth
              }
            }

            // Microphone
            RowLayout {
              width: parent.width
              spacing: 12
              visible: Pipewire.ready && controlPanel.micNode !== null

              Rectangle {
                id: micIconBox
                Layout.preferredWidth: 38; Layout.preferredHeight: 38
                radius: 12
                color: controlPanel.micMuted ? Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.10) : Colors.bgSubtle
                border.width: 1
                border.color: controlPanel.micMuted ? Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.25) : _p.border

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
                  onEntered: micIconBox.color = controlPanel.micMuted ? Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.25) : Qt.rgba(0.28, 0.28, 0.36, 1)
                  onExited:  micIconBox.color = controlPanel.micMuted ? Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.10) : Colors.bgSubtle
                  onClicked: {
                    if (controlPanel.micNode && controlPanel.micNode.audio) {
                      controlPanel.micNode.audio.muted = !controlPanel.micMuted;
                    }
                  }
                }
              }

              Text {
                text: "Mic"
                color: _p.fg
                font.family: _p.uiFont
                font.pixelSize: 12
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: implicitWidth
              }

              Item {
                Layout.fillWidth: true
                height: 38

                Rectangle {
                  id: micToggle
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.left: parent.left
                  width: 52; height: 28
                  radius: 14
                  color: controlPanel.micMuted ? Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.18) : Qt.rgba(Colors.green.r, Colors.green.g, Colors.green.b, 0.18)
                  border.width: 1
                  border.color: controlPanel.micMuted ? Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.3) : Qt.rgba(Colors.green.r, Colors.green.g, Colors.green.b, 0.3)

                  Rectangle {
                    x: controlPanel.micMuted ? 3 : micToggle.width - width - 3
                    y: 3
                    width: micToggle.height - 6; height: micToggle.height - 6
                    radius: width / 2
                    color: controlPanel.micMuted ? _p.red : _p.green
                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                  }

                  MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (controlPanel.micNode && controlPanel.micNode.audio) {
                        controlPanel.micNode.audio.muted = !controlPanel.micMuted;
                      }
                    }
                  }
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.left: micToggle.right
                  anchors.leftMargin: 12
                  text: controlPanel.micMuted ? "Muted" : "Live"
                  color: controlPanel.micMuted ? _p.red : _p.green
                  font.family: _p.uiFont
                  font.pixelSize: 11
                  font.bold: true
                  Behavior on color { ColorAnimation { duration: 150 } }
                }
              }
            }

            // Brightness
            RowLayout {
              width: parent.width
              spacing: 12
              visible: controlPanel.brightnessAvailable

              Rectangle {
                id: brtIconBox
                Layout.preferredWidth: 38; Layout.preferredHeight: 38
                radius: 12
                color: Colors.bgSubtle
                border.width: 1
                border.color: _p.border

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
                  onEntered: brtIconBox.color = Qt.rgba(0.28, 0.28, 0.36, 1)
                  onExited:  brtIconBox.color = Colors.bgSubtle
                }
              }

              Text {
                text: "Brightness"
                color: _p.fg
                font.family: _p.uiFont
                font.pixelSize: 12
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: implicitWidth
              }

              SliderControl {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                value: controlPanel.brightnessPct
                fillColor: _p.yellow
                snapPercent: 5
                onMoved: function(v) {
                  controlPanel.brightnessDragging = true;
                  controlPanel.brightnessPct = v;
                  brightnessSetTimer.target = v;
                  brightnessSetTimer.restart();
                }
                onDragEnded: controlPanel.brightnessDragging = false
              }

              Text {
                text: Math.round(controlPanel.brightnessPct * 100) + "%"
                color: _p.fg
                font.family: _p.uiFont
                font.pixelSize: 12
                font.bold: true
                opacity: 0.8
                Layout.preferredWidth: implicitWidth
              }
            }
          }
        }

        // ════════════════ QUICK ACTIONS ════════════════
        Rectangle {
          width: parent.width
          radius: 20
          color: Colors.bgRaised
          border.width: 1
          border.color: _p.border
          implicitHeight: actionsCol.implicitHeight + 40

          Column {
            id: actionsCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
            spacing: 14

            RowLayout {
              width: parent.width
              spacing: 10

              Rectangle {
                width: 6; height: 16; radius: 3
                color: _p.purple
                Layout.alignment: Qt.AlignVCenter
              }

              Text {
                text: "Power"
                color: _p.fgMid
                font.family: _p.uiFont
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 1.2
                Layout.alignment: Qt.AlignVCenter
              }

              Item { Layout.fillWidth: true }
            }

            Grid {
              width: parent.width
              columns: 2
              spacing: 10

              Repeater {
                model: [
                  { id: "lock", icon: "\uDB80\uDD3E", label: "Lock",    color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.15), accent: _p.accent, proc: lockProc },
                  { id: "caffeinate", icon: "\uF0F4", label: "Caffeinate", color: Qt.rgba(Colors.orange.r, Colors.orange.g, Colors.orange.b, 0.15), accent: _p.orange },
                  { id: "logout", icon: "\uDB80\uDD43", label: "Logout",  color: Qt.rgba(Colors.yellow.r, Colors.yellow.g, Colors.yellow.b, 0.15), accent: _p.yellow, proc: logoutProc },
                  { id: "sleep", icon: "\uDB81\uDD94", label: "Sleep",   color: Qt.rgba(Colors.green.r, Colors.green.g, Colors.green.b, 0.15), accent: _p.green,  proc: sleepProc },
                  { id: "reboot", icon: "\uDB81\uDF09", label: "Reboot",  color: Qt.rgba(Colors.purple.r, Colors.purple.g, Colors.purple.b, 0.15), accent: _p.purple, proc: rebootProc },
                  { id: "poweroff", icon: "\uDB81\uDC25", label: "Off",     color: Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.15), accent: _p.red,    proc: poweroffProc },
                ]

                delegate: Rectangle {
                  required property var modelData
                  property bool _isCaffeineActive: modelData.id === "caffeinate" && controlPanel.caffeinated
                  property bool _hovered: false
                  width: (parent.width - parent.spacing) / 2
                  height: 52
                  radius: 14

                  color: {
                    if (_isCaffeineActive)
                      return _hovered ? Qt.rgba(modelData.accent.r, modelData.accent.g, modelData.accent.b, 0.45)
                                      : Qt.rgba(modelData.accent.r, modelData.accent.g, modelData.accent.b, 0.35);
                    return _hovered ? Qt.rgba(modelData.accent.r, modelData.accent.g, modelData.accent.b, 0.25)
                                    : modelData.color;
                  }
                  border.width: 1
                  border.color: _isCaffeineActive ? modelData.accent : Qt.rgba(modelData.accent.r, modelData.accent.g, modelData.accent.b, 0.2)

                  Behavior on scale  { NumberAnimation { duration: 80 } }
                  Behavior on color  { ColorAnimation { duration: 60 } }
                  Behavior on border.color { ColorAnimation { duration: 60 } }

                  Row {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14 }
                    spacing: 10

                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      text: modelData.icon
                      color: modelData.accent
                      font.family: _p.uiFont
                      font.pixelSize: 18
                    }

                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      text: modelData.label
                      color: _p.fg
                      font.family: _p.uiFont
                      font.pixelSize: 12
                      font.bold: true
                    }
                  }

                  MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: parent._hovered = true
                    onExited:  parent._hovered = false
                    onClicked: {
                      if (modelData.id === "caffeinate") {
                        if (controlPanel.caffeinated) caffeinateStopProc.startDetached();
                        else caffeinateStartProc.startDetached();
                      } else if (modelData.proc) {
                        modelData.proc.startDetached();
                      }
                    }
                  }
                }
              }
            }
          }
        }

        // ════════════════ NOTIFICATIONS ════════════════
        Rectangle {
          width: parent.width
          radius: 20
          color: Colors.bgRaised
          border.width: 1
          border.color: _p.border
          implicitHeight: notifCol.implicitHeight + 40

          Column {
            id: notifCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
            spacing: 14

            RowLayout {
              width: parent.width
              spacing: 10

              Rectangle {
                width: 6; height: 16; radius: 3
                color: _p.teal
                Layout.alignment: Qt.AlignVCenter
              }

              Text {
                text: "Notifications"
                color: _p.fgMid
                font.family: _p.uiFont
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 1.2
                Layout.alignment: Qt.AlignVCenter
              }

              Item { Layout.fillWidth: true }

              Rectangle {
                id: dndToggle
                Layout.preferredWidth: 48; Layout.preferredHeight: 26
                radius: 13
                color: (root && root.doNotDisturb) ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.25) : Colors.bgSubtle
                border.width: 1
                border.color: (root && root.doNotDisturb) ? _p.accent : _p.border

                Rectangle {
                  x: (root && root.doNotDisturb) ? parent.width - width - 3 : 3
                  y: 3
                  width: parent.height - 6; height: parent.height - 6
                  radius: width / 2
                  color: (root && root.doNotDisturb) ? _p.accent : _p.fgDim
                  Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                  Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: { if (root) root.doNotDisturb = !root.doNotDisturb; }
                }
              }

              Text {
                text: (root && root.doNotDisturb) ? "DND" : "All"
                color: (root && root.doNotDisturb) ? _p.accent : _p.fgDim
                font.family: _p.uiFont
                font.pixelSize: 11
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: implicitWidth
                Behavior on color { ColorAnimation { duration: 150 } }
              }

              Rectangle {
                id: clearAllBtn
                Layout.preferredWidth: clearAllText.implicitWidth + 20
                Layout.preferredHeight: 28
                Layout.alignment: Qt.AlignVCenter
                radius: 8
                color: "transparent"
                border.width: 1
                border.color: _p.border

                Text {
                  id: clearAllText
                  anchors.centerIn: parent
                  text: root ? "Clear (" + root.notificationServer.trackedNotifications.values.length + ")" : "Clear"
                  color: _p.fgMid
                  font.family: _p.uiFont
                  font.pixelSize: 10
                  font.bold: true
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: { clearAllBtn.color = Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.15); clearAllBtn.border.color = _p.red }
                  onExited:  { clearAllBtn.color = "transparent"; clearAllBtn.border.color = _p.border }
                  onClicked: { if (root) root.clearNotifications(); }
                }
              }
            }

            Text {
              width: parent.width
              text: (root && root.doNotDisturb) ? "Critical alerts will still appear" : "Notifications adapt to urgency"
              color: _p.fgDim
              font.family: _p.uiFont
              font.pixelSize: 10
              wrapMode: Text.Wrap
              opacity: 0.5
            }

            Repeater {
              model: root ? root.notificationServer.trackedNotifications : null

              delegate: Rectangle {
                required property QtObject modelData
                property QtObject notification: modelData

                width: parent.width
                implicitHeight: notifCardCol.implicitHeight + 28
                height: implicitHeight
                radius: 14
                color: Colors.bg
                border.width: 1
                border.color: _p.border
                opacity: 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Component.onCompleted: opacity = 1

                Rectangle {
                  anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                  width: 3; radius: 1.5
                  color: notification && notification.urgency === NotificationUrgency.Critical
                    ? _p.red : (notification && notification.urgency === NotificationUrgency.Low
                      ? _p.fgDim : _p.accent)
                }

                Column {
                  id: notifCardCol
                  anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                  anchors.leftMargin: 22
                  spacing: root ? root.cardSpacing : 6

                  Row {
                    width: parent.width
                    spacing: 8

                    AppIcon {
                      notification: modelData
                      fallbackBg: root ? root.bgRaised : Colors.bgRaised
                    }

                    Text {
                      width: Math.max(0, parent.width - dismissNotif.width - parent.spacing - 24 - parent.spacing)
                      text: (notification && notification.appName && notification.appName.length > 0)
                        ? notification.appName : "Notification"
                      color: _p.accent
                      font.family: _p.uiFont
                      font.pixelSize: 11
                      font.bold: true
                      elide: Text.ElideRight
                      verticalAlignment: Text.AlignVCenter
                      height: 24
                    }

                    Rectangle {
                      id: dismissNotif
                      width: 22; height: 22
                      radius: 6
                      color: "transparent"
                      border.width: 1
                      border.color: _p.border

                      Text {
                        anchors.centerIn: parent
                        text: "\uDB80\uDD56"
                        color: _p.fgDim
                        font.family: _p.uiFont
                        font.pixelSize: 11
                      }

                      MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: { dismissNotif.color = Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.15); dismissNotif.border.color = _p.red }
                        onExited:  { dismissNotif.color = "transparent"; dismissNotif.border.color = _p.border }
                        onClicked: notification.dismiss()
                      }
                    }
                  }

                  Text {
                    text: notification ? (root ? root.stripMarkup(notification.summary || "") : notification.summary || "") : ""
                    width: parent.width
                    color: _p.fg
                    font.family: _p.uiFont
                    font.pixelSize: 12
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
                    font.pixelSize: 11
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
            }

            // Empty state
            Item {
              width: parent.width
              height: visible ? 100 : 0
              visible: !root || !root.notificationServer || root.notificationServer.trackedNotifications.values.length === 0

              Column {
                anchors.centerIn: parent
                spacing: 6

                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: "\uDB80\uDC9C"
                  color: _p.fgDim
                  font.family: _p.uiFont
                  font.pixelSize: 28
                  opacity: 0.3
                }

                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: "No notifications"
                  color: _p.fgDim
                  font.family: _p.uiFont
                  font.pixelSize: 12
                  font.bold: true
                  opacity: 0.5
                }
              }
            }
          }
        }
      }
    }
  }
}
