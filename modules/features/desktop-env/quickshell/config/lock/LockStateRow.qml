pragma ComponentBehavior: Bound
import QtQuick
import ".."

// Lock state line shared by the primary and secondary lock layouts. An error
// wins, then the authenticating message, then the typed-character count.
Row {
  id: root

  property string errorMessage: ""
  property bool authenticating: false
  property int typedLength: 0
  property bool showIcon: false
  property int textSize: Config.fontSizeLg

  readonly property color stateColour: root.errorMessage !== ""
    ? Colours.red
    : (root.typedLength > 0 ? Colours.fg : (root.authenticating ? Colours.accent : Colours.fgDim))

  spacing: Config.spaceSm

  Text {
    visible: root.showIcon
    anchors.verticalCenter: parent.verticalCenter
    text: root.errorMessage !== "" ? "󰅙" : (root.authenticating ? "󱎟" : "󰌾")
    color: root.stateColour
    font.family: Session.monoFont
    font.pixelSize: Config.iconSizeMd
  }

  Text {
    anchors.verticalCenter: parent.verticalCenter
    text: root.errorMessage !== ""
      ? root.errorMessage
      : (root.authenticating
          ? "Authenticating..."
          : (root.typedLength > 0
              ? ("Typing (" + root.typedLength + " characters)...")
              : "System Locked"))
    color: root.stateColour
    font.family: Session.sansFont
    font.pixelSize: root.textSize
  }
}
