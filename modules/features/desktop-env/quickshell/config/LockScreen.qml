pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
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
  property string enteredPassword: ""
  // Guards against a tight start→fail→start loop if PAM keeps erroring without
  // user input. Reset on every user-initiated submit and on a successful unlock.
  property int _authRestarts: 0
  readonly property int _maxAuthRestarts: 5

  // Expose lock/unlock via IPC at Scope level so target exists when unlocked
  IpcHandler {
    target: "lockscreen"

    function lock(): void {
      if (!lockScope.active) {
        lockScope.active = true
      } else if (lockLoader.item && !lockLoader.item.locked) {
        // If active remained true while already unlocked, force a clean component reload
        lockScope.active = false
        Qt.callLater(function() {
          lockScope.active = true
        })
      }
    }

    function unlock(): void {
      lockScope.unlockSession()
    }

    function toggle(): void {
      if (lockScope.active && lockLoader.item && lockLoader.item.locked) {
        lockScope.unlockSession()
      } else {
        lockScope.active = false
        Qt.callLater(function() {
          lockScope.active = true
        })
      }
    }
  }

  function unlockSession(): void {
    if (lockLoader.item && lockLoader.item.locked) {
      lockLoader.item.locked = false
    }
    // Defer unloading the Loader by one event tick so WlSessionLock can cleanly
    // flush the unlock_and_destroy protocol request before its surfaces and QML item are destroyed.
    Qt.callLater(function() {
      lockScope.active = false
    })
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
      lockScope.enteredPassword = ""
      if (result === PamResult.Success) {
        lockScope._authRestarts = 0
        lockScope.errorMessage = ""
        lockScope.unlockSession()
      } else if (lockScope._authRestarts < lockScope._maxAuthRestarts) {
        lockScope._authRestarts++
        lockScope.errorMessage = "Authentication failed. Try again."
        lockScope.shakeTrigger++
        pam.start()
      } else {
        lockScope.errorMessage = "Authentication unavailable. Try again later."
        lockScope.shakeTrigger++
      }
    }

    onError: function(err) {
      lockScope.authenticating = false
      lockScope.pendingPassword = ""
      lockScope.enteredPassword = ""
      lockScope.shakeTrigger++
      if (lockScope._authRestarts < lockScope._maxAuthRestarts) {
        lockScope._authRestarts++
        lockScope.errorMessage = "PAM error. Retrying..."
        pam.start()
      } else {
        lockScope.errorMessage = "Authentication unavailable. Try again later."
      }
    }
  }

  function submitPassword(password) {
    if (!password || lockScope.authenticating) return
    lockScope._authRestarts = 0
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
      MediaService.lockActive = lockLoader.active
      if (lockLoader.active) {
        lockScope._authRestarts = 0
        lockScope.errorMessage = ""
        lockScope.authenticating = false
        lockScope.pendingPassword = ""
        lockScope.enteredPassword = ""
        pam.start()
      } else {
        if (pam.active) {
          pam.abort()
        }
        Qt.callLater(gc)
      }
    }
  }

  Component {
    id: lockComponent

    WlSessionLock {
      id: lockRoot
      locked: true
      onLockStateChanged: {
        if (!locked) {
          lockScope.active = false
        }
      }

      WlSessionLockSurface {
        id: surface
        color: Colours.bg

        readonly property bool authenticating: lockScope.authenticating
        readonly property string errorMessage: lockScope.errorMessage
        property real shakeOffset: 0
        property bool capsLockOn: false
        property bool revealPassword: false
        readonly property bool isStatusSplit: Config.lockStatusPosition === "split" || Config.lockStatusPosition === "corners"

        // Check if this screen is the main interactive screen (first screen in list)
        property bool isPrimaryScreen: surface.screen === undefined || surface.screen === Quickshell.screens[0]

        readonly property string currentTimeStr: ClockService.lockTimeStr
        readonly property string currentDateStr: ClockService.lockDateStr

        Component.onCompleted: {
          if (surface.isPrimaryScreen) {
            mainBg.forceActiveFocus()
          }
        }

        Connections {
          target: lockScope
          function onShakeTriggerChanged() {
            if (surface.isPrimaryScreen) {
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
          color: Colours.bg
          focus: true

          Keys.onPressed: function(event) {
            surface.capsLockOn = (event.modifiers & Qt.CapsLockModifier) !== 0

            // Clear previous error message immediately on fresh typing
            if (lockScope.errorMessage !== "") {
              lockScope.errorMessage = ""
            }

            // Don't queue keystrokes in the disabled field while PAM is busy.
            if (surface.authenticating) return

            if (event.key === Qt.Key_Escape) {
              lockScope.enteredPassword = ""
              surface.revealPassword = false
              if (surface.isPrimaryScreen && passInput) {
                passInput.focus = false
              }
              mainBg.forceActiveFocus()
              event.accepted = true
              return
            }

            // Ignore standalone modifier keys, tabs, and Delete
            if (event.key === Qt.Key_Shift || event.key === Qt.Key_Control ||
                event.key === Qt.Key_Alt || event.key === Qt.Key_Meta ||
                event.key === Qt.Key_CapsLock || event.key === Qt.Key_Tab ||
                event.key === Qt.Key_Backtab || event.key === Qt.Key_Delete) {
              return
            }

            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              if (lockScope.enteredPassword.length > 0 && !surface.authenticating) {
                surface.revealPassword = false
                lockScope.submitPassword(lockScope.enteredPassword)
                lockScope.enteredPassword = ""
              }
              event.accepted = true
              return
            }

            if (event.key === Qt.Key_Backspace) {
              if (lockScope.enteredPassword.length > 0) {
                lockScope.enteredPassword = lockScope.enteredPassword.slice(0, -1)
              }
              event.accepted = true
              return
            }

            // Ignore modifier shortcuts (Ctrl, Alt combos)
            if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier)) {
              return
            }

            if (event.text && event.text.length > 0) {
              var code = event.text.charCodeAt(0)
              if (code >= 32 && code !== 127) {
                lockScope.enteredPassword += event.text
                event.accepted = true
              }
            }
          }

          // Wallpaper background layer (configurable via Config.lockWallpaperPath)
          Image {
            id: lockBgImage
            anchors.fill: parent
            source: Config.lockWallpaperPath
            asynchronous: true
            cache: false
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(parent.width > 0 ? parent.width : 1920, parent.height > 0 ? parent.height : 1080)
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

          // Clustered Status Pills (default; docked to Config.lockStatusPosition corner)
          Row {
            id: statusCluster
            visible: !surface.isStatusSplit
            spacing: Config.lockStatusSpacing
            z: 10

            readonly property var pos: Utils.parseOverlayPosition(Config.lockStatusPosition, "top-right")

            anchors.top: pos.onBottom ? undefined : mainBg.top
            anchors.bottom: pos.onBottom ? mainBg.bottom : undefined
            anchors.left: pos.onLeft ? mainBg.left : undefined
            anchors.right: pos.onLeft ? undefined : mainBg.right
            anchors.margins: Config.lockStatusMargin

            // Hostname Pill
            Pill {
              horizontal: true
              clickable: false
              baseColour: Colours.bgRaised
              border.color: Colours.border

              Row {
                anchors.centerIn: parent
                spacing: 6

                Text {
                  text: "󰌾"
                  color: Colours.accent
                  font.family: Config.monoFont
                  font.pixelSize: Config.iconSizeSm
                  anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                  text: Quickshell.env("HOSTNAME") || Quickshell.env("HOST") || "NixOS"
                  color: Colours.fgMid
                  font.family: Config.sansFont
                  font.pixelSize: Config.fontSizeSm
                  font.bold: true
                  anchors.verticalCenter: parent.verticalCenter
                }
              }
            }

            // Network Widget Pill
            NetworkWidget {
              horizontal: true
              interactive: false
            }

            // Battery Widget Pill
            BatteryWidget {
              id: lockClusterBattery
              visible: lockClusterBattery.batPresent
              horizontal: true
              interactive: false
            }

            // Volume & Mute Status Pill
            Pill {
              horizontal: true
              clickable: false
              baseColour: Colours.bgRaised
              border.color: SystemService.muted ? Colours.red : Colours.border

              Row {
                anchors.centerIn: parent
                spacing: 6

                Text {
                  text: SystemService.volumeIcon
                  color: SystemService.muted ? Colours.red : Colours.accent
                  font.family: Config.monoFont
                  font.pixelSize: Config.iconSizeSm
                  anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                  text: SystemService.muted ? "Muted" : (SystemService.volumePercent + "%")
                  color: SystemService.muted ? Colours.red : Colours.fgMid
                  font.family: Config.sansFont
                  font.pixelSize: Config.fontSizeSm
                  anchors.verticalCenter: parent.verticalCenter
                }
              }
            }
          }

          // Top Left Hostname / System Status (when Config.lockStatusPosition is "split" or "corners")
          Pill {
            visible: surface.isStatusSplit
            horizontal: true
            clickable: false
            baseColour: Colours.bgRaised
            border.color: Colours.border
            anchors.left: mainBg.left
            anchors.top: mainBg.top
            anchors.margins: Config.lockStatusMargin
            z: 10

            Row {
              anchors.centerIn: parent
              spacing: 6

              Text {
                text: "󰌾"
                color: Colours.accent
                font.family: Config.monoFont
                font.pixelSize: Config.iconSizeSm
                anchors.verticalCenter: parent.verticalCenter
              }

              Text {
                text: Quickshell.env("HOSTNAME") || Quickshell.env("HOST") || "NixOS"
                color: Colours.fgMid
                font.family: Config.sansFont
                font.pixelSize: Config.fontSizeSm
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
              }
            }
          }

          // Top Right Volume & Mute Status (when Config.lockStatusPosition is "split" or "corners")
          Pill {
            visible: surface.isStatusSplit
            horizontal: true
            clickable: false
            baseColour: Colours.bgRaised
            border.color: SystemService.muted ? Colours.red : Colours.border
            anchors.right: mainBg.right
            anchors.top: mainBg.top
            anchors.margins: Config.lockStatusMargin
            z: 10

            Row {
              anchors.centerIn: parent
              spacing: 6

              Text {
                text: SystemService.volumeIcon
                color: SystemService.muted ? Colours.red : Colours.accent
                font.family: Config.monoFont
                font.pixelSize: Config.iconSizeSm
                anchors.verticalCenter: parent.verticalCenter
              }

              Text {
                text: SystemService.muted ? "Muted" : (SystemService.volumePercent + "%")
                color: SystemService.muted ? Colours.red : Colours.fgMid
                font.family: Config.sansFont
                font.pixelSize: Config.fontSizeSm
                anchors.verticalCenter: parent.verticalCenter
              }
            }
          }

          // Bottom Left Wi-Fi / Network Status (when Config.lockStatusPosition is "split" or "corners")
          NetworkWidget {
            visible: surface.isStatusSplit
            horizontal: true
            interactive: false
            anchors.left: mainBg.left
            anchors.bottom: mainBg.bottom
            anchors.margins: Config.lockStatusMargin
            z: 10
          }

          // Bottom Right Battery Status (when Config.lockStatusPosition is "split" or "corners")
          BatteryWidget {
            id: lockSplitBattery
            visible: surface.isStatusSplit && lockSplitBattery.batPresent
            horizontal: true
            interactive: false
            anchors.right: mainBg.right
            anchors.bottom: mainBg.bottom
            anchors.margins: Config.lockStatusMargin
            z: 10
          }

          // Primary Interactive Screen Content
          ColumnLayout {
            visible: surface.isPrimaryScreen

            anchors.centerIn: parent
            width: Math.min(parent.width - 40, Config.lockCardWidth)
            spacing: 24

            // TIME & DATE HEADER
            Column {
              Layout.alignment: Qt.AlignHCenter
              spacing: 4

              Text {
                id: clockText
                anchors.horizontalCenter: parent.horizontalCenter
                text: surface.currentTimeStr
                color: Colours.fg
                font.family: Config.serifFont
                font.pixelSize: 72
                font.italic: true
                font.letterSpacing: 2
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: surface.currentDateStr
                color: Colours.fgDim
                font.family: Config.sansFont
                font.pixelSize: 16
              }
            }

            // MEDIA PLAYER CARD (matches the Command Centre media card)
            MediaCard {
              Layout.fillWidth: true
              seekable: false
              interactive: false
              visible: MediaService.hasPlayer && (MediaService.isPlaying || MediaService.trackTitle !== "")
            }

            // USER & AUTHENTICATION CARD
            Card {
              Layout.fillWidth: true
              implicitHeight: authCol.implicitHeight + 36
              borderColour: surface.errorMessage !== "" ? Colours.red : Colours.border

              transform: Translate {
                x: surface.shakeOffset
              }

              ColumnLayout {
                id: authCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 20
                spacing: 16

                readonly property bool isInputActive: passInput.activeFocus || lockScope.enteredPassword.length > 0

                // Avatar & Username Header
                ColumnLayout {
                  Layout.alignment: Qt.AlignHCenter
                  spacing: 8

                  // Avatar Box (supports custom image with fallback icon)
                  Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: Config.lockAvatarSize
                    height: Config.lockAvatarSize
                    radius: Config.commandCentreCardRadius
                    color: Colours.bgSubtle
                    border.color: Colours.border
                    border.width: 1

                    // Fallback Icon
                    Text {
                      anchors.centerIn: parent
                      text: Config.lockFallbackIcon
                      color: Colours.accent
                      font.family: Config.monoFont
                      font.pixelSize: 32
                      visible: !avatarImage.ready
                    }

                    // Avatar Image (loaded from Config.lockAvatarPath)
                    RoundedImage {
                      id: avatarImage
                      anchors.fill: parent
                      source: Config.lockAvatarPath
                      sourceSize: Qt.size(192, 192)
                      radius: Config.commandCentreCardRadius
                    }
                  }

                  // Username Text
                  Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Quickshell.env("USER") || "User"
                    color: Colours.fg
                    font.family: Config.sansFont
                    font.pixelSize: 20
                    font.bold: true
                  }

                  // Status / Error Subtitle
                  Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: surface.errorMessage !== "" ? surface.errorMessage : (surface.authenticating ? "Authenticating..." : "System Locked")
                    color: surface.errorMessage !== "" ? Colours.red : (surface.authenticating ? Colours.accent : Colours.fgDim)
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
                  color: Colours.bgSubtle
                  border.color: authCol.isInputActive ? Colours.accent : Colours.border
                  border.width: authCol.isInputActive ? 2 : 1

                  Behavior on border.color { ColorAnimation { duration: Config.animSmoothMs } }

                  // Background click area for card margin focusing
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.IBeamCursor
                    onClicked: passInput.forceActiveFocus()
                  }

                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 8
                    spacing: 10

                    // Lock / Auth Icon with spinner animation when authenticating
                    Text {
                      id: authIcon
                      text: surface.authenticating ? "󱎟" : "󰌾"
                      color: authCol.isInputActive ? Colours.accent : Colours.fgDim
                      font.family: Config.monoFont
                      font.pixelSize: Config.iconSizeLg
                      Layout.alignment: Qt.AlignVCenter
                      transformOrigin: Item.Center

                      NumberAnimation {
                        id: spinAnim
                        target: authIcon
                        property: "rotation"
                        from: 0
                        to: 360
                        loops: Animation.Infinite
                        duration: 1000
                        running: surface.authenticating
                      }

                      Connections {
                        target: surface
                        function onAuthenticatingChanged() {
                          if (!surface.authenticating) authIcon.rotation = 0
                        }
                      }
                    }

                    // Password Input Field
                    TextInput {
                      id: passInput
                      Layout.fillWidth: true
                      Layout.alignment: Qt.AlignVCenter
                      echoMode: surface.revealPassword ? TextInput.Normal : TextInput.Password
                      color: Colours.fg
                      font.family: Config.sansFont
                      font.pixelSize: 16
                      clip: true
                      focus: false
                      enabled: !surface.authenticating
                      cursorVisible: activeFocus
                      text: lockScope.enteredPassword

                      Binding {
                        target: passInput
                        property: "text"
                        value: lockScope.enteredPassword
                      }

                      onTextEdited: {
                        lockScope.enteredPassword = passInput.text
                      }

                      onTextChanged: {
                        if (passInput.text.length > 0 && lockScope.errorMessage !== "") {
                          lockScope.errorMessage = ""
                        }
                      }

                      Keys.onPressed: function(event) {
                        surface.capsLockOn = (event.modifiers & Qt.CapsLockModifier) !== 0
                        if (event.key === Qt.Key_Escape) {
                          lockScope.enteredPassword = ""
                          surface.revealPassword = false
                          passInput.focus = false
                          mainBg.forceActiveFocus()
                          event.accepted = true
                        }
                      }

                      Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        text: "Enter password..."
                        color: Colours.fgDim
                        font.family: Config.sansFont
                        font.pixelSize: 16
                        visible: lockScope.enteredPassword.length === 0 && !passInput.activeFocus
                      }

                      onAccepted: {
                        if (lockScope.enteredPassword.length > 0 && !surface.authenticating) {
                          surface.revealPassword = false
                          lockScope.submitPassword(lockScope.enteredPassword)
                          lockScope.enteredPassword = ""
                        }
                      }
                    }

                    // Reveal Password Toggle Button
                    IconButton {
                      id: revealBtn
                      Layout.alignment: Qt.AlignVCenter
                      buttonSize: 32
                      visible: lockScope.enteredPassword.length > 0
                      icon: surface.revealPassword ? "󰈉" : "󰈈"
                      baseColour: "transparent"
                      hoverColour: Colours.bgRaised
                      iconColour: surface.revealPassword ? Colours.accent : Colours.fgDim
                      hoverIconColour: Colours.accent
                      onClicked: {
                        surface.revealPassword = !surface.revealPassword
                      }
                    }

                    // Submit Button Pill
                    IconButton {
                      id: submitBtn
                      Layout.alignment: Qt.AlignVCenter
                      buttonSize: 32
                      icon: "󰁔"
                      baseColour: lockScope.enteredPassword.length > 0 ? Colours.accent : Colours.bgRaised
                      hoverColour: lockScope.enteredPassword.length > 0 ? Colours.accent : Colours.bgSubtle
                      borderColour: lockScope.enteredPassword.length > 0 ? Colours.accent : Colours.border
                      hoverBorderColour: lockScope.enteredPassword.length > 0 ? Colours.accent : Colours.border
                      iconColour: lockScope.enteredPassword.length > 0 ? Colours.bg : Colours.fgDim
                      hoverIconColour: lockScope.enteredPassword.length > 0 ? Colours.bg : Colours.accent
                      hoverScale: 0.92
                      enabled: lockScope.enteredPassword.length > 0 && !surface.authenticating
                      onClicked: {
                        if (lockScope.enteredPassword.length > 0 && !surface.authenticating) {
                          surface.revealPassword = false
                          lockScope.submitPassword(lockScope.enteredPassword)
                          lockScope.enteredPassword = ""
                        }
                      }
                    }
                  }
                }

                // Caps Lock Warning Pill Badge
                Pill {
                  visible: surface.capsLockOn
                  Layout.alignment: Qt.AlignHCenter
                  pillColour: Colours.bgSubtle
                  border.color: Colours.yellow
                  padding: 8

                  Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                      text: "󰌎"
                      color: Colours.yellow
                      font.family: Config.monoFont
                      font.pixelSize: 14
                      anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                      text: "Caps Lock is active"
                      color: Colours.yellow
                      font.family: Config.sansFont
                      font.pixelSize: 13
                      anchors.verticalCenter: parent.verticalCenter
                    }
                  }
                }
              }
            }

            // BOTTOM SYSTEM POWER CONTROLS
            PowerButtons {
              Layout.fillWidth: true
              showLock: false
              buttonRadius: Config.lockInputRadius
            }
          }

          // Secondary Display Screen Content (Non-interactive display for multi-monitors)
          Column {
            visible: !surface.isPrimaryScreen

            anchors.centerIn: parent
            spacing: 20

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: surface.currentTimeStr
              color: Colours.fg
              font.family: Config.serifFont
              font.pixelSize: 72
              font.italic: true
              font.letterSpacing: 1
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: surface.currentDateStr
              color: Colours.fgDim
              font.family: Config.sansFont
              font.pixelSize: 18
            }

            Pill {
              anchors.horizontalCenter: parent.horizontalCenter
              pillColour: Colours.bgRaised
              border.color: surface.errorMessage !== "" ? Colours.red : (lockScope.enteredPassword.length > 0 ? Colours.accent : Colours.border)
              padding: 10

              Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                  text: surface.authenticating ? "󱎟" : (surface.errorMessage !== "" ? "󰅙" : "󰌾")
                  color: surface.errorMessage !== "" ? Colours.red : Colours.accent
                  font.family: Config.monoFont
                  font.pixelSize: 16
                  anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                  text: surface.authenticating
                    ? "Authenticating..."
                    : (surface.errorMessage !== ""
                        ? surface.errorMessage
                        : (lockScope.enteredPassword.length > 0
                            ? ("Typing (" + lockScope.enteredPassword.length + " characters)...")
                            : "System Locked"))
                  color: surface.errorMessage !== "" ? Colours.red : (lockScope.enteredPassword.length > 0 ? Colours.fg : Colours.fgDim)
                  font.family: Config.sansFont
                  font.pixelSize: 15
                  anchors.verticalCenter: parent.verticalCenter
                }
              }
            }

            MediaCard {
              anchors.horizontalCenter: parent.horizontalCenter
              width: Config.lockCardWidth
              seekable: false
              interactive: false
              visible: MediaService.hasPlayer && (MediaService.isPlaying || MediaService.trackTitle !== "")
            }
          }
        }
      }
    }
  }
}
