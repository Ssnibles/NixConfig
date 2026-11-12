pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import ".."

// Icon plus optional label inside a Pill, with an optional tooltip. Shared by
// the bar status widgets and the lock screen badges.
Pill {
  id: root

  property PanelWindow sharedWindow: null
  // Pointer interaction. Off for read-only badges such as the lock screen.
  property bool interactive: true

  property string icon: ""
  property color iconColour: Colours.fg
  property int iconSize: Config.iconSizeSm
  property string iconFont: Session.monoFont

  property string label: ""
  // The label is only meaningful in the horizontal layout.
  property bool showLabel: root.horizontal
  property color labelColour: Colours.fg
  property int labelSize: Config.fontSizeSm
  property string labelFont: Session.sansFont
  property bool labelBold: false
  property real labelMaxWidth: 0

  // Side bars rotate the icon and label as a unit.
  property real rowRotation: 0
  property int rowSpacing: Config.spaceSm

  property bool tooltipEnabled: true
  property string tooltipTitle: ""
  property var tooltipDetails: []

  hoverHighlight: root.interactive
  clickable: root.interactive

  Row {
    anchors.centerIn: parent
    spacing: root.rowSpacing
    rotation: root.rowRotation
    transformOrigin: Item.Center

    Text {
      text: root.icon
      color: root.iconColour
      font.family: root.iconFont
      font.pixelSize: root.iconSize
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      visible: root.showLabel
      text: root.showLabel ? root.label : ""
      color: root.labelColour
      font.family: root.labelFont
      font.pixelSize: root.labelSize
      font.bold: root.labelBold
      elide: Text.ElideRight
      maximumLineCount: 1
      width: root.labelMaxWidth > 0 ? Math.min(implicitWidth, root.labelMaxWidth) : implicitWidth
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  Tooltip {
    target: root
    visible: root.tooltipEnabled
    sharedWindow: root.sharedWindow
    icon: root.icon
    iconColour: root.iconColour
    title: root.tooltipTitle
    details: root.tooltipDetails
  }
}
