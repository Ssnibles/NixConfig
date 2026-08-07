import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.UPower
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

      // Primary Interactive Screen Content
      ColumnLayout {
        visible: surface.isPrimaryScreen

        anchors.centerIn: parent
        width: Math.min(parent.width - 40, 440)
        spacing: 28

        // --- TIME & DATE HEADER ---
        Column {
          Layout.alignment: Qt.AlignHCenter
          spacing: 6

          Text {
            id: clockText
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(new Date(), Config.lockClockFormat)
            color: Colors.fg
            font.family: Config.serifFont
            font.pixelSize: 64
            font.italic: true

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
            font.pixelSize: 18
          }
        }

        // --- USER & AUTHENTICATION CARD ---
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: authCol.implicitHeight + 40
          color: Colors.bg
          border.color: surface.errorMessage !== "" ? Colors.red : Colors.border
          border.width: 1
          radius: Config.lockCardRadius

          transform: Translate {
            x: surface.shakeOffset
          }

          Behavior on border.color { ColorAnimation { duration: 150 } }

          ColumnLayout {
            id: authCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 24
            spacing: 18

            // Avatar & Username Header
            ColumnLayout {
              Layout.alignment: Qt.AlignHCenter
              spacing: 8

              // Avatar Card Box (supports custom image with fallback icon)
              Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 64
                height: 64
                radius: Config.lockCardRadius
                color: Colors.bgSubtle
                border.color: Colors.border
                border.width: 1

                // Fallback Nerd Font Glyph Icon
                Text {
                  anchors.centerIn: parent
                  text: Config.lockFallbackIcon
                  color: Colors.accent
                  font.family: Config.monoFont
                  font.pixelSize: 36
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
                    radius: Config.lockCardRadius
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

            // Password Input Box (Card Container)
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

                // Submit Button Card
                Rectangle {
                  id: submitBtn
                  Layout.preferredWidth: 32
                  Layout.preferredHeight: 32
                  Layout.alignment: Qt.AlignVCenter
                  radius: 8
                  color: submitHover.containsMouse ? Colors.accent : Colors.bg
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

            // Caps Lock Warning Indicator
            Row {
              Layout.alignment: Qt.AlignHCenter
              visible: surface.capsLockOn
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
              color: hoverArea.containsMouse ? Colors.bgSubtle : Colors.bg
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
        spacing: 16

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: Qt.formatDateTime(new Date(), "hh:mm")
          color: Colors.fg
          font.family: Config.sansFont
          font.pixelSize: 72
          font.bold: true
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
          color: Colors.fgMid
          font.family: Config.sansFont
          font.pixelSize: 18
          font.bold: true
        }

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 8

          Text {
            text: "󰌾"
            color: Colors.accent
            font.family: Config.monoFont
            font.pixelSize: 16
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            text: "Locked"
            color: Colors.fgDim
            font.family: Config.sansFont
            font.pixelSize: 16
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }
    }
  }
}
  }
}
