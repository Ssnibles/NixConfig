pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import ".."

// Rounded overlay scrollbar for list views. It only shows while the content
// overflows, so short lists keep their full width. Lists reserve `gutter` on
// the right, which drops to zero with the bar, so row highlights stop before a
// visible bar and nothing is held back when there is none.
ScrollBar {
  id: root

  readonly property int gutter: root.overflows ? Config.scrollBarWidth + Config.spaceXs : 0

  readonly property Flickable view: root.parent as Flickable
  // AsNeeded still leaves the bar visible when the list fits, so the policy is
  // forced off unless the content actually has somewhere to scroll.
  readonly property bool overflows: root.view !== null
    && root.view.contentHeight + root.view.topMargin + root.view.bottomMargin > root.view.height + 0.5

  policy: root.overflows ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
  width: Config.scrollBarWidth
  // Qt places the bar once when it attaches to the list, so a list that is
  // still being sized leaves the bar behind. Track the right edge directly.
  x: root.view !== null ? root.view.width - root.width : 0

  contentItem: Rectangle {
    id: thumb

    implicitWidth: Config.scrollBarWidth
    radius: width / 2
    color: Colours.fgMid

    // The pill keeps one colour; hovering only thickens it into the gutter.
    // It grows from its right edge so it never spills out of the list.
    transform: Scale {
      origin.x: thumb.width
      origin.y: 0
      xScale: root.hovered ? 1.5 : 1
      Behavior on xScale { NumberAnimation { duration: Config.animFastMs; easing.type: Easing.OutCubic } }
    }
  }
}
