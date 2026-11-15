pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."

// Header shared by the status menus: icon, title, optional controls and the
// close button. Declared children land before the close button.
RowLayout {
  id: root

  property string icon: ""
  property color iconColour: Colours.fg
  property string title: ""

  default property alias actions: trailing.data

  Layout.fillWidth: true
  spacing: Config.spaceSm

  Text {
    text: root.icon
    color: root.iconColour
    font.family: Session.monoFont
    font.pixelSize: Config.iconSizeLg
  }

  Text {
    Layout.fillWidth: true
    text: root.title
    color: Colours.fg
    font.family: Session.sansFont
    font.pixelSize: Config.fontSizeLg
    font.bold: true
  }

  Row {
    id: trailing
    spacing: Config.spaceSm
  }

  IconButton {
    buttonSize: Config.spaceXl + Config.space2xs
    iconSize: Config.iconSizeSm
    icon: "󰅖"
    onClicked: UiState.closeStatusMenu()
  }
}
