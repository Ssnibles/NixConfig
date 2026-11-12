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
  spacing: 20

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    text: ClockService.lockTimeStr
    color: Colours.fg
    font.family: Session.serifFont
    font.pixelSize: 72
    font.italic: true
    font.letterSpacing: 1
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    text: ClockService.lockDateStr
    color: Colours.fgDim
    font.family: Session.sansFont
    font.pixelSize: 18
  }

  Pill {
    anchors.horizontalCenter: parent.horizontalCenter
    pillColour: Colours.bgRaised
    border.color: root.errorMessage !== "" ? Colours.red : (root.enteredLength > 0 ? Colours.accent : Colours.border)
    padding: 10

    Row {
      anchors.centerIn: parent
      spacing: 8

      Text {
        text: root.authenticating ? "󱎟" : (root.errorMessage !== "" ? "󰅙" : "󰌾")
        color: root.errorMessage !== "" ? Colours.red : Colours.accent
        font.family: Session.monoFont
        font.pixelSize: 16
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
