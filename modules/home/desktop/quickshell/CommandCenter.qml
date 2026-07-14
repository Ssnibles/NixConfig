import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQml

PanelWindow {
  id: controlPanel

  // root is injected by shell.qml when embedded; when running standalone it's null.
  property QtObject root: null
  property QtObject _p: palette

  // Local palette that falls back to the global Colors singleton so this panel
  // works both standalone (loaded directly) and embedded (via shell.qml).
  QtObject {
    id: palette
    property color fg:        (controlPanel.root && controlPanel.root.fg !== undefined)        ? controlPanel.root.fg        : Colors.fg
    property color fgMid:     (controlPanel.root && controlPanel.root.fgMid !== undefined)     ? controlPanel.root.fgMid     : Colors.fgMid
    property color fgDim:     (controlPanel.root && controlPanel.root.fgDim !== undefined)     ? controlPanel.root.fgDim     : Colors.fgDim
    property color bg:        Colors.bg
    property color bgRaised:  Colors.bgRaised
    property color bgSubtle:  (controlPanel.root && controlPanel.root.bgSubtle !== undefined)  ? controlPanel.root.bgSubtle  : Colors.bgSubtle
    property color border:    (controlPanel.root && controlPanel.root.border !== undefined)    ? controlPanel.root.border    : Colors.border
    property color accent:    (controlPanel.root && controlPanel.root.accent !== undefined)    ? controlPanel.root.accent    : Colors.accent
    property color red:       (controlPanel.root && controlPanel.root.red !== undefined)       ? controlPanel.root.red       : Colors.red
    property color green:     (controlPanel.root && controlPanel.root.green !== undefined)     ? controlPanel.root.green     : Colors.green
    property color yellow:    (controlPanel.root && controlPanel.root.yellow !== undefined)    ? controlPanel.root.yellow    : Colors.yellow
    property color purple:    (controlPanel.root && controlPanel.root.purple !== undefined)    ? controlPanel.root.purple    : Colors.purple
    property color orange:    (controlPanel.root && controlPanel.root.orange !== undefined)    ? controlPanel.root.orange    : Colors.orange
    property color teal:      (controlPanel.root && controlPanel.root.teal !== undefined)      ? controlPanel.root.teal      : Colors.teal
    property string uiFont:   (controlPanel.root && controlPanel.root.uiFont !== undefined)    ? controlPanel.root.uiFont    : "JetBrainsMono Nerd Font"
    property string specialFont: (controlPanel.root && controlPanel.root.specialFont !== undefined) ? controlPanel.root.specialFont : "Instrument Serif"
  }

  // ── Volume ──
  // PwObjectTracker is required by Quickshell so bindings update when the default sink changes.
  property var volNodes: Pipewire.ready && Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
  PwObjectTracker { objects: controlPanel.volNodes }
  property var volInfo: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
  property real volPct: volInfo ? volInfo.volume : 0
  property bool volMuted: volInfo ? volInfo.muted : false

  // ── Microphone ──
  // Pipewire.defaultAudioSource is broken on some systems (it resolves to the sink),
  // so we manually scan Pipewire.nodes for the first non-monitor audio source.
  property var micNode: controlPanel._findMicNode()
  property var micNodes: controlPanel.micNode ? [controlPanel.micNode] : []
  PwObjectTracker { objects: controlPanel.micNodes }
  property var micInfo: controlPanel.micNode ? controlPanel.micNode.audio : null
  property bool micMuted: micInfo ? micInfo.muted : false

  // ── Brightness ──
  // Supports three backends, tried in order: sysfs (laptop), brightnessctl (generic),
  // and ddcutil (external monitors via DDC/CI).
  property string backlightPath: ""
  property real brightnessMax: 0
  property real brightnessPct: 0.8
  property bool brightnessAvailable: true
  property bool brightnessDiscovered: false
  property string brightnessBackend: ""  // "sysfs", "brightnessctl", "ddcutil", or ""
  property bool brightnessDragging: false

  // ── Media ──
  // Prefer the currently playing player; fall back to the most recently paused one.
  property var mediaPlayers: Mpris.players.values
  property var mediaPlayer: {
    var playing = _findFirst(mediaPlayers, function(p) { return p.isPlaying })
    return playing ? playing : _findFirst(mediaPlayers, function(p) {
      return p.playbackState === MprisPlaybackState.Paused
    })
  }
  property string mediaText: mediaPlayer
    ? (mediaPlayer.trackArtist
      ? mediaPlayer.trackTitle + " \u2014 " + mediaPlayer.trackArtist
      : mediaPlayer.trackTitle)
    : ""
  property string mediaSubtext: {
    if (!mediaPlayer) return ""
    var parts = []
    if (mediaPlayer.trackAlbum) parts.push(mediaPlayer.trackAlbum)
    parts.push(mediaPlayer.name || "")
    return parts.join(" \u2014 ")
  }
  // _mediaTick is bumped by a timer so this computed property re-evaluates,
  // keeping the seek-bar position in sync while music is playing.
  property int _mediaTick: 0
  property real mediaLastPosition: 0
  property real mediaLastLength: 0
  property int mediaResetToken: 0
  function _resetMediaTiming(pos, len) {
    controlPanel.mediaLastPosition = Math.max(0, pos || 0)
    controlPanel.mediaLastLength = Math.max(0, len || 0)
    controlPanel._mediaTick = 0
    controlPanel.mediaResetToken++
  }
  function _updateMediaPosition(pos, len) {
    var p = Math.max(0, pos || 0)
    var l = Math.max(0, len || 0)
    if (p + 0.5 < controlPanel.mediaLastPosition) {
      controlPanel._resetMediaTiming(p, l)
      return
    }
    controlPanel.mediaLastPosition = p
    controlPanel.mediaLastLength = l
  }
  property real mediaProgress: {
    var _ = controlPanel._mediaTick
    var __ = controlPanel.mediaResetToken
    return mediaPlayer && controlPanel.mediaLastLength > 0
      ? Math.min(1, Math.max(0, controlPanel.mediaLastPosition / controlPanel.mediaLastLength))
      : 0
  }
  onMediaPlayerChanged: {
    if (!mediaPlayer) {
      controlPanel._resetMediaTiming(0, 0)
      return
    }
    controlPanel._resetMediaTiming(mediaPlayer.position, mediaPlayer.length)
  }

  Connections {
    target: controlPanel.mediaPlayer
    function onPositionChanged() {
      if (!controlPanel.mediaPlayer) return
      controlPanel._updateMediaPosition(controlPanel.mediaPlayer.position, controlPanel.mediaPlayer.length)
    }
    function onLengthChanged() {
      if (!controlPanel.mediaPlayer) return
      controlPanel.mediaLastLength = Math.max(0, controlPanel.mediaPlayer.length || 0)
    }
    function onTrackChanged() {
      if (!controlPanel.mediaPlayer) return
      controlPanel._resetMediaTiming(controlPanel.mediaPlayer.position, controlPanel.mediaPlayer.length)
    }
  }

  Timer {
    interval: 500
    running: controlPanel.visible && controlPanel.mediaPlayer && controlPanel.mediaPlayer.isPlaying
    repeat: true
    onTriggered: {
      if (controlPanel.mediaPlayer) {
        controlPanel._updateMediaPosition(controlPanel.mediaPlayer.position, controlPanel.mediaPlayer.length)
      }
      controlPanel._mediaTick++
    }
  }

  // ── Animation state ──
  property real panelOpacity: 0
  property real panelSlide: 60
  property bool _isOpen: panelOpacity > 0
  property bool _closeRequested: false
  // Workaround: mark surface as prerendered so onCompleted logic only runs once.
  property bool _surfacePrerendered: false

  Component.onCompleted: {
    _surfacePrerendered = true
    controlPanel._discoverBacklight()
  }

  onVisibleChanged: {
    if (visible) {
      controlPanel._closeRequested = false
      fadeOutAnim.stop()
      panelOpacity = 0
      panelSlide = 60
      fadeInAnim.start()
      // Only refresh fast backends on show; ddcutil is slow and updated by its own timer.
      if (controlPanel.brightnessBackend === "sysfs" || controlPanel.brightnessBackend === "brightnessctl") {
        controlPanel._refreshBrightness()
      }
    } else {
      panelOpacity = 0
      panelSlide = 60
      controlPanel._closeRequested = false
    }
  }

  SequentialAnimation {
    id: fadeInAnim
    // Tiny pause ensures the surface is ready before animating in.
    PauseAnimation { duration: 1 }
    ParallelAnimation {
      NumberAnimation { target: controlPanel; property: "panelOpacity"; to: 1; duration: 300; easing.type: Easing.OutCubic }
      NumberAnimation { target: controlPanel; property: "panelSlide"; to: 0; duration: 300; easing.type: Easing.OutCubic }
    }
  }

  SequentialAnimation {
    id: fadeOutAnim
    ParallelAnimation {
      NumberAnimation { target: controlPanel; property: "panelOpacity"; to: 0; duration: 200; easing.type: Easing.OutCubic }
      NumberAnimation { target: controlPanel; property: "panelSlide"; to: 60; duration: 200; easing.type: Easing.OutCubic }
    }
    // Only actually hide the window after the animation finishes.
    onFinished: {
      if (controlPanel._closeRequested) {
        controlPanel.visible = false
        controlPanel._closeRequested = false
      }
    }
  }

  function requestHide() {
    if (controlPanel.visible && !controlPanel._closeRequested) {
      controlPanel._closeRequested = true
      fadeOutAnim.start()
    }
  }

  // Kick off brightness discovery by listing sysfs backlight devices.
  function _discoverBacklight() {
    controlPanel.brightnessDiscovered = true
    backlightDiscoverProc.exec(["sh", "-c", "ls -1 /sys/class/backlight/ 2>/dev/null || true"])
  }

  // Try each sysfs backlight directory; if none work, fall back to brightnessctl, then ddcutil.
  function _tryBacklightDirs(dirs) {
    var base = "/sys/class/backlight/"
    for (var i = 0; i < dirs.length; i++) {
      try {
        // Use synchronous XMLHttpRequest to read local sysfs files from QML.
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + base + dirs[i] + "/max_brightness", false)
        xhr.send()
        if (xhr.status === 0 || xhr.status === 200) {
          var maxVal = parseInt(xhr.responseText.trim())
          if (!isNaN(maxVal) && maxVal > 0) {
            controlPanel.backlightPath = base + dirs[i]
            controlPanel.brightnessMax = maxVal
            controlPanel.brightnessBackend = "sysfs"
            controlPanel.brightnessAvailable = true
            controlPanel._refreshBrightness()
            return
          }
        }
      } catch(e) {}
    }
    // No sysfs backlight found — try brightnessctl fallback
    brightnessFallbackProc.exec(["sh", "-c", "echo $(brightnessctl get 2>/dev/null) $(brightnessctl max 2>/dev/null)"])
  }

  // Query the current brightness value from whichever backend is active.
  function _refreshBrightness() {
    if (controlPanel.brightnessBackend === "sysfs" && controlPanel.backlightPath) {
      brightnessReadProc.exec(["brightnessctl", "get"])
    } else if (controlPanel.brightnessBackend === "brightnessctl") {
      brightnessFallbackProc.exec(["sh", "-c", "echo $(brightnessctl get 2>/dev/null) $(brightnessctl max 2>/dev/null)"])
    } else if (controlPanel.brightnessBackend === "ddcutil") {
      ddcutilReadProc.exec(["ddcutil", "--sleep-multiplier", "0.1", "getvcp", "10", "--brief"])
    }
  }

  // Clamp to 5% minimum, then dispatch to the active brightness backend.
  function _setBrightness(pct) {
    controlPanel.brightnessPct = Math.max(0.05, Math.min(1, pct))
    if (controlPanel.brightnessBackend === "sysfs" || controlPanel.brightnessBackend === "brightnessctl") {
      brightnessSetProc.command = ["brightnessctl", "set", Math.round(controlPanel.brightnessPct * 100) + "%"]
      brightnessSetProc.startDetached()
    } else if (controlPanel.brightnessBackend === "ddcutil") {
      var val = Math.round(controlPanel.brightnessPct * controlPanel.brightnessMax)
      ddcutilSetProc.command = [
        "ddcutil", "--sleep-multiplier", "0.1", "setvcp", "--noverify", "10", "" + val
      ]
      ddcutilSetProc.startDetached()
    }
  }

  function _findFirst(list, predicate) {
    for (var i = 0; i < list.length; i++) {
      if (predicate(list[i])) return list[i]
    }
    return null
  }

  // Scan all Pipewire nodes for the first real capture (source) device.
  // Excludes monitor sources because those are loopback, not physical mics.
  function _findMicNode() {
    if (!Pipewire.ready) return null
    var nodes = Pipewire.nodes
    var arr = nodes && nodes.values ? nodes.values : nodes
    for (var i = 0; i < arr.length; i++) {
      var n = arr[i]
      if (n && n.audio && !n.isSink) {
        var name = n.name || ""
        if (name.indexOf("monitor") !== -1) continue
        return n
      }
    }
    return null
  }

  function _formatTime(seconds) {
    var s = Math.round(seconds)
    if (s < 0) s = 0
    var m = Math.floor(s / 60)
    s = s % 60
    return m + ":" + (s < 10 ? "0" : "") + s
  }

  // Some MPRIS players return URLs wrapped in literal quotes; strip them.
  function _coverArtUrl() {
    if (!controlPanel.mediaPlayer) return ""
    var url = controlPanel.mediaPlayer.trackArtUrl
    if (url) {
      url = String(url).trim()
      if (url.charAt(0) === '"' && url.charAt(url.length - 1) === '"') url = url.slice(1, -1)
      return url
    }
    var meta = controlPanel.mediaPlayer.metadata
    if (meta) {
      var raw = meta["mpris:artUrl"]
      if (raw) {
        url = String(raw).trim()
        if (url.charAt(0) === '"' && url.charAt(url.length - 1) === '"') url = url.slice(1, -1)
        return url
      }
    }
    return ""
  }

  Process { id: brightnessSetProc }
  Process { id: ddcutilSetProc }
  Process {
    id: brightnessReadProc
    stdout: StdioCollector {
      onDataChanged: {
        var val = parseInt(this.text.trim())
        if (!isNaN(val) && controlPanel.brightnessMax > 0) {
          controlPanel.brightnessPct = Math.max(0, Math.min(1, val / controlPanel.brightnessMax))
        }
      }
    }
  }
  Process {
    id: brightnessFallbackProc
    stdout: StdioCollector {
      onDataChanged: {
        var parts = this.text.trim().split(/\s+/).filter(function(s) { return s.length > 0 })
        if (parts.length >= 2) {
          var cur = parseInt(parts[0])
          var max = parseInt(parts[1])
          if (!isNaN(cur) && !isNaN(max) && max > 1) {
            controlPanel.brightnessMax = max
            controlPanel.brightnessPct = Math.max(0, Math.min(1, cur / max))
            controlPanel.brightnessAvailable = true
            controlPanel.brightnessBackend = "brightnessctl"
            return
          }
        }
        // brightnessctl fallback failed — try ddcutil for desktop monitors
        ddcutilDiscoverProc.exec(["ddcutil", "--sleep-multiplier", "0.1", "getvcp", "10", "--brief"])
      }
    }
  }
  Process {
    id: ddcutilDiscoverProc
    stdout: StdioCollector {
      onDataChanged: {
        var parts = this.text.trim().split(/\s+/).filter(function(s) { return s.length > 0 })
        // ddcutil brief output format: VCP 10 C <current> <max>
        if (parts.length >= 5 && parts[0] === "VCP" && parts[1] === "10") {
          var cur = parseInt(parts[3])
          var max = parseInt(parts[4])
          if (!isNaN(cur) && !isNaN(max) && max > 0) {
            controlPanel.brightnessMax = max
            controlPanel.brightnessPct = Math.max(0, Math.min(1, cur / max))
            controlPanel.brightnessAvailable = true
            controlPanel.brightnessBackend = "ddcutil"
            return
          }
        }
        controlPanel.brightnessAvailable = false
        controlPanel.brightnessBackend = ""
      }
    }
  }
  Process {
    id: ddcutilReadProc
    stdout: StdioCollector {
      onDataChanged: {
        var parts = this.text.trim().split(/\s+/).filter(function(s) { return s.length > 0 })
        if (parts.length >= 5 && parts[0] === "VCP" && parts[1] === "10") {
          var cur = parseInt(parts[3])
          var max = parseInt(parts[4])
          if (!isNaN(cur) && !isNaN(max) && max > 0) {
            controlPanel.brightnessMax = max
            if (!controlPanel.brightnessDragging) {
              controlPanel.brightnessPct = Math.max(0, Math.min(1, cur / max))
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
        var dirs = this.text.trim().split('\n').filter(function(d) { return d.length > 0 })
        controlPanel._tryBacklightDirs(dirs)
      }
    }
  }

  // Poll brightness while the panel is open so external changes (e.g. Fn keys)
  // are reflected in the slider. Disabled during dragging to avoid fighting the user.
  Timer {
    interval: 500
    running: controlPanel._isOpen && controlPanel.brightnessAvailable && controlPanel.brightnessBackend.length > 0 && !controlPanel.brightnessDragging
    repeat: true
    onTriggered: controlPanel._refreshBrightness()
  }

  // ── Volume debounce (batch rapid slider updates) ──
  // Fires 80ms after the slider stops moving so we don't spam wpctl.
  Timer {
    id: volSetTimer
    interval: 80
    repeat: false
    property real target: 0
    onTriggered: {
      var pct = Math.round(target * 100)
      volSetProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", pct + "%"]
      volSetProc.startDetached()
    }
  }
  Process { id: volSetProc }

  // ── Brightness debounce (batch rapid slider updates) ──
  Timer {
    id: brightnessSetTimer
    interval: 80
    repeat: false
    property real target: 0
    onTriggered: controlPanel._setBrightness(target)
  }

  // ── Quick action processes ──
  Process { id: lockProc; command: ["qs", "-c", "default", "ipc", "call", "sessionlock", "lock"] }
  Process { id: logoutProc; command: ["hyprctl", "dispatch", "hl.dsp.exit()"] }
  Process { id: sleepProc; command: ["systemctl", "suspend"] }
  Process { id: rebootProc; command: ["systemctl", "reboot"] }
  Process { id: poweroffProc; command: ["systemctl", "poweroff"] }

  // ── Caffeinate (idle inhibit) ──
  // Uses systemd-inhibit to block idle/sleep. We store the PID in a tmpfile
  // so we can kill it later and check whether it's still running.
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
    running: controlPanel.visible
    repeat: true
    onTriggered: {
      // kill -0 checks if the process exists without sending a real signal.
      caffeinateCheckProc.exec(["sh", "-c", "kill -0 $(cat /tmp/quickshell-caffeine.pid 2>/dev/null) 2>/dev/null && echo active || echo inactive"])
    }
  }
  Process {
    id: caffeinateCheckProc
    stdout: StdioCollector {
      onDataChanged: {
        controlPanel.caffeinated = (this.text.trim() === "active")
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
    color: _p.bg
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

        // ── HEADER ──
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
              font.family: _p.specialFont
              font.pixelSize: 64
              font.bold: true
              font.italic: true

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

        // ── MEDIA CARD ──
        Rectangle {
          width: parent.width
          radius: 20
          color: _p.bgRaised
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

              ClippingRectangle {
                id: mediaArtContainer
                Layout.preferredWidth: 88
                Layout.preferredHeight: 88
                radius: 16
                color: _p.bgSubtle

                Image {
                  id: mediaArtImage
                  anchors.fill: parent
                  source: controlPanel._coverArtUrl()
                  fillMode: Image.PreserveAspectCrop
                  smooth: true
                  visible: status === Image.Ready || status === Image.Loading
                }

                Text {
                  anchors.centerIn: parent
                  text: "\u{F075A}"
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
                    onTextChanged: {
                      x = 0
                      if (overflow) mediaScroll1.restart()
                    }
                  }

                  SequentialAnimation {
                    id: mediaScroll1
                    running: controlPanel.visible && mediaTitleText.overflow
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
                  var _ = controlPanel._mediaTick
                  var __ = controlPanel.mediaResetToken
                  return controlPanel._formatTime(controlPanel.mediaLastPosition)
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
                  color: _p.bgSubtle

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
                      controlPanel.mediaPlayer.position = mouse.x / width * controlPanel.mediaPlayer.length
                    }
                  }
                }
              }

              Text {
                text: controlPanel._formatTime(controlPanel.mediaLastLength)
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
                width: 40
                height: 40
                radius: 20
                color: _p.bgSubtle
                border.width: 1
                border.color: _p.border
                Behavior on scale { NumberAnimation { duration: 100 } }

                Text {
                  anchors.centerIn: parent
                  text: "\u{F04AE}"
                  color: _p.fg
                  font.family: _p.uiFont
                  font.pixelSize: 16
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: parent.scale = 0.92
                  onExited: parent.scale = 1
                  onClicked: { if (controlPanel.mediaPlayer) controlPanel.mediaPlayer.previous() }
                }
              }

              Rectangle {
                width: 48
                height: 48
                radius: 24
                color: _p.accent
                Behavior on scale { NumberAnimation { duration: 100 } }

                Text {
                  anchors.centerIn: parent
                  text: controlPanel.mediaPlayer && controlPanel.mediaPlayer.isPlaying ? "\u{F03E4}" : "\u{F040A}"
                  color: _p.bg
                  font.family: _p.uiFont
                  font.pixelSize: 20
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: parent.scale = 0.92
                  onExited: parent.scale = 1
                  onClicked: { if (controlPanel.mediaPlayer) controlPanel.mediaPlayer.togglePlaying() }
                }
              }

              Rectangle {
                width: 40
                height: 40
                radius: 20
                color: _p.bgSubtle
                border.width: 1
                border.color: _p.border
                Behavior on scale { NumberAnimation { duration: 100 } }

                Text {
                  anchors.centerIn: parent
                  text: "\u{F04AD}"
                  color: _p.fg
                  font.family: _p.uiFont
                  font.pixelSize: 16
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: parent.scale = 0.92
                  onExited: parent.scale = 1
                  onClicked: { if (controlPanel.mediaPlayer) controlPanel.mediaPlayer.next() }
                }
              }
            }
          }
        }

        // ── SYSTEM CARD ──
        Rectangle {
          width: parent.width
          radius: 20
          color: _p.bgRaised
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
                width: 6
                height: 16
                radius: 3
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
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 12
                color: _p.bgSubtle
                border.width: 1
                border.color: controlPanel.volMuted ? _p.red : _p.border

                Text {
                  anchors.centerIn: parent
                  text: {
                    if (controlPanel.volMuted) return "\u{F075F}"
                    var v = controlPanel.volPct
                    if (v <= 0) return "\u{F075F}"
                    if (v < 0.33) return "\u{F057F}"
                    if (v < 0.66) return "\u{F0580}"
                    return "\u{F057E}"
                  }
                  color: controlPanel.volMuted ? _p.red : _p.fg
                  font.family: _p.uiFont
                  font.pixelSize: 16
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: {
                    volIconBox.color = _p.bgRaised
                    volIconBox.border.color = controlPanel.volMuted ? _p.red : _p.accent
                  }
                  onExited: {
                    volIconBox.color = _p.bgSubtle
                    volIconBox.border.color = controlPanel.volMuted ? _p.red : _p.border
                  }
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
                  volSetTimer.target = v
                  volSetTimer.restart()
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
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 12
                color: _p.bgSubtle
                border.width: 1
                border.color: controlPanel.micMuted ? _p.red : _p.border

                Text {
                  anchors.centerIn: parent
                  text: controlPanel.micMuted ? "\u{F036D}" : "\u{F036C}"
                  color: controlPanel.micMuted ? _p.red : _p.green
                  font.family: _p.uiFont
                  font.pixelSize: 16
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: {
                    micIconBox.color = _p.bgRaised
                    micIconBox.border.color = controlPanel.micMuted ? _p.red : _p.accent
                  }
                  onExited: {
                    micIconBox.color = _p.bgSubtle
                    micIconBox.border.color = controlPanel.micMuted ? _p.red : _p.border
                  }
                  onClicked: {
                    if (controlPanel.micNode && controlPanel.micNode.audio) {
                      controlPanel.micNode.audio.muted = !controlPanel.micMuted
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
                  width: 52
                  height: 28
                  radius: 14
                  color: controlPanel.micMuted
                    ? Qt.rgba(_p.red.r, _p.red.g, _p.red.b, 0.18)
                    : Qt.rgba(_p.green.r, _p.green.g, _p.green.b, 0.18)
                  border.width: 1
                  border.color: controlPanel.micMuted
                    ? Qt.rgba(_p.red.r, _p.red.g, _p.red.b, 0.3)
                    : Qt.rgba(_p.green.r, _p.green.g, _p.green.b, 0.3)

                  Rectangle {
                    x: controlPanel.micMuted ? 3 : micToggle.width - width - 3
                    y: 3
                    width: micToggle.height - 6
                    height: micToggle.height - 6
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
                        controlPanel.micNode.audio.muted = !controlPanel.micMuted
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
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 12
                color: _p.bgSubtle
                border.width: 1
                border.color: _p.border

                Text {
                  anchors.centerIn: parent
                  text: "\u{F00DF}"
                  color: _p.yellow
                  font.family: _p.uiFont
                  font.pixelSize: 16
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: {
                    brtIconBox.color = _p.bgRaised
                    brtIconBox.border.color = _p.yellow
                  }
                  onExited: {
                    brtIconBox.color = _p.bgSubtle
                    brtIconBox.border.color = _p.border
                  }
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
                  controlPanel.brightnessDragging = true
                  controlPanel.brightnessPct = v
                  brightnessSetTimer.target = v
                  brightnessSetTimer.restart()
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

        // ── QUICK ACTIONS ──
        Rectangle {
          width: parent.width
          radius: 20
          color: _p.bgRaised
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
                width: 6
                height: 16
                radius: 3
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
                  { id: "lock", icon: "\u{F033E}", label: "Lock Screen", color: Qt.rgba(_p.accent.r, _p.accent.g, _p.accent.b, 0.15), accent: _p.accent, proc: lockProc },
                  { id: "caffeinate", icon: "\u{F0176}", label: "Caffeinate", color: Qt.rgba(_p.orange.r, _p.orange.g, _p.orange.b, 0.15), accent: _p.orange },
                  { id: "logout", icon: "\u{F0343}", label: "Logout", color: Qt.rgba(_p.yellow.r, _p.yellow.g, _p.yellow.b, 0.15), accent: _p.yellow, proc: logoutProc },
                  { id: "sleep", icon: "\u{F0904}", label: "Sleep", color: Qt.rgba(_p.green.r, _p.green.g, _p.green.b, 0.15), accent: _p.green, proc: sleepProc },
                  { id: "reboot", icon: "\u{F0709}", label: "Reboot", color: Qt.rgba(_p.purple.r, _p.purple.g, _p.purple.b, 0.15), accent: _p.purple, proc: rebootProc },
                  { id: "poweroff", icon: "\u{F0425}", label: "Power Off", color: Qt.rgba(_p.red.r, _p.red.g, _p.red.b, 0.15), accent: _p.red, proc: poweroffProc }
                ]

                delegate: Rectangle {
                  required property var modelData
                  property bool _isCaffeineActive: modelData.id === "caffeinate" && controlPanel.caffeinated
                  property bool _hovered: false
                  width: (parent.width - parent.spacing) / 2
                  height: 48
                  radius: 12

                  color: _isCaffeineActive ? _p.bgRaised : _p.bgSubtle
                  border.width: 1
                  border.color: _isCaffeineActive ? modelData.accent : (_hovered ? modelData.accent : _p.border)

                  Behavior on scale { NumberAnimation { duration: 80 } }
                  Behavior on color { ColorAnimation { duration: 60 } }
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
                    onExited: parent._hovered = false
                    onClicked: {
                      if (modelData.id === "caffeinate") {
                        if (controlPanel.caffeinated) {
                          controlPanel.caffeinated = false
                          caffeinateStopProc.startDetached()
                        } else {
                          controlPanel.caffeinated = true
                          caffeinateStartProc.startDetached()
                        }
                      } else if (modelData.proc) {
                        modelData.proc.startDetached()
                      }
                    }
                  }
                }
              }
            }
          }
        }

        // ── NOTIFICATIONS ──
        Rectangle {
          width: parent.width
          radius: 20
          color: _p.bgRaised
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
                width: 6
                height: 16
                radius: 3
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
                Layout.preferredWidth: 48
                Layout.preferredHeight: 26
                radius: 13
                color: (root && root.doNotDisturb)
                  ? Qt.rgba(_p.accent.r, _p.accent.g, _p.accent.b, 0.25)
                  : _p.bgSubtle
                border.width: 1
                border.color: (root && root.doNotDisturb) ? _p.accent : _p.border

                Rectangle {
                  x: (root && root.doNotDisturb) ? parent.width - width - 3 : 3
                  y: 3
                  width: parent.height - 6
                  height: parent.height - 6
                  radius: width / 2
                  color: (root && root.doNotDisturb) ? _p.accent : _p.fgDim
                  Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                  Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: { if (root) root.doNotDisturb = !root.doNotDisturb }
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
                  onEntered: {
                    clearAllBtn.color = Qt.rgba(_p.red.r, _p.red.g, _p.red.b, 0.15)
                    clearAllBtn.border.color = _p.red
                  }
                  onExited: {
                    clearAllBtn.color = "transparent"
                    clearAllBtn.border.color = _p.border
                  }
                  onClicked: { if (root) root.clearNotifications() }
                }
              }
            }

            Text {
              width: parent.width
              text: (root && root.doNotDisturb)
                ? "Critical alerts will still appear"
                : "Notifications adapt to urgency"
              color: _p.fgDim
              font.family: _p.uiFont
              font.pixelSize: 10
              wrapMode: Text.Wrap
              opacity: 0.5
            }

            Repeater {
              model: controlPanel.visible ? (root ? root.notificationServer.trackedNotifications : null) : null

              delegate: Rectangle {
                required property QtObject modelData
                property QtObject notification: modelData
                property color _urgencyColor: notification && notification.urgency === NotificationUrgency.Critical
                  ? _p.red
                  : (notification && notification.urgency === NotificationUrgency.Low ? _p.fgDim : _p.accent)

                width: parent.width
                implicitHeight: notifCardCol.implicitHeight + 28
                height: implicitHeight
                radius: 20
                color: _p.bgRaised
                border.width: 1
                border.color: _urgencyColor
                opacity: 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Component.onCompleted: opacity = 1

                Column {
                  id: notifCardCol
                  anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                  spacing: 8

                  RowLayout {
                    width: parent.width
                    spacing: 8

                    Rectangle {
                      Layout.preferredWidth: 28
                      Layout.preferredHeight: 28
                      radius: 8
                      color: _p.bgSubtle
                      border.width: 1
                      border.color: _p.border

                      AppIcon {
                        anchors.centerIn: parent
                        notification: modelData
                        iconSize: 18
                        fallbackBg: _p.bgSubtle
                      }
                    }

                    Rectangle {
                      Layout.preferredWidth: 4
                      Layout.preferredHeight: 14
                      radius: 2
                      color: _urgencyColor
                      Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                      text: (notification && notification.appName && notification.appName.length > 0)
                        ? notification.appName.toUpperCase()
                        : "NOTIFICATION"
                      color: _p.accent
                      font.family: _p.uiFont
                      font.pixelSize: 10
                      font.bold: true
                      font.letterSpacing: 1.2
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                      Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                      id: dismissNotif
                      Layout.preferredWidth: 20
                      Layout.preferredHeight: 20
                      radius: 5
                      color: "transparent"
                      border.width: 1
                      border.color: _p.border
                      Layout.alignment: Qt.AlignVCenter

                      Text {
                        anchors.centerIn: parent
                        text: "\u00D7"
                        color: _p.fgDim
                        font.family: _p.uiFont
                        font.pixelSize: 12
                        font.bold: true
                      }

                      MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                          dismissNotif.color = _p.bgSubtle
                          dismissNotif.border.color = _p.red
                        }
                        onExited: {
                          dismissNotif.color = "transparent"
                          dismissNotif.border.color = _p.border
                        }
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
              visible: controlPanel.visible && (!root || !root.notificationServer || root.notificationServer.trackedNotifications.values.length === 0)

              Column {
                anchors.centerIn: parent
                spacing: 6

                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: "\u{F009C}"
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
