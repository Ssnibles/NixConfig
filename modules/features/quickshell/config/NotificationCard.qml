import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets

// Single notification card. Rendered by NotificationOverlay for each queued
// notification and by CommandCenter for history items.
Rectangle {
  id: root

  property var notification: null
  property string appName: ""
  property string desktopEntry: ""

  property string summary: ""
  property string body: ""
  property string appIcon: ""
  property string image: ""
  property int urgency: 1 // 0 = Low, 1 = Normal, 2 = Critical
  property string trackTitle: ""
  property string trackArtist: ""
  property bool isMedia: false
  readonly property bool isHovered: hoverArea.containsMouse
  signal dismissed()
  signal actionTriggered()

  // Retain the notification object while this card is shown.
  RetainableLock {
    object: root.notification
    locked: root.notification !== null
  }

  // Generate candidate list for icon resolution (fallback hierarchy)
  property var candidateIcons: {
    var list = []
    
    function addCandidate(s) {
      if (!s) return
      var str = String(s).trim()
      if (str.charAt(0) === '"' && str.charAt(str.length - 1) === '"') {
        str = str.slice(1, -1)
      }
      if (str !== "" && list.indexOf(str) === -1) {
        list.push(str)
      }
    }

    // Explicit notification image / art
    addCandidate(root.image)

    if (root.isMedia) {
      // Look up cached cover art from NotificationStore
      var cachedArt = NotificationStore.getCoverArt(
        root.trackTitle || (NotificationStore.mediaPlayer ? NotificationStore.mediaPlayer.trackTitle : ""),
        root.trackArtist || (NotificationStore.mediaPlayer ? NotificationStore.mediaPlayer.trackArtist : ""),
        root.image || (NotificationStore.mediaPlayer ? NotificationStore.mediaPlayer.trackArtUrl : "")
      )
      addCandidate(cachedArt)
      addCandidate(root.image)
      if (NotificationStore.mediaPlayer && NotificationStore.mediaPlayer.trackArtUrl) {
        addCandidate(NotificationStore.mediaPlayer.trackArtUrl)
      }
      if (NotificationStore.latestMediaImage) {
        addCandidate(NotificationStore.latestMediaImage)
      }
      return list
    }

    // Explicit app icon string provided by notification
    addCandidate(root.appIcon)

    // Desktop entry variations
    if (root.desktopEntry) {
      var de = String(root.desktopEntry).trim()
      if (de.endsWith(".desktop")) {
        de = de.substring(0, de.length - 8)
      }
      addCandidate(de)
      var deParts = de.split(".")
      if (deParts.length > 1) {
        addCandidate(deParts[deParts.length - 1])
      }
    }

    // App name variations
    if (root.appName) {
      var an = String(root.appName).trim().toLowerCase()
      addCandidate(an)
      addCandidate(an.replace(/\s+/g, "-"))
    }

    // Universal default fallback icons
    addCandidate("dialog-information")
    addCandidate("preferences-system-notifications")
    addCandidate("notification-symbolic")

    return list
  }

  function resolveIconSource(candidates) {
    if (!candidates || candidates.length === 0) return ""
    for (var i = 0; i < candidates.length; i++) {
      var src = String(candidates[i]).trim()
      if (src === "") continue
      if (src.startsWith("/") || src.startsWith("file://") || src.startsWith("http://") || src.startsWith("https://") || src.startsWith("image://")) {
        return src
      }
      if (Quickshell.hasThemeIcon(src)) {
        return "image://icon/" + src
      }
    }
    return ""
  }

  property string iconSource: resolveIconSource(candidateIcons)
  property bool hasIcon: true

  width: parent ? parent.width : Config.notifWidth
  height: Math.max(contentCol.implicitHeight, hasIcon ? (isMedia ? 48 : 40) : 0) + Config.notifCardMargins * 2
  radius: Config.notifRadius
  
  color: hoverArea.containsMouse ? Colors.bgRaised : Colors.bg
  border.color: hoverArea.containsMouse
    ? (isMedia ? Colors.teal : (urgency === 2 ? Colors.red : Colors.accent))
    : (urgency === 2 ? Colors.red : Colors.border)
  border.width: 1

  scale: hoverArea.containsMouse ? (hoverArea.pressed ? 0.98 : 1.02) : 1.0

  Behavior on color { ColorAnimation { duration: 150 } }
  Behavior on border.color { ColorAnimation { duration: 150 } }
  Behavior on scale { NumberAnimation { duration: 100 } }

  MouseArea {
    id: hoverArea
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      if (mouse.button === Qt.RightButton) {
        root.actionTriggered()
      } else {
        root.dismissed()
      }
    }
  }

  // Correlated fallback icon glyph based on appName / desktopEntry / summary
  property string fallbackGlyph: {
    var app = (appName || desktopEntry || "").toLowerCase().trim()
    var sum = (summary || "").toLowerCase().trim()

    if (isMedia) return "󰎈"

    // App/Service specific matching
    if (app.indexOf("spotify") !== -1) return "󰓇"
    if (app.indexOf("firefox") !== -1 || app.indexOf("zen") !== -1 || app.indexOf("librewolf") !== -1 || app.indexOf("chrome") !== -1 || app.indexOf("chromium") !== -1 || app.indexOf("brave") !== -1 || app.indexOf("vivaldi") !== -1 || app.indexOf("browser") !== -1) return "󰈹"
    if (app.indexOf("discord") !== -1 || app.indexOf("vesktop") !== -1 || app.indexOf("webcord") !== -1) return "󰙯"
    if (app.indexOf("telegram") !== -1) return "󰔁"
    if (app.indexOf("slack") !== -1) return "󰒱"
    if (app.indexOf("signal") !== -1) return "󰍡"
    if (app.indexOf("terminal") !== -1 || app.indexOf("kitty") !== -1 || app.indexOf("foot") !== -1 || app.indexOf("alacritty") !== -1 || app.indexOf("ghostty") !== -1 || app.indexOf("wezterm") !== -1) return "󰅍"
    if (app.indexOf("code") !== -1 || app.indexOf("vscodium") !== -1 || app.indexOf("nvim") !== -1 || app.indexOf("neovim") !== -1 || app.indexOf("vim") !== -1 || app.indexOf("emacs") !== -1) return "󰨞"
    if (app.indexOf("steam") !== -1) return "󰓓"
    if (app.indexOf("mail") !== -1 || app.indexOf("thunderbird") !== -1 || app.indexOf("gearman") !== -1) return "󰇮"
    if (app.indexOf("volume") !== -1 || app.indexOf("audio") !== -1 || app.indexOf("pipewire") !== -1 || app.indexOf("wireplumber") !== -1) return "󰕾"
    if (app.indexOf("net") !== -1 || app.indexOf("wifi") !== -1 || app.indexOf("network") !== -1) return "󰤨"
    if (app.indexOf("bat") !== -1 || app.indexOf("power") !== -1 || app.indexOf("upower") !== -1) return "󰂄"
    if (app.indexOf("brightness") !== -1 || app.indexOf("backlight") !== -1) return "󰃠"
    if (app.indexOf("bluetooth") !== -1) return "󰂯"
    if (app.indexOf("obs") !== -1 || app.indexOf("screen") !== -1 || app.indexOf("shot") !== -1 || app.indexOf("grim") !== -1 || app.indexOf("slurp") !== -1) return "󰄄"
    if (app.indexOf("niri") !== -1 || app.indexOf("hyprland") !== -1 || app.indexOf("sway") !== -1 || app.indexOf("wayland") !== -1) return "󰍹"
    if (app.indexOf("package") !== -1 || app.indexOf("update") !== -1 || app.indexOf("nix") !== -1) return "󰏗"

    // Summary keyword matching fallbacks
    if (sum.indexOf("volume") !== -1 || sum.indexOf("muted") !== -1) return "󰕾"
    if (sum.indexOf("wifi") !== -1 || sum.indexOf("network") !== -1 || sum.indexOf("connected") !== -1) return "󰤨"
    if (sum.indexOf("battery") !== -1 || sum.indexOf("charging") !== -1) return "󰂄"
    if (sum.indexOf("brightness") !== -1) return "󰃠"
    if (sum.indexOf("bluetooth") !== -1) return "󰂯"
    if (sum.indexOf("screenshot") !== -1) return "󰄄"

    // Urgency level fallbacks
    if (urgency === 2) return "󰀦"

    // First letter fallback if program name / desktop entry is available
    var cleanApp = (appName || desktopEntry || "").trim()
    if (cleanApp.length > 0) {
      var match = cleanApp.match(/[a-zA-Z0-9]/)
      if (match) return match[0].toUpperCase()
    }

    return "󰂚"
  }

  // Left-side Icon/Image Container
  Item {
    id: iconContainer
    visible: root.hasIcon
    anchors.left: parent.left
    anchors.leftMargin: Config.notifCardMargins
    anchors.verticalCenter: parent.verticalCenter
    width: root.isMedia ? 48 : 40
    height: root.isMedia ? 48 : 40

    Rectangle {
      anchors.fill: parent
      radius: 8
      color: Colors.bgSubtle
      border.color: Colors.border
      border.width: 1

      // Fallback Nerd Font icon glyph or first letter
      Text {
        anchors.centerIn: parent
        text: root.fallbackGlyph
        color: root.isMedia ? Colors.fgDim : (root.urgency === 2 ? Colors.red : Colors.accent)
        font.pixelSize: (root.fallbackGlyph.length === 1) ? (root.isMedia ? 22 : 18) : (root.isMedia ? 22 : 18)
        font.bold: root.fallbackGlyph.length === 1
        font.family: (root.fallbackGlyph.length === 1) ? Config.sansFont : Config.monoFont
        visible: !img.visible
      }

      // Mask for rounded corners
      Item {
        id: iconMask
        width: parent.width
        height: parent.height
        visible: false
        layer.enabled: true
        Rectangle {
          width: parent.width
          height: parent.height
          radius: 8
          color: "black"
        }
      }

      Image {
        id: img
        anchors.fill: parent
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        source: root.iconSource
        visible: source !== "" && status === Image.Ready

        layer.enabled: true
        layer.effect: MultiEffect {
          maskEnabled: true
          maskSource: iconMask
        }
      }
    }
  }

  // Text Column
  Column {
    id: contentCol
    anchors.left: root.hasIcon ? iconContainer.right : parent.left
    anchors.leftMargin: root.hasIcon ? 10 : Config.notifCardMargins
    anchors.right: parent.right
    anchors.rightMargin: Config.notifCardMargins
    anchors.verticalCenter: parent.verticalCenter
    spacing: 2

    Text {
      width: parent.width
      text: root.isMedia ? "Now Playing" : root.summary
      color: root.isMedia ? Colors.teal : (root.urgency === 2 ? Colors.red : Colors.accent)
      font.bold: true
      font.pixelSize: root.isMedia ? 12 : 14
      font.family: Config.sansFont
      elide: Text.ElideRight
    }

    Text {
      width: parent.width
      text: root.isMedia ? root.trackTitle : root.body
      color: Colors.fg
      font.pixelSize: 14
      font.family: Config.sansFont
      elide: root.isMedia ? Text.ElideRight : Text.ElideNone
      wrapMode: root.isMedia ? Text.NoWrap : Text.Wrap
      visible: text !== ""
    }

    Text {
      width: parent.width
      text: root.trackArtist
      color: Colors.fgMid
      font.pixelSize: 12
      font.family: Config.sansFont
      elide: Text.ElideRight
      visible: root.isMedia && text !== ""
    }
  }
}