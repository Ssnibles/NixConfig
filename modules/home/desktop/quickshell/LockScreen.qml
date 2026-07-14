import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

WlSessionLockSurface {
  id: lockSurface

  signal authenticated()

  readonly property string uiFont: "JetBrainsMono Nerd Font"
  readonly property string specialFont: "Instrument Serif"

  property bool authFailed: false
  property bool authInProgress: false
  property string statusMsg: ""

  Item {
    id: focusCatcher
    anchors.fill: parent
    focus: true

    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_Escape) {
        passwordField.text = ""
        focusCatcher.forceActiveFocus()
        event.accepted = true
      } else if (!passwordField.activeFocus
                 && event.text.length > 0
                 && event.key !== Qt.Key_Return
                 && event.key !== Qt.Key_Enter) {
        passwordField.forceActiveFocus()
        passwordField.text = event.text
        event.accepted = true
      }
    }
  }

  PamContext {
    id: pamContext
    user: "josh"
    config: "quickshell"

    onResponseRequiredChanged: {
      if (responseRequired) {
        respond(passwordField.text)
        passwordField.text = ""
      }
    }

    onCompleted: function(result) {
      authInProgress = false
      if (result === PamResult.Success) {
        lockSurface.authenticated()
      } else {
        authFailed = true
        statusMsg = "Authentication failed"
        failTimer.restart()
      }
    }

    onError: function(error) {
      authInProgress = false
      authFailed = true
      statusMsg = "Authentication error"
      failTimer.restart()
    }
  }

  function submitPassword() {
    if (passwordField.text.length === 0 || authInProgress) return
    authInProgress = true
    authFailed = false
    statusMsg = ""
    pamContext.start()
  }

  Timer {
    id: failTimer
    interval: 2500
    onTriggered: {
      authFailed = false
      statusMsg = ""
    }
  }

  Image {
    anchors.fill: parent
    source: Colors.wallpaper
    fillMode: Image.PreserveAspectCrop
    smooth: true

    Rectangle {
      anchors.fill: parent
      color: "#CC000000"
    }
  }

  Rectangle {
    id: card
    anchors.centerIn: parent
    width: 380
    height: cardContent.implicitHeight + 56
    radius: 24
    color: Colors.bgRaised
    border.width: authFailed ? 2 : 1
    border.color: authFailed ? Colors.red : Colors.border

    opacity: 0
    scale: 0.94

    Component.onCompleted: cardAnim.start()

    ParallelAnimation {
      id: cardAnim
      NumberAnimation { target: card; property: "opacity"; to: 1; duration: 350; easing.type: Easing.OutCubic }
      NumberAnimation { target: card; property: "scale"; to: 1; duration: 350; easing.type: Easing.OutCubic }
    }

    ColumnLayout {
      id: cardContent
      anchors { left: parent.left; right: parent.right; top: parent.top; margins: 28 }
      spacing: 0

      Text {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 4
        text: Qt.formatDateTime(new Date(), "HH:mm")
        color: Colors.fg
        font.family: lockSurface.specialFont
        font.pixelSize: 72
        font.italic: true

        Timer {
          interval: 1000
          running: true
          repeat: true
          onTriggered: parent.text = Qt.formatDateTime(new Date(), "HH:mm")
        }
      }

      Text {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 2
        text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
        color: Colors.fgMid
        font.family: lockSurface.uiFont
        font.pixelSize: 13
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 28
        Layout.preferredHeight: 48
        radius: 12
        color: Colors.bg
        border.width: passwordField.activeFocus ? 2 : 1
        border.color: {
          if (lockSurface.authFailed) return Colors.red
          return passwordField.activeFocus ? Colors.accent : Colors.border
        }

        Behavior on border.color { ColorAnimation { duration: 150 } }

        TextInput {
          id: passwordField
          anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
          color: Colors.fg
          font.family: lockSurface.uiFont
          font.pixelSize: 13
          horizontalAlignment: TextInput.AlignHCenter
          verticalAlignment: TextInput.AlignVCenter
          echoMode: TextInput.Password
          passwordCharacter: "\u2022"
          clip: true

          Keys.onEscapePressed: {
            text = ""
            focusCatcher.forceActiveFocus()
          }

          Text {
            anchors.fill: parent
            text: "Enter password..."
            color: Colors.fgDim
            font.family: lockSurface.uiFont
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            visible: passwordField.text.length === 0 && !passwordField.activeFocus
          }

          onAccepted: lockSurface.submitPassword()
        }
      }

      Text {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 10
        text: lockSurface.statusMsg || (lockSurface.authInProgress ? "Authenticating..." : "")
        color: lockSurface.authFailed ? Colors.red : Colors.accent
        font.family: lockSurface.uiFont
        font.pixelSize: 11
        visible: text.length > 0
      }
    }
  }
}
