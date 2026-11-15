pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import ".."

// Thin overlay scrollbar for list views. It only appears when the content
// overflows, so short lists keep their full width.
ScrollBar {
  id: root

  policy: ScrollBar.AsNeeded
  width: Config.spaceSm

  contentItem: Rectangle {
    implicitWidth: Config.spaceSm
    radius: width / 2
    color: root.pressed
      ? Colours.accent
      : (root.hovered ? Colours.fgMid : Colours.fgDim)
  }
}
