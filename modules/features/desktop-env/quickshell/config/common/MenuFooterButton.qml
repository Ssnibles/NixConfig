pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."

// Wide footer button shared by the status menus, handing off to the full
// network or Bluetooth manager.
Pill {
  id: root

  property string icon: "󰒓"
  property string label: ""

  Layout.fillWidth: true
  pillHeight: Config.spaceXl + Config.spaceSm
  padding: Config.pillPaddingHorizontal
  baseColour: Colours.bgSubtle
  hoverColour: Colours.bgRaised
  hoverHighlight: true
  border.color: Colours.border
  clickable: true

  Row {
    anchors.centerIn: parent
    spacing: Config.spaceSm

    Text {
      text: root.icon
      color: Colours.fgDim
      font.family: Session.monoFont
      font.pixelSize: Config.iconSizeSm
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: root.label
      color: Colours.fgMid
      font.family: Session.sansFont
      font.pixelSize: Config.fontSizeSm
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}
