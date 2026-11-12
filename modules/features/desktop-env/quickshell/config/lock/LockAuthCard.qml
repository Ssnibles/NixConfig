pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."

// Interactive authentication card used on the primary lock screen display.
Card {
  id: root

  property var session: null

  property real shakeOffset: 0
  property bool capsLockOn: false
  property bool revealPassword: false
  readonly property bool authenticating: root.session ? root.session.authenticating : false
  readonly property string errorMessage: root.session ? root.session.errorMessage : ""
  readonly property string enteredPassword: root.session ? root.session.enteredPassword : ""

  signal backgroundFocusRequested()

  function submitEnteredPassword() {
    if (root.enteredPassword.length === 0 || root.authenticating) return
    root.revealPassword = false
    root.session.submitPassword(root.session.enteredPassword)
    root.session.enteredPassword = ""
  }

  function cancelInput() {
    root.session.enteredPassword = ""
    root.revealPassword = false
    passInput.focus = false
  }

  function updateCapsLock(modifiers) {
    root.capsLockOn = (modifiers & Qt.CapsLockModifier) !== 0
  }

  // Extra top padding gives the avatar room to breathe.
  implicitHeight: authCol.implicitHeight + Config.spaceXl + Config.spaceLg
  borderColour: root.errorMessage !== "" ? Colours.red : Colours.border

  transform: Translate {
    x: root.shakeOffset
  }

  ColumnLayout {
    id: authCol
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.leftMargin: Config.spaceLg
    anchors.rightMargin: Config.spaceLg
    anchors.topMargin: Config.spaceXl
    spacing: Config.spaceLg

    readonly property bool isInputActive: passInput.activeFocus || root.enteredPassword.length > 0

    // Avatar and identity header.
    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: Config.spaceMd

      // Avatar Box (supports custom image with fallback icon)
      Rectangle {
        Layout.alignment: Qt.AlignHCenter
        width: Config.lockAvatarSize
        height: Config.lockAvatarSize
        radius: Config.commandCentreCardRadius
        color: Colours.bgSubtle
        border.color: Colours.border
        border.width: Config.borderWidth

        // Fallback Icon
        Text {
          anchors.centerIn: parent
          text: Config.lockFallbackIcon
          color: Colours.accent
          font.family: Session.monoFont
          font.pixelSize: 32
          visible: !avatarImage.ready
        }

        // Avatar Image (loaded from Session.lockAvatarPath)
        RoundedImage {
          id: avatarImage
          anchors.fill: parent
          source: Session.lockAvatarPath
          sourceSize: Qt.size(192, 192)
          radius: Config.commandCentreCardRadius
        }
      }

      // Username and status form a tighter pair under the avatar.
      ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Config.space2xs

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: Session.user
          color: Colours.fg
          font.family: Session.sansFont
          font.pixelSize: 20
          font.bold: true
        }

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: root.errorMessage !== "" ? root.errorMessage : (root.authenticating ? "Authenticating..." : "System Locked")
          color: root.errorMessage !== "" ? Colours.red : (root.authenticating ? Colours.accent : Colours.fgDim)
          font.family: Session.sansFont
          font.pixelSize: Config.fontSizeMd
        }
      }
    }

    // Password Input Pill Box Container
    Rectangle {
      Layout.fillWidth: true
      height: 48
      radius: Config.lockInputRadius
      color: Colours.bgSubtle
      border.color: authCol.isInputActive ? Colours.accent : Colours.border
      border.width: authCol.isInputActive ? Config.borderWidthFocus : Config.borderWidth

      Behavior on border.color { ColorAnimation { duration: Config.animSmoothMs } }

      // Background click area for card margin focusing
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onClicked: passInput.forceActiveFocus()
      }

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Config.spaceLg
        anchors.rightMargin: Config.spaceLg
        spacing: Config.spaceMd

        // Lock / Auth Icon with spinner animation when authenticating
        Text {
          id: authIcon
          text: root.authenticating ? "󱎟" : "󰌾"
          color: authCol.isInputActive ? Colours.accent : Colours.fgDim
          font.family: Session.monoFont
          font.pixelSize: Config.iconSizeLg
          Layout.alignment: Qt.AlignVCenter
          transformOrigin: Item.Center

          NumberAnimation {
            target: authIcon
            property: "rotation"
            from: 0
            to: 360
            loops: Animation.Infinite
            duration: 1000
            running: root.authenticating
          }

          Connections {
            target: root
            function onAuthenticatingChanged() {
              if (!root.authenticating) authIcon.rotation = 0
            }
          }
        }

        // Password Input Field
        TextInput {
          id: passInput
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignVCenter
          echoMode: root.revealPassword ? TextInput.Normal : TextInput.Password
          color: Colours.fg
          font.family: Session.sansFont
          font.pixelSize: 16
          clip: true
          focus: false
          enabled: !root.authenticating
          cursorVisible: activeFocus

          Binding {
            target: passInput
            property: "text"
            value: root.enteredPassword
          }

          onTextEdited: {
            root.session.enteredPassword = passInput.text
          }

          onTextChanged: {
            if (passInput.text.length > 0 && root.session.errorMessage !== "") {
              root.session.errorMessage = ""
            }
          }

          Keys.onPressed: function(event) {
            root.updateCapsLock(event.modifiers)
            if (event.key === Qt.Key_Escape) {
              root.cancelInput()
              root.backgroundFocusRequested()
              event.accepted = true
            }
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            text: "Enter password..."
            color: Colours.fgDim
            font.family: Session.sansFont
            font.pixelSize: 16
            visible: root.enteredPassword.length === 0 && !passInput.activeFocus
          }

          onAccepted: root.submitEnteredPassword()
        }

        // Reveal Password Toggle Button
        IconButton {
          Layout.alignment: Qt.AlignVCenter
          buttonSize: 32
          visible: root.enteredPassword.length > 0
          icon: root.revealPassword ? "󰈉" : "󰈈"
          baseColour: "transparent"
          hoverColour: Colours.bgRaised
          iconColour: root.revealPassword ? Colours.accent : Colours.fgDim
          hoverIconColour: Colours.accent
          onClicked: {
            root.revealPassword = !root.revealPassword
          }
        }
      }
    }

    // Caps Lock Warning Pill Badge
    Pill {
      visible: root.capsLockOn
      Layout.alignment: Qt.AlignHCenter
      pillColour: Colours.bgSubtle
      border.color: Colours.yellow
      padding: Config.spaceMd

      Row {
        anchors.centerIn: parent
        spacing: Config.spaceSm

        Text {
          text: "󰌎"
          color: Colours.yellow
          font.family: Session.monoFont
          font.pixelSize: 14
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: "Caps Lock is active"
          color: Colours.yellow
          font.family: Session.sansFont
          font.pixelSize: 13
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }

    // Media is secondary to authentication, so it sits below a divider.
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Config.spaceLg
      visible: lockMedia.hasMedia

      Divider { Layout.fillWidth: true }

      LockMediaRow {
        id: lockMedia
        Layout.fillWidth: true
      }
    }
  }
}
