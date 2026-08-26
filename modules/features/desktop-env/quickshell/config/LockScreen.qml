import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import Quickshell.Networking
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "Utils.js" as Utils

Scope {
  id: lockScope

  property bool active: false
  property bool authenticating: false
  property string errorMessage: ""
  property int shakeTrigger: 0
  property string pendingPassword: ""

  // Expose lock/unlock via IPC at Scope level so target exists when unlocked
  IpcHandler {
    target: "lockscreen"

    function lock(): void {
      lockScope.active = true
    }

    function unlock(): void {
      lockScope.unlockSession()
    }

    function toggle(): void {
      if (lockScope.active) {
        lockScope.unlockSession()
      } else {
        lockScope.active = true
      }
    }
  }

  function unlockSession(): void {
    if (lockLoader.item && lockLoader.item.locked) {
      lockLoader.item.locked = false
    } else {
      lockScope.active = false
    }
  }

  // Single PAM Service Context for the lock session across all screens
  PamContext {
    id: pam
    config: "login"
    user: Quickshell.env("USER") || ""

    onResponseRequiredChanged: {
      if (responseRequired && lockScope.pendingPassword.length > 0) {
        respond(lockScope.pendingPassword)
        lockScope.pendingPassword = ""
      }
    }

    onCompleted: function(result) {
      lockScope.authenticating = false
      lockScope.pendingPassword = ""
      if (result === PamResult.Success) {
        lockScope.errorMessage = ""
        lockScope.unlockSession()
      } else {
        lockScope.errorMessage = "Authentication failed. Try again."
        lockScope.shakeTrigger++
        pam.start()
      }
    }

    onError: function(err) {
      lockScope.authenticating = false
      lockScope.pendingPassword = ""
      lockScope.errorMessage = "PAM Error"
      lockScope.shakeTrigger++
      pam.start()
    }
  }

  function submitPassword(password) {
    if (!password || lockScope.authenticating) return
    lockScope.authenticating = true
    lockScope.errorMessage = ""

    if (pam.responseRequired) {
      pam.respond(password)
    } else {
      lockScope.pendingPassword = password
      if (!pam.active) {
        pam.start()
      }
    }
  }

  Loader {
    id: lockLoader
    active: lockScope.active
    sourceComponent: lockComponent
    onActiveChanged: {
      if (lockLoader.active) {
        lockScope.errorMessage = ""
        lockScope.authenticating = false
        lockScope.pendingPassword = ""
        pam.start()
      }
    }
  }

  Component {
    id: lockComponent

    WlSessionLock {
      id: lockRoot
      locked: true

      WlSessionLockSurface {
        id: surface
        color: Colors.bg

        Connections {
          target: lockRoot
          function onLockedChanged() {
            if (!lockRoot.locked) {
              lockScope.active = false
            }
          }
        }

        readonly property bool authenticating: lockScope.authenticating
        readonly property string errorMessage: lockScope.errorMessage
        property real shakeOffset: 0
        property bool capsLockOn: false

        // Check if this screen is the main interactive screen (first screen in list)
        property bool isPrimaryScreen: surface.screen === undefined || surface.screen === Quickshell.screens[0]

        Component.onCompleted: {
          if (surface.isPrimaryScreen) {
            mainBg.forceActiveFocus()
          }
        }

        Connections {
          target: lockScope
          function onShakeTriggerChanged() {
            if (surface.isPrimaryScreen) {
              passInput.text = ""
              shakeAnimation.start()
              mainBg.forceActiveFocus()
            }
          }
        }

        // Shake animation for error feedback
        SequentialAnimation {
          id: shakeAnimation
          NumberAnimation { target: surface; property: "shakeOffset"; to: -12; duration: 50; easing.type: Easing.OutQuad }
          NumberAnimation { target: surface; property: "shakeOffset"; to: 12; duration: 50; easing.type: Easing.OutQuad }
          NumberAnimation { target: surface; property: "shakeOffset"; to: -8; duration: 50; easing.type: Easing.OutQuad }
          NumberAnimation { target: surface; property: "shakeOffset"; to: 8; duration: 50; easing.type: Easing.OutQuad }
          NumberAnimation { target: surface; property: "shakeOffset"; to: -4; duration: 50; easing.type: Easing.OutQuad }
          NumberAnimation { target: surface; property: "shakeOffset"; to: 0; duration: 50; easing.type: Easing.OutQuad }
        }

        // Main background layer
        Rectangle {
          id: mainBg
          anchors.fill: parent
          color: Colors.bg
          focus: true

          Keys.onPressed: function(event) {
            surface.capsLockOn = (event.modifiers & Qt.CapsLockModifier) !== 0

            if (event.key === Qt.Key_Escape) {
              passInput.focus = false
              mainBg.forceActiveFocus()
              event.accepted = true
              return
            }

            if (!passInput.activeFocus) {
              // Ignore alone modifier keys or tabs
              if (event.key === Qt.Key_Shift || event.key === Qt.Key_Control ||
                  event.key === Qt.Key_Alt || event.key === Qt.Key_Meta ||
                  event.key === Qt.Key_CapsLock || event.key === Qt.Key_Tab ||
                  event.key === Qt.Key_Backtab) {
                return
              }

              passInput.forceActiveFocus()
              if (event.text && event.text.length > 0) {
                if (event.key !== Qt.Key_Backspace && event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Delete) {
                  passInput.text += event.text
                }
                event.accepted = true
              }
            }
          }

          // Wallpaper background layer (configurable via Config.lockWallpaperPath)
          Image {
            id: lockBgImage
            anchors.fill: parent
            source: Config.lockWallpaperPath
            fillMode: Image.PreserveAspectCrop
            smooth: true

            layer.enabled: Config.lockBlurPercentage > 0
            layer.effect: MultiEffect {
              blurEnabled: Config.lockBlurPercentage > 0
              blur: Config.lockBlurPercentage
              blurMax: 64
            }

            // Translucent dark overlay to elevate UI contrast (configurable via Config.lockBackgroundDimming)
            Rectangle {
              anchors.fill: parent
              color: "black"
              opacity: Config.lockBackgroundDimming
            }
          }

          // Global click handler to clear text field focus when clicking outside
          MouseArea {
            anchors.fill: parent
            onClicked: mainBg.forceActiveFocus()
          }

          // Bottom Left Wi-Fi / Network Status (Text & Icon, No Background)
          Row {
            visible: surface.isPrimaryScreen
            anchors.left: mainBg.left
            anchors.bottom: mainBg.bottom
            anchors.margins: 24
            spacing: 8
            z: 10

            property var wiredDev: Utils.findFirst(Networking.devices.values, function(d) { return d.type === DeviceType.Wired })
            property var wifiDev: Utils.findFirst(Networking.devices.values, function(d) { return d.type === DeviceType.Wifi && d.connected }) || Utils.findFirst(Networking.devices.values, function(d) { return d.type === DeviceType.Wifi })
            property bool isWired: wiredDev && wiredDev.connected
            property bool isWifi: wifiDev && wifiDev.connected
            property var wifiNet: Utils.findFirst(wifiDev ? wifiDev.networks.values : [], function(n) { return n.connected })
            property string wifiSsid: wifiNet ? wifiNet.name : ""

            property string netIcon: {
              if (isWired) return "󰈀"
              if (isWifi) return "󰤨"
              return "󰤮"
            }

            property string netText: {
              if (isWired) return "Ethernet"
              if (isWifi) return wifiSsid !== "" ? wifiSsid : "Wi-Fi"
              return "Offline"
            }

            property color netColor: (isWired || isWifi) ? Colors.accent : Colors.fgDim

            Text {
              text: parent.netIcon
              color: parent.netColor
              font.family: Config.monoFont
              font.pixelSize: 16
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              text: parent.netText
              color: Colors.fgMid
              font.family: Config.sansFont
              font.pixelSize: 13
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          // Bottom Right Battery Status (Text & Icon, No Background)
          Row {
            visible: surface.isPrimaryScreen && batPresent
            anchors.right: mainBg.right
            anchors.bottom: mainBg.bottom
            anchors.margins: 24
            spacing: 8
            z: 10

            property var batDevice: Utils.findBatteryDevice(UPower.devices, UPower.displayDevice)
            readonly property bool batPresent: batDevice !== null && batDevice.isLaptopBattery
            readonly property int batPct: batDevice ? Math.round(batDevice.percentage * 100) : 0
            readonly property bool batCharging: batDevice && batDevice.state === UPowerDeviceState.Charging
            readonly property bool batPlugged: batDevice && batDevice.state === UPowerDeviceState.FullyCharged

            property string batIcon: Utils.batteryIcon(batPct, batCharging, batPlugged, batPresent)
            property color batColor: {
              if (!batPresent) return Colors.fgMid
              if (batCharging || batPlugged) return Colors.green
              if (batPct <= 15) return Colors.red
              if (batPct <= 30) return Colors.yellow
              return Colors.fgMid
            }

            Text {
              text: parent.batIcon
              color: parent.batColor
              font.family: Config.monoFont
              font.pixelSize: 16
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              text: parent.batPct + "%"
              color: parent.batColor
              font.family: Config.sansFont
              font.pixelSize: 13
              font.bold: true
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          // Primary Interactive Screen Content
          ColumnLayout {
            visible: surface.isPrimaryScreen

            anchors.centerIn: parent
            width: Math.min(parent.width - 40, 440)
            spacing: 24

            // --- TIME & DATE HEADER ---
            Column {
              Layout.alignment: Qt.AlignHCenter
              spacing: 4

              Text {
                id: clockText
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(new Date(), Config.lockClockFormat)
                color: Colors.fg
                font.family: Config.serifFont
                font.pixelSize: 72
                font.italic: true
                font.letterSpacing: 1

                function updateTime() {
                  var d = new Date()
                  clockText.text = Qt.formatDateTime(d, Config.lockClockFormat)
                  clockTimer.interval = 60000 - (d.getSeconds() * 1000 + d.getMilliseconds())
                  clockTimer.restart()
                }

                Timer {
                  id: clockTimer
                  running: lockRoot.locked
                  repeat: false
                  onTriggered: clockText.updateTime()
                }

                Component.onCompleted: updateTime()
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(new Date(), Config.lockDateFormat)
                color: Colors.fgMid
                font.family: Config.sansFont
                font.pixelSize: 16
              }
            }

            // --- MEDIA PLAYER CARD (Taller, play/pause only, non-interactive position bar) ---
            Rectangle {
              id: lockMediaCard
              Layout.fillWidth: true
              implicitHeight: lockMediaCol.implicitHeight + 28
              color: Colors.bgRaised
              border.color: Colors.border
              border.width: 1
              radius: Config.commandCenterCardRadius
              visible: !!activePlayer && (activePlayer.isPlaying || (activePlayer.trackTitle !== undefined && activePlayer.trackTitle !== ""))

              property var mediaPlayers: Mpris.players.values
              property var activePlayer: Utils.findActivePlayer(lockMediaCard.mediaPlayers, MprisPlaybackState.Paused)

              MediaProgress {
                id: lockMediaTracker
                player: lockMediaCard.activePlayer
              }

              Column {
                id: lockMediaCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 10

                RowLayout {
                  width: parent.width
                  spacing: 12

                  // Track Art / Icon
                  Rectangle {
                    width: 44
                    height: 44
                    radius: 8
                    color: Colors.bgSubtle
                    border.color: Colors.border
                    border.width: 1

                    Text {
                      visible: !coverArt.visible
                      text: "󰎇"
                      color: Colors.fgDim
                      font.family: Config.monoFont
                      font.pixelSize: 20
                      anchors.centerIn: parent
                    }

                    Item {
                      id: coverArtMask
                      anchors.fill: parent
                      visible: false
                      layer.enabled: true
                      Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: "black"
                      }
                    }

                    Image {
                      id: coverArt
                      anchors.fill: parent
                      asynchronous: true
                      fillMode: Image.PreserveAspectCrop
                      visible: source !== "" && status === Image.Ready
                      source: (lockMediaCard.activePlayer && (lockMediaCard.activePlayer.trackTitle || lockMediaCard.activePlayer.trackArtUrl)) ? NotificationStore.getCoverArt(
                        lockMediaCard.activePlayer.trackTitle || "",
                        lockMediaCard.activePlayer.trackArtist || "",
                        lockMediaCard.activePlayer.trackArtUrl || ""
                      ) : ""

                      layer.enabled: true
                      layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: coverArtMask
                      }
                    }
                  }

                  // Track Info
                  Column {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                      width: parent.width
                      text: lockMediaCard.activePlayer ? Utils.cleanTrackTitle(lockMediaCard.activePlayer.trackTitle) : ""
                      color: Colors.fg
                      font.bold: true
                      font.pixelSize: 15
                      font.family: Config.sansFont
                      elide: Text.ElideRight
                    }

                    Text {
                      width: parent.width
                      text: lockMediaCard.activePlayer ? (lockMediaCard.activePlayer.trackArtist || "Unknown Artist") : ""
                      color: Colors.fgMid
                      font.pixelSize: 13
                      font.family: Config.sansFont
                      elide: Text.ElideRight
                    }
                  }

                  // Play/Pause Button (ONLY Play/Pause)
                  Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: lockPlayHover.containsMouse ? Colors.accent : Colors.bgSubtle
                    border.color: Colors.border
                    border.width: 1
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    Text {
                      anchors.centerIn: parent
                      text: (lockMediaCard.activePlayer && lockMediaCard.activePlayer.isPlaying) ? "󰏤" : "󰐊"
                      color: lockPlayHover.containsMouse ? Colors.bg : Colors.fg
                      font.family: Config.monoFont
                      font.pixelSize: 16
                    }

                    MouseArea {
                      id: lockPlayHover
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onEntered: parent.scale = 0.90
                      onExited: parent.scale = 1.0
                      onClicked: {
                        if (lockMediaCard.activePlayer) {
                          lockMediaCard.activePlayer.isPlaying = !lockMediaCard.activePlayer.isPlaying
                        }
                      }
                    }
                  }
                }

                // Non-interactive progress bar & position numbers
                RowLayout {
                  width: parent.width
                  spacing: 8
                  visible: lockMediaTracker.lastLength > 0

                  Text {
                    text: Utils.formatTime(Math.round(lockMediaTracker.estimatedPosition))
                    color: Colors.fgDim
                    font.family: Config.sansFont
                    font.pixelSize: 12
                    Layout.preferredWidth: 38
                    horizontalAlignment: Text.AlignRight
                  }

                  SliderControl {
                    Layout.fillWidth: true
                    value: lockMediaTracker.progress
                    fillColor: Colors.accent
                    enabled: false // Non-interactive: playback position cannot be dragged or clicked
                  }

                  Text {
                    text: Utils.formatTime(Math.round(lockMediaTracker.lastLength))
                    color: Colors.fgDim
                    font.family: Config.sansFont
                    font.pixelSize: 12
                    Layout.preferredWidth: 38
                  }
                }
              }
            }

            // --- USER & AUTHENTICATION CARD ---
            Rectangle {
              Layout.fillWidth: true
              implicitHeight: authCol.implicitHeight + 36
              color: Colors.bgRaised
              border.color: surface.errorMessage !== "" ? Colors.red : Colors.border
              border.width: 1
              radius: Config.commandCenterCardRadius

              transform: Translate {
                x: surface.shakeOffset
              }

              Behavior on border.color { ColorAnimation { duration: 150 } }

              ColumnLayout {
                id: authCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 20
                spacing: 16

                // Avatar & Username Header
                ColumnLayout {
                  Layout.alignment: Qt.AlignHCenter
                  spacing: 8

                  // Avatar Box (supports custom image with fallback icon)
                  Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 64
                    height: 64
                    radius: Config.commandCenterCardRadius
                    color: Colors.bgSubtle
                    border.color: Colors.border
                    border.width: 1

                    // Fallback Icon
                    Text {
                      anchors.centerIn: parent
                      text: Config.lockFallbackIcon
                      color: Colors.accent
                      font.family: Config.monoFont
                      font.pixelSize: 32
                      visible: !avatarImage.visible || avatarImage.status === Image.Error
                    }

                    // Mask for rounded corners on avatar image
                    Item {
                      id: avatarMask
                      anchors.fill: parent
                      visible: false
                      layer.enabled: true
                      Rectangle {
                        anchors.fill: parent
                        radius: Config.commandCenterCardRadius
                        color: "black"
                      }
                    }

                    // Avatar Image (loaded from Config.lockAvatarPath)
                    Image {
                      id: avatarImage
                      anchors.fill: parent
                      source: Config.lockAvatarPath
                      fillMode: Image.PreserveAspectCrop
                      smooth: true
                      visible: status === Image.Ready

                      layer.enabled: true
                      layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: avatarMask
                      }
                    }
                  }

                  // Username Text
                  Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Quickshell.env("USER") || "User"
                    color: Colors.fg
                    font.family: Config.sansFont
                    font.pixelSize: 20
                    font.bold: true
                  }

                  // Status / Error Subtitle
                  Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: surface.errorMessage !== "" ? surface.errorMessage : (surface.authenticating ? "Authenticating..." : "System Locked")
                    color: surface.errorMessage !== "" ? Colors.red : (surface.authenticating ? Colors.accent : Colors.fgDim)
                    font.family: Config.sansFont
                    font.pixelSize: 14
                  }
                }

                // Password Input Pill Box Container
                Rectangle {
                  id: inputCard
                  Layout.fillWidth: true
                  height: 48
                  radius: Config.lockInputRadius
                  color: Colors.bgSubtle
                  border.color: passInput.activeFocus ? Colors.accent : Colors.border
                  border.width: passInput.activeFocus ? 2 : 1

                  Behavior on border.color { ColorAnimation { duration: 150 } }

                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 8
                    spacing: 10

                    // Lock / Auth Icon
                    Text {
                      text: surface.authenticating ? "󱎟" : "󰌾"
                      color: passInput.activeFocus ? Colors.accent : Colors.fgDim
                      font.family: Config.monoFont
                      font.pixelSize: 18
                      Layout.alignment: Qt.AlignVCenter
                    }

                    // Password Input Field
                    TextInput {
                      id: passInput
                      Layout.fillWidth: true
                      Layout.alignment: Qt.AlignVCenter
                      echoMode: TextInput.Password
                      color: Colors.fg
                      font.family: Config.sansFont
                      font.pixelSize: 16
                      clip: true
                      focus: false
                      enabled: !surface.authenticating

                      onTextChanged: {
                        if (passInput.text.length > 0 && surface.errorMessage !== "") {
                          surface.errorMessage = ""
                        }
                      }

                      Keys.onPressed: function(event) {
                        surface.capsLockOn = (event.modifiers & Qt.CapsLockModifier) !== 0
                        if (event.key === Qt.Key_Escape) {
                          passInput.focus = false
                          mainBg.forceActiveFocus()
                          event.accepted = true
                        }
                      }

                      Text {
                        text: "Enter password..."
                        color: Colors.fgDim
                        font.family: Config.sansFont
                        font.pixelSize: 16
                        visible: passInput.text.length === 0 && !passInput.activeFocus
                      }

                      onAccepted: {
                        if (passInput.text.length > 0 && !surface.authenticating) {
                          lockScope.submitPassword(passInput.text)
                          passInput.text = ""
                        }
                      }
                    }

                    // Submit Button Pill
                    Rectangle {
                      id: submitBtn
                      Layout.preferredWidth: 32
                      Layout.preferredHeight: 32
                      Layout.alignment: Qt.AlignVCenter
                      radius: 8
                      color: submitHover.containsMouse ? Colors.accent : Colors.bgRaised
                      border.color: Colors.border
                      border.width: 1

                      Behavior on scale { NumberAnimation { duration: 100 } }

                      Text {
                        anchors.centerIn: parent
                        text: "󰁔"
                        color: submitHover.containsMouse ? Colors.bg : Colors.fg
                        font.family: Config.monoFont
                        font.pixelSize: 16
                      }

                      MouseArea {
                        id: submitHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.scale = 0.92
                        onExited: parent.scale = 1.0
                        onClicked: {
                          if (passInput.text.length > 0 && !surface.authenticating) {
                            passInput.accepted()
                          }
                        }
                      }
                    }
                  }

                  // Click inside card focuses text input
                  MouseArea {
                    anchors.fill: parent
                    anchors.rightMargin: 40
                    onClicked: passInput.forceActiveFocus()
                  }
                }

                // Caps Lock Warning Pill Badge
                Pill {
                  visible: surface.capsLockOn
                  Layout.alignment: Qt.AlignHCenter
                  pillColor: Colors.bgSubtle
                  border.color: Colors.yellow
                  padding: 8

                  Row {
                    spacing: 6

                    Text {
                      text: "󰌎"
                      color: Colors.yellow
                      font.family: Config.monoFont
                      font.pixelSize: 14
                      anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                      text: "Caps Lock is active"
                      color: Colors.yellow
                      font.family: Config.sansFont
                      font.pixelSize: 13
                      anchors.verticalCenter: parent.verticalCenter
                    }
                  }
                }
              }
            }

            // --- BOTTOM SYSTEM POWER CONTROLS ---
            RowLayout {
              id: sysControlsRow
              Layout.fillWidth: true
              spacing: 10

              property var buttonModel: [
                { icon: "󰤄", label: "Suspend", cmd: ["systemctl", "suspend"], hoverCol: Colors.accent },
                { icon: "󰜉", label: "Reboot", cmd: ["systemctl", "reboot"], hoverCol: Colors.orange },
                { icon: "󰐥", label: "Power", cmd: ["systemctl", "poweroff"], hoverCol: Colors.red }
              ]

              Repeater {
                model: sysControlsRow.buttonModel
                delegate: Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredWidth: 1
                  height: 48
                  radius: Config.lockInputRadius
                  color: hoverArea.containsMouse ? Colors.bgSubtle : Colors.bgRaised
                  border.color: hoverArea.containsMouse ? modelData.hoverCol : Colors.border
                  border.width: 1

                  Behavior on scale { NumberAnimation { duration: 100 } }

                  MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: parent.scale = 0.94
                    onExited: parent.scale = 1.0
                    onClicked: Quickshell.execDetached(modelData.cmd)
                  }

                  Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                      text: modelData.icon
                      color: hoverArea.containsMouse ? modelData.hoverCol : Colors.fg
                      font.family: Config.monoFont
                      font.pixelSize: 18
                      anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                      text: modelData.label
                      color: hoverArea.containsMouse ? Colors.fg : Colors.fgMid
                      font.family: Config.sansFont
                      font.pixelSize: 13
                      anchors.verticalCenter: parent.verticalCenter
                    }
                  }
                }
              }
            }
          }

          // Secondary Display Screen Content (Non-interactive display for multi-monitors)
          Column {
            visible: !surface.isPrimaryScreen

            anchors.centerIn: parent
            spacing: 20

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: Qt.formatDateTime(new Date(), Config.lockClockFormat)
              color: Colors.fg
              font.family: Config.serifFont
              font.pixelSize: 72
              font.italic: true
              font.letterSpacing: 1
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: Qt.formatDateTime(new Date(), Config.lockDateFormat)
              color: Colors.fgMid
              font.family: Config.sansFont
              font.pixelSize: 18
            }

            Pill {
              anchors.horizontalCenter: parent.horizontalCenter
              pillColor: Colors.bgRaised
              border.color: Colors.border
              padding: 10

              Row {
                spacing: 8

                Text {
                  text: "󰌾"
                  color: Colors.accent
                  font.family: Config.monoFont
                  font.pixelSize: 16
                  anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                  text: "Locked"
                  color: Colors.fgDim
                  font.family: Config.sansFont
                  font.pixelSize: 15
                  anchors.verticalCenter: parent.verticalCenter
                }
              }
            }
          }
        }
      }
    }
  }
}
