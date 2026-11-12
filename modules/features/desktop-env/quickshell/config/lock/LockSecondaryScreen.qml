pragma ComponentBehavior: Bound
import QtQuick
import ".."

// Read-only lock screen content shown on non-primary displays.
Column {
  id: root

  property var session: null

  readonly property bool authenticating: root.session ? root.session.authenticating : false
  readonly property string errorMessage: root.session ? root.session.errorMessage : ""
  readonly property int enteredLength: root.session ? root.session.enteredPassword.length : 0

  anchors.centerIn: parent
  spacing: Config.spaceXl

  Column {
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Config.spaceXs

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: ClockService.lockTimeStr
      color: Colours.fg
      font.family: Session.serifFont
      font.pixelSize: 72
      font.italic: true
      font.letterSpacing: 2
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: ClockService.lockDateStr
      color: Colours.fgDim
      font.family: Session.sansFont
      font.pixelSize: 16
    }
  }

  Pill {
    anchors.horizontalCenter: parent.horizontalCenter
    pillColour: Colours.bgRaised
    border.color: root.errorMessage !== "" ? Colours.red : (root.enteredLength > 0 ? Colours.accent : Colours.border)
    padding: Config.spaceMd

    Row {
      anchors.centerIn: parent
      spacing: Config.spaceSm

      Text {
        text: root.authenticating ? "󱎟" : (root.errorMessage !== "" ? "󰅙" : "󰌾")
        color: root.errorMessage !== "" ? Colours.red : Colours.accent
        font.family: Session.monoFont
        font.pixelSize: Config.iconSizeMd
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: root.authenticating
          ? "Authenticating..."
          : (root.errorMessage !== ""
              ? root.errorMessage
              : (root.enteredLength > 0
                  ? ("Typing (" + root.enteredLength + " characters)...")
                  : "System Locked"))
        color: root.errorMessage !== "" ? Colours.red : (root.enteredLength > 0 ? Colours.fg : Colours.fgDim)
        font.family: Session.sansFont
        font.pixelSize: Config.fontSizeLg
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }

  Card {
    anchors.horizontalCenter: parent.horizontalCenter
    width: Config.lockCardWidth
    implicitHeight: secondaryMedia.implicitHeight + Config.spaceLg * 2
    visible: secondaryMedia.hasMedia

    LockMediaRow {
      id: secondaryMedia
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Config.spaceLg
    }
  }
}
