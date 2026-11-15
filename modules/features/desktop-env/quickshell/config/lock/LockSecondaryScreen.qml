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

  LockClock {
    anchors.horizontalCenter: parent.horizontalCenter
  }

  Pill {
    anchors.horizontalCenter: parent.horizontalCenter
    pillColour: Colours.bgRaised
    border.color: root.errorMessage !== "" ? Colours.red : (root.enteredLength > 0 ? Colours.accent : Colours.border)
    padding: Config.spaceMd

    LockStateRow {
      anchors.centerIn: parent
      showIcon: true
      errorMessage: root.errorMessage
      authenticating: root.authenticating
      typedLength: root.enteredLength
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
