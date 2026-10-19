pragma ComponentBehavior: Bound
import QtQuick

// Shared interactive icon button with hover colour, border, and scale feedback.
Rectangle {
  id: root

  property string icon: ""
  property string uiFont: Config.monoFont
  property int iconSize: Config.iconSizeMd
  property int buttonSize: 28

  property color baseColour: "transparent"
  property color hoverColour: Colours.bgSubtle
  property color borderColour: "transparent"
  property color hoverBorderColour: borderColour
  property color iconColour: Colours.fg
  property color hoverIconColour: Colours.accent
  property color disabledIconColour: Colours.fgDim
  property real hoverScale: 1.0

  readonly property bool hovered: mouseArea.containsMouse

  signal clicked(var mouse)

  implicitWidth: root.buttonSize
  implicitHeight: root.buttonSize
  width: implicitWidth
  height: implicitHeight
  radius: Config.itemRadiusMd
  antialiasing: true

  color: (root.enabled && root.hovered) ? root.hoverColour : root.baseColour
  border.width: (root.borderColour !== "transparent" || root.hoverBorderColour !== "transparent") ? 1 : 0
  border.color: (root.enabled && root.hovered) ? root.hoverBorderColour : root.borderColour
  scale: (root.enabled && root.hovered) ? root.hoverScale : 1.0

  Behavior on color { ColorAnimation { duration: Config.animFastMs } }
  Behavior on border.color { ColorAnimation { duration: Config.animFastMs } }
  Behavior on scale { NumberAnimation { duration: Config.animFastMs } }

  Text {
    anchors.centerIn: parent
    text: root.icon
    color: !root.enabled
      ? root.disabledIconColour
      : (root.hovered ? root.hoverIconColour : root.iconColour)
    font.family: root.uiFont
    font.pixelSize: root.iconSize
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    enabled: root.enabled
    hoverEnabled: root.enabled
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: function(mouse) {
      root.clicked(mouse)
    }
  }
}
