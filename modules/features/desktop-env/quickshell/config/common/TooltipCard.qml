pragma ComponentBehavior: Bound
import QtQuick
import ".."

// Default tooltip card: icon and title header, then one line per detail.
// Rendered by SharedTooltipWindow when a Tooltip has no custom content.
Card {
  id: root

  property var tooltip: null

  width: parent ? parent.width : 0
  height: content.implicitHeight + Config.popupContentMargins * 2
  cardRadius: Config.popupRadius
  cardColour: Colours.bg

  Column {
    id: content
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Config.popupContentMargins
    spacing: Config.popupContentSpacing

    Row {
      spacing: Config.spaceSm

      Text {
        text: root.tooltip ? root.tooltip.icon : ""
        color: root.tooltip ? root.tooltip.iconColour : Colours.fg
        font.family: Session.monoFont
        font.pixelSize: 19
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: root.tooltip ? root.tooltip.title : ""
        color: Colours.fg
        font.family: Session.sansFont
        font.pixelSize: Config.fontSizeLg
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Divider {
      width: parent.width
      visible: root.tooltip ? root.tooltip.details.length > 0 : false
    }

    Repeater {
      model: root.tooltip ? root.tooltip.details : []

      delegate: Text {
        required property var modelData
        text: modelData
        color: Colours.fgMid
        font.family: Session.sansFont
        font.pixelSize: Config.fontSizeMd
      }
    }
  }
}
