pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Scope {
  id: lockScope

  property bool active: false
  property bool authenticating: false
  property string errorMessage: ""
  property int shakeTrigger: 0
  property string pendingPassword: ""
  // Guards against a tight start→fail→start loop if PAM keeps erroring without
  // user input. Reset on every user-initiated submit and on a successful unlock.
  property int _authRestarts: 0
  readonly property int _maxAuthRestarts: 5

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
        color: Colours.bg

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

        property string currentTimeStr: Qt.formatDateTime(new Date(), Config.lockClockFormat)
        property string currentDateStr: Qt.formatDateTime(new Date(), Config.lockDateFormat)

        function updateTime() {
          var d = new Date()
          surface.currentTimeStr = Qt.formatDateTime(d, Config.lockClockFormat)
          surface.currentDateStr = Qt.formatDateTime(d, Config.lockDateFormat)
          clockTimer.interval = 60000 - (d.getSeconds() * 1000 + d.getMilliseconds())
          clockTimer.restart()
        }

        Timer {
          id: clockTimer
          running: lockRoot.locked
          repeat: false
          onTriggered: surface.updateTime()
        }

        Component.onCompleted: {
          surface.updateTime()
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
          color: Colours.bg
          focus: true

          Keys.onPressed: function(event) {
            surface.capsLockOn = (event.modifiers & Qt.CapsLockModifier) !== 0

            // Don't queue keystrokes in the disabled field while PAM is busy.
            if (surface.authenticating) return

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

          // Bottom Left Wi-Fi / Network Status (shared pill widget)
          NetworkWidget {
            visible: surface.isPrimaryScreen
            horizontal: true
            interactive: false
            anchors.left: mainBg.left
            anchors.bottom: mainBg.bottom
            anchors.margins: 24
            z: 10
          }

          // Bottom Right Battery Status (shared pill widget)
          BatteryWidget {
            id: lockBattery
            visible: surface.isPrimaryScreen && lockBattery.batPresent
            horizontal: true
            interactive: false
            anchors.right: mainBg.right
            anchors.bottom: mainBg.bottom
            anchors.margins: 24
            z: 10
          }

          // Primary Interactive Screen Content
          ColumnLayout {
            visible: surface.isPrimaryScreen

            anchors.centerIn: parent
            width: Math.min(parent.width - 40, Config.lockCardWidth)
            spacing: 24

            // --- TIME & DATE HEADER ---
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

            // --- MEDIA PLAYER CARD (matches the Command Centre media card) ---
            MediaCard {
              Layout.fillWidth: true
              seekable: false
              interactive: false
              visible: MediaService.hasPlayer && (MediaService.isPlaying || MediaService.trackTitle !== "")
            }

            // --- USER & AUTHENTICATION CARD ---
            Rectangle {
              Layout.fillWidth: true
              implicitHeight: authCol.implicitHeight + 36
              color: Colours.bgRaised
              border.color: surface.errorMessage !== "" ? Colours.red : Colours.border
              border.width: 1
              radius: Config.commandCentreCardRadius

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
                  border.color: passInput.activeFocus ? Colours.accent : Colours.border
                  border.width: passInput.activeFocus ? 2 : 1

                  Behavior on border.color { ColorAnimation { duration: 150 } }

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

                    // Lock / Auth Icon
                    Text {
                      text: surface.authenticating ? "󱎟" : "󰌾"
                      color: passInput.activeFocus ? Colours.accent : Colours.fgDim
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
                      color: Colours.fg
                      font.family: Config.sansFont
                      font.pixelSize: 16
                      clip: true
                      focus: false
                      enabled: !surface.authenticating
                      cursorVisible: activeFocus

                      onTextChanged: {
                        if (passInput.text.length > 0 && lockScope.errorMessage !== "") {
                          lockScope.errorMessage = ""
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
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        text: "Enter password..."
                        color: Colours.fgDim
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
                      color: submitHover.containsMouse ? Colours.accent : Colours.bgRaised
                      border.color: Colours.border
                      border.width: 1

                      Behavior on scale { NumberAnimation { duration: 100 } }

                      Text {
                        anchors.centerIn: parent
                        text: "󰁔"
                        color: submitHover.containsMouse ? Colours.bg : Colours.fg
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

            // --- BOTTOM SYSTEM POWER CONTROLS ---
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
              border.color: Colours.border
              padding: 10

              Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                  text: "󰌾"
                  color: Colours.accent
                  font.family: Config.monoFont
                  font.pixelSize: 16
                  anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                  text: "Locked"
                  color: Colours.fgDim
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
