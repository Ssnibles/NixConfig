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

  // Expose lock/unlock via IPC at Scope level so target exists when unlocked
  IpcHandler {
    target: "lockscreen"

    function lock(): void {
      lockScope.active = true
    }

    function unlock(): void {
      lockScope.active = false
    }

    function toggle(): void {
      lockScope.active = !lockScope.active
    }
  }

  Loader {
    id: lockLoader
    active: lockScope.active
    sourceComponent: lockComponent
  }

  Component {
    id: lockComponent

    WlSessionLock {
      id: lockRoot
      locked: true

      Connections {
        target: lockRoot
        function onLockedChanged() {
          if (!lockRoot.locked) {
            lockScope.active = false
          }
        }
      }

      WlSessionLockSurface {
        id: surface
        color: Colors.bg

        // Core state properties for authentication
        property bool authenticating: false
        property string errorMessage: ""
        property real shakeOffset: 0
        property bool capsLockOn: false

        Component.onCompleted: {
          surface.errorMessage = ""
          surface.authenticating = false
          pam.start()
          mainBg.forceActiveFocus()
        }

        // PAM Service Context
        PamContext {
          id: pam
          config: "login"
          user: Quickshell.env("USER") || ""

          onCompleted: function(result) {
            surface.authenticating = false
            if (result === PamResult.Success) {
              surface.errorMessage = ""
              passInput.text = ""
              lockRoot.locked = false
            } else {
              surface.errorMessage = "Authentication failed. Try again."
              passInput.text = ""
              shakeAnimation.start()
              pam.start()
              mainBg.forceActiveFocus()
            }
          }

          onError: function(err) {
            surface.authenticating = false
            surface.errorMessage = "PAM Error"
            shakeAnimation.start()
            mainBg.forceActiveFocus()
          }
        }

        Connections {
          target: lockRoot
          function onLockedChanged() {
            if (lockRoot.locked) {
              surface.errorMessage = ""
              passInput.text = ""
              surface.authenticating = false
              pam.start()
              mainBg.forceActiveFocus()
            } else {
              lockScope.active = false
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
        anchors.fill: parent
        source: Config.lockWallpaperPath
        fillMode: Image.PreserveAspectCrop
        smooth: true

        // Translucent dark overlay to elevate UI contrast
        Rectangle {
          anchors.fill: parent
          color: "#CC000000"
        }
      }

      // Global click handler to clear text field focus when clicking outside
      MouseArea {
        anchors.fill: parent
        onClicked: mainBg.forceActiveFocus()
      }

      // Check if this screen is the main interactive screen (first screen in list)
      property bool isPrimaryScreen: surface.screen === undefined || surface.screen === Quickshell.screens[0]

      // Primary Interactive Screen Content
      ColumnLayout {
        visible: parent.isPrimaryScreen
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
            font.family: Config.sansFont
            font.pixelSize: 64
            font.bold: true

            Timer {
              interval: 1000
              running: lockRoot.locked
              repeat: true
              onTriggered: clockText.text = Qt.formatDateTime(new Date(), Config.lockClockFormat)
            }
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(new Date(), Config.lockDateFormat)
            color: Colors.fgMid
            font.family: Config.sansFont
            font.pixelSize: 15
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
                font.pixelSize: 18
                font.bold: true
              }

              // Status / Error Subtitle
              Text {
                Layout.alignment: Qt.AlignHCenter
                text: surface.errorMessage !== "" ? surface.errorMessage : (surface.authenticating ? "Authenticating..." : "System Locked")
                color: surface.errorMessage !== "" ? Colors.red : (surface.authenticating ? Colors.accent : Colors.fgDim)
                font.family: Config.sansFont
                font.pixelSize: 12
              }
            }

            // Password Input Box (Card Container)
            Rectangle {
              id: inputCard
              Layout.fillWidth: true
              height: 46
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
                  font.pixelSize: 16
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
                  font.pixelSize: 14
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
                    font.pixelSize: 14
                    visible: passInput.text.length === 0 && !passInput.activeFocus
                  }

                  onAccepted: {
                    if (passInput.text.length > 0 && !surface.authenticating) {
                      surface.authenticating = true
                      surface.errorMessage = ""
                      if (!pam.active) pam.start()
                      if (pam.responseRequired) {
                        pam.respond(passInput.text)
                      }
                    }
                  }

                  Connections {
                    target: pam
                    function onResponseRequiredChanged() {
                      if (pam.responseRequired && surface.authenticating && passInput.text.length > 0) {
                        pam.respond(passInput.text)
                      }
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
                    font.pixelSize: 14
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
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
              }

              Text {
                text: "Caps Lock is active"
                color: Colors.yellow
                font.family: Config.sansFont
                font.pixelSize: 11
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
                  font.pixelSize: 16
                  anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                  text: modelData.label
                  color: hoverArea.containsMouse ? Colors.fg : Colors.fgMid
                  font.family: Config.sansFont
                  font.pixelSize: 11
                  font.bold: true
                  anchors.verticalCenter: parent.verticalCenter
                }
              }
            }
          }
        }
      }

      // Secondary Display Screen Content (Non-interactive display for multi-monitors)
      Column {
        visible: !parent.isPrimaryScreen
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
          font.pixelSize: 16
        }

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 8

          Text {
            text: "󰌾"
            color: Colors.accent
            font.family: Config.monoFont
            font.pixelSize: 14
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            text: "Locked"
            color: Colors.fgDim
            font.family: Config.sansFont
            font.pixelSize: 14
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }
    }
  }
}
}
