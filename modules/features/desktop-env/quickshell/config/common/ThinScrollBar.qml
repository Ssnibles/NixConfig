pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import ".."

// Rounded overlay scrollbar for list views. It only appears when the content
// overflows, so short lists keep their full width. Lists reserve `gutter` on
// the right so row highlights stop before the bar.
ScrollBar {
  id: root

  readonly property int gutter: Config.scrollBarWidth + Config.spaceXs

  policy: ScrollBar.AsNeeded
  width: Config.scrollBarWidth

  contentItem: Rectangle {
    implicitWidth: Config.scrollBarWidth
    radius: width / 2
    color: root.pressed
      ? Colours.accent
      : (root.hovered ? Colours.fg : Colours.fgMid)
  }
}
