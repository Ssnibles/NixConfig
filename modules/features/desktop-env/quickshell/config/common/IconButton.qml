pragma ComponentBehavior: Bound
import QtQuick
import ".."

// Shared interactive icon button with hover colour, border, and scale feedback.
Rectangle {
  id: root

  property string icon: ""
  property string uiFont: Session.monoFont
  property int iconSize: Config.iconSizeMd
  property int buttonSize: Config.spaceXl + Config.space2xs

  property color baseColour: "transparent"
  property color hoverColour: Colours.bgSubtle
  property color borderColour: "transparent"
  property color hoverBorderColour: borderColour
  property color iconColour: Colours.fg
  property color hoverIconColour: Colours.accent
  property color disabledIconColour: Colours.fgDim
  property real hoverScale: 1.04

  readonly property bool hovered: mouseArea.containsMouse
  readonly property bool pressed: mouseArea.pressed

  signal clicked(var mouse)

  implicitWidth: root.buttonSize
  implicitHeight: root.buttonSize
  width: root.buttonSize
  height: root.buttonSize
  radius: Math.min(root.width, root.height) / 2
  antialiasing: true

  color: (root.enabled && root.hovered) ? root.hoverColour : root.baseColour
  // A transparent border and a zero-width border look identical, so derive the
  // width from the alpha instead of comparing colour values.
  border.width: (root.borderColour.a > 0 || root.hoverBorderColour.a > 0) ? Config.borderWidth : 0
  border.color: (root.enabled && root.hovered) ? root.hoverBorderColour : root.borderColour
  scale: !root.enabled ? 1.0 : (root.pressed ? 0.94 : (root.hovered ? root.hoverScale : 1.0))

  Behavior on color { ColorAnimation { duration: Config.animFastMs } }
  Behavior on border.color { ColorAnimation { duration: Config.animFastMs } }
  Behavior on scale { NumberAnimation { duration: Config.animFastMs; easing.type: Easing.OutBack } }

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
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: function(mouse) {
      if (mouse.button === Qt.LeftButton) root.clicked(mouse)
    }
  }
}
