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
  property string timeStr: ""
  readonly property bool isHovered: hoverArea.containsMouse
  signal dismissed()
  signal actionTriggered()

  // Retain the notification object while this card is shown.
  RetainableLock {
    object: root.notification
    locked: Boolean(root.notification)
  }

  // --- Multi-tier Icon & Avatar Candidate Resolution ---
  property var candidateIcons: {
    var list = []

    function addCandidate(s) {
      if (!s) return
      var str = String(s).trim()
      if (str.charAt(0) === '"' && str.charAt(str.length - 1) === '"') {
        str = str.slice(1, -1).trim()
      }
      if (!str) return

      // Normalize file paths to file:// scheme for Qt Quick Image
      if (str.startsWith("/")) {
        str = "file://" + str
      }

      // If candidate is an image://icon/ URL, verify existence or check alias
      if (str.startsWith("image://icon/")) {
        var iconName = str.substring(13).split("?")[0].trim()
        if (!Quickshell.hasThemeIcon(iconName) && !Quickshell.iconPath(iconName, true)) {
          var a = (Config.notifAppIcons && Config.notifAppIcons[iconName.toLowerCase()]) ? Config.notifAppIcons[iconName.toLowerCase()] : ""
          if (a) {
            str = a.startsWith("/") ? ("file://" + a) : (Quickshell.iconPath(a, true) || ("image://icon/" + a))
          } else {
            return // Skip invalid icon name so Quickshell doesn't throw a warning
          }
        }
      }

      // If candidate is a theme icon name without URL scheme
      if (!str.startsWith("file://") && !str.startsWith("http://") && !str.startsWith("https://") && !str.startsWith("image://")) {
        var clean = str.replace(/\.(png|svg|xpm|ico)$/i, "")
        // Check Config.notifAppIcons alias first
        var alias = (Config.notifAppIcons && Config.notifAppIcons[clean.toLowerCase()]) ? Config.notifAppIcons[clean.toLowerCase()] : ""
        if (alias) {
          if (alias.startsWith("/") || alias.startsWith("file://") || alias.startsWith("image://")) {
            str = alias.startsWith("/") ? ("file://" + alias) : alias
          } else {
            var aliasPath = Quickshell.iconPath(alias, true)
            str = aliasPath ? aliasPath : (Quickshell.hasThemeIcon(alias) ? ("image://icon/" + alias) : "")
          }
        } else {
          var path = Quickshell.iconPath(clean, true)
          if (path) {
            str = path
          } else if (Quickshell.hasThemeIcon(clean)) {
            str = "image://icon/" + clean
          } else {
            return // Skip nonexistent icon
          }
        }
      }

      if (str && str !== "" && list.indexOf(str) === -1) {
        list.push(str)
      }
    }

    // --- Tier 1: Explicit notification image / avatar / cover art ---
    if (root.image) {
      addCandidate(root.image)
    }

    if (root.isMedia) {
      var cachedArt = NotificationStore.getCoverArt(
        root.trackTitle || (NotificationStore.mediaPlayer ? NotificationStore.mediaPlayer.trackTitle : ""),
        root.trackArtist || (NotificationStore.mediaPlayer ? NotificationStore.mediaPlayer.trackArtist : ""),
        root.image || (NotificationStore.mediaPlayer ? NotificationStore.mediaPlayer.trackArtUrl : "")
      )
      addCandidate(cachedArt)
      if (NotificationStore.mediaPlayer && NotificationStore.mediaPlayer.trackArtUrl) {
        addCandidate(NotificationStore.mediaPlayer.trackArtUrl)
      }
      if (NotificationStore.latestMediaImage) {
        addCandidate(NotificationStore.latestMediaImage)
      }
    }

    // --- Tier 2: Configured App Fallback Icons (from Config.notifAppIcons) ---
    var keysToTry = [
      (root.desktopEntry || "").toLowerCase().replace(/\.desktop$/, "").trim(),
      (root.appName || "").toLowerCase().trim(),
      (root.appIcon || "").toLowerCase().replace(/\.(png|svg|xpm|ico)$/i, "").trim()
    ]
    for (var k = 0; k < keysToTry.length; k++) {
      var key = keysToTry[k]
      if (key && Config.notifAppIcons && Config.notifAppIcons[key]) {
        addCandidate(Config.notifAppIcons[key])
      }
    }

    // --- Tier 3: Explicit appIcon from notification ---
    if (root.appIcon) {
      addCandidate(root.appIcon)
    }

    // --- Tier 4: Desktop entry name ---
    if (root.desktopEntry) {
      var de = String(root.desktopEntry).trim()
      if (de.endsWith(".desktop")) de = de.substring(0, de.length - 8)
      addCandidate(de)
      var deParts = de.split(".")
      if (deParts.length > 1) {
        addCandidate(deParts[deParts.length - 1])
      }
    }

    // --- Tier 5: App name ---
    if (root.appName) {
      var an = String(root.appName).trim().toLowerCase()
      addCandidate(an)
      addCandidate(an.replace(/\s+/g, "-"))
    }

    // --- Tier 6: Configured global default fallback logo ---
    if (Config.notifDefaultFallbackLogo) {
      addCandidate(Config.notifDefaultFallbackLogo)
    }

    return list
  }

  // Sequential candidate fallback: if candidate 0 (avatar) fails or errors, try candidate 1 (app logo), etc.
  property int candidateIndex: 0
  readonly property string currentCandidate: (candidateIndex >= 0 && candidateIndex < candidateIcons.length) ? candidateIcons[candidateIndex] : ""

  onCandidateIconsChanged: {
    candidateIndex = 0
  }

  function nextCandidate() {
    if (candidateIndex + 1 < candidateIcons.length) {
      candidateIndex++
    } else {
      candidateIndex = candidateIcons.length
    }
  }

  property bool hasIcon: true

  readonly property int targetIconSize: isMedia ? (Config.notifMediaIconSize || 48) : (Config.notifIconSize || 40)
  readonly property int targetIconRadius: Config.notifIconRadius || 8

  width: parent ? parent.width : Config.notifWidth
  height: Math.max(contentCol.implicitHeight, hasIcon ? targetIconSize : 0) + Config.notifCardMargins * 2
  radius: Config.notifRadius

  color: hoverArea.containsMouse ? Colors.bgRaised : Colors.bg
  border.color: hoverArea.containsMouse
    ? (isMedia ? Colors.teal : (urgency === 2 ? Colors.red : Colors.accent))
    : (urgency === 2 ? Colors.red : Colors.border)
  border.width: 1

  scale: hoverArea.containsMouse ? (hoverArea.pressed ? 0.98 : 1.01) : 1.0

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
        if (Config.notifLeftClickAction === "focus") {
          root.actionTriggered()
        } else {
          root.dismissed()
        }
      }
    }
  }

  // Correlated fallback icon glyph based on Config.notifAppGlyphs
  property string fallbackGlyph: {
    if (isMedia) return "󰎈"

    var app = (appName || desktopEntry || appIcon || "").toLowerCase().trim()
    var sum = (summary || "").toLowerCase().trim()

    // 1. Check Config.notifAppGlyphs
    if (Config.notifAppGlyphs) {
      for (var key in Config.notifAppGlyphs) {
        if (app.indexOf(key) !== -1 || sum.indexOf(key) !== -1) {
          return Config.notifAppGlyphs[key]
        }
      }
    }

    // 2. Urgency level fallbacks
    if (urgency === 2) return "󰀦"

    // 3. First letter fallback if program name / desktop entry is available
    var cleanApp = (appName || desktopEntry || appIcon || summary || "").trim()
    if (cleanApp.length > 0) {
      var match = cleanApp.match(/[a-zA-Z0-9]/)
      if (match) return match[0].toUpperCase()
    }

    return Config.notifDefaultFallbackGlyph || "󰂚"
  }

  // Left-side Icon/Image Container
  Item {
    id: iconContainer
    visible: root.hasIcon
    anchors.left: parent.left
    anchors.leftMargin: Config.notifCardMargins
    anchors.top: parent.top
    anchors.topMargin: Config.notifCardMargins
    width: root.targetIconSize
    height: root.targetIconSize

    Rectangle {
      anchors.fill: parent
      radius: root.targetIconRadius
      color: Colors.bgSubtle
      border.color: Colors.border
      border.width: 1

      // Fallback Nerd Font icon glyph or first letter
      Text {
        anchors.centerIn: parent
        text: root.fallbackGlyph
        color: root.isMedia ? Colors.fgDim : (root.urgency === 2 ? Colors.red : Colors.accent)
        font.pixelSize: (root.fallbackGlyph.length === 1) ? 18 : 20
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
        layer.enabled: img.visible
        Rectangle {
          width: parent.width
          height: parent.height
          radius: root.targetIconRadius
          color: "black"
        }
      }

      Image {
        id: img
        anchors.fill: parent
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.targetIconSize * 2, root.targetIconSize * 2)
        source: root.currentCandidate
        visible: source !== "" && status === Image.Ready

        onStatusChanged: {
          if (status === Image.Error) {
            root.nextCandidate()
          }
        }

        layer.enabled: img.visible
        layer.effect: MultiEffect {
          maskEnabled: true
          maskSource: iconMask
        }
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: root.actionTriggered()
      }
    }
  }

  // Text and Actions Column
  Column {
    id: contentCol
    anchors.left: root.hasIcon ? iconContainer.right : parent.left
    anchors.leftMargin: root.hasIcon ? 10 : Config.notifCardMargins
    anchors.right: parent.right
    anchors.rightMargin: Config.notifCardMargins
    anchors.top: parent.top
    anchors.topMargin: Config.notifCardMargins
    spacing: 3

    // Header row: Title / Summary + Timestamp
    Row {
      width: parent.width
      spacing: 6

      Text {
        width: timeLabel.visible ? (parent.width - timeLabel.implicitWidth - 6) : parent.width
        text: root.isMedia ? "Now Playing" : root.summary
        color: root.isMedia ? Colors.teal : (root.urgency === 2 ? Colors.red : Colors.accent)
        font.bold: true
        font.pixelSize: root.isMedia ? 12 : 13
        font.family: Config.sansFont
        elide: Text.ElideRight
      }

      Text {
        id: timeLabel
        text: root.timeStr
        color: Colors.fgDim
        font.pixelSize: 11
        font.family: Config.sansFont
        visible: root.timeStr !== ""
      }
    }

    // Body Text
    Text {
      width: parent.width
      text: root.isMedia ? root.trackTitle : root.body
      color: Colors.fg
      font.pixelSize: 13
      font.family: Config.sansFont
      maximumLineCount: root.isMedia ? 1 : (Config.notifMaxLines || 5)
      elide: Text.ElideRight
      wrapMode: root.isMedia ? Text.NoWrap : Text.Wrap
      visible: text !== ""
    }

    // Media Artist Subtext
    Text {
      width: parent.width
      text: root.trackArtist
      color: Colors.fgMid
      font.pixelSize: 12
      font.family: Config.sansFont
      elide: Text.ElideRight
      visible: root.isMedia && text !== ""
    }

    // Action Buttons Row (if notification has actions and Config.notifShowActions is enabled)
    Row {
      id: actionsRow
      spacing: 6
      visible: Config.notifShowActions && actionsRepeater.count > 0

      Repeater {
        id: actionsRepeater
        model: (root.notification && root.notification.actions) ? root.notification.actions : []
        delegate: Rectangle {
          id: actionBtn
          visible: modelData.identifier !== "default"
          height: 24
          radius: 6
          implicitWidth: actionText.implicitWidth + 16
          color: actionHover.containsMouse ? Colors.bgRaised : Colors.bgSubtle
          border.color: actionHover.containsMouse ? Colors.accent : Colors.border
          border.width: 1

          Text {
            id: actionText
            anchors.centerIn: parent
            text: modelData.text || modelData.identifier
            font.pixelSize: 11
            font.bold: true
            font.family: Config.sansFont
            color: actionHover.containsMouse ? Colors.accent : Colors.fgMid
          }

          MouseArea {
            id: actionHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              try {
                modelData.invoke()
              } catch(e) {}
              if (Config.notifDismissOnAction && root.notification && !root.notification.resident) {
                root.dismissed()
              }
            }
          }
        }
      }
    }
  }

  // Quick Dismiss 'X' Button on Card Hover
  Rectangle {
    id: closeBtn
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.margins: 6
    width: 20
    height: 20
    radius: 10
    color: closeHover.containsMouse ? Colors.bgSubtle : "transparent"
    visible: root.isHovered

    Text {
      anchors.centerIn: parent
      text: "󰅖"
      font.pixelSize: 11
      font.family: Config.monoFont
      color: closeHover.containsMouse ? Colors.red : Colors.fgDim
    }

    MouseArea {
      id: closeHover
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.dismissed()
    }
  }
}
