pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import QtQuick.Layouts

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

  Layout.fillWidth: true
  implicitHeight: authCol.implicitHeight + 36
  borderColour: root.errorMessage !== "" ? Colours.red : Colours.border

  transform: Translate {
    x: root.shakeOffset
  }

  ColumnLayout {
    id: authCol
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: 20
    spacing: 16

    readonly property bool isInputActive: passInput.activeFocus || root.enteredPassword.length > 0

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
        text: root.errorMessage !== "" ? root.errorMessage : (root.authenticating ? "Authenticating..." : "System Locked")
        color: root.errorMessage !== "" ? Colours.red : (root.authenticating ? Colours.accent : Colours.fgDim)
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
          text: root.authenticating ? "󱎟" : "󰌾"
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
          font.family: Config.sansFont
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
            font.family: Config.sansFont
            font.pixelSize: 16
            visible: root.enteredPassword.length === 0 && !passInput.activeFocus
          }

          onAccepted: root.submitEnteredPassword()
        }

        // Reveal Password Toggle Button
        IconButton {
          id: revealBtn
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

        // Submit Button Pill
        IconButton {
          id: submitBtn
          Layout.alignment: Qt.AlignVCenter
          buttonSize: 32
          icon: "󰁔"
          baseColour: root.enteredPassword.length > 0 ? Colours.accent : Colours.bgRaised
          hoverColour: root.enteredPassword.length > 0 ? Colours.accent : Colours.bgSubtle
          borderColour: root.enteredPassword.length > 0 ? Colours.accent : Colours.border
          hoverBorderColour: root.enteredPassword.length > 0 ? Colours.accent : Colours.border
          iconColour: root.enteredPassword.length > 0 ? Colours.bg : Colours.fgDim
          hoverIconColour: root.enteredPassword.length > 0 ? Colours.bg : Colours.accent
          hoverScale: 0.92
          enabled: root.enteredPassword.length > 0 && !root.authenticating
          onClicked: root.submitEnteredPassword()
        }
      }
    }

    // Caps Lock Warning Pill Badge
    Pill {
      visible: root.capsLockOn
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
