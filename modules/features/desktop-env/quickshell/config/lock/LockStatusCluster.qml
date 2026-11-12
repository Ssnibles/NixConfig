pragma ComponentBehavior: Bound
import QtQuick
import "../Utils.js" as Utils
import ".."

// Lock screen status badges, either clustered in one corner or split across all
// four corners of the screen.
Item {
  id: root

  readonly property bool isStatusSplit: Session.lockStatusPosition === "split" || Session.lockStatusPosition === "corners"
  readonly property var pos: Utils.parseOverlayPosition(Session.lockStatusPosition, "top-right")

  Row {
    // Match the bar's status order, with the lock-only hostname first.
    visible: !root.isStatusSplit
    spacing: Config.lockStatusSpacing
    z: 10

    anchors.top: root.pos.onBottom ? undefined : root.top
    anchors.bottom: root.pos.onBottom ? root.bottom : undefined
    anchors.left: root.pos.onLeft ? root.left : undefined
    anchors.right: root.pos.onLeft ? undefined : root.right
    anchors.margins: Config.lockStatusMargin

    HostnamePill { }

    VolumePill { }

    NetworkWidget {
      horizontal: true
      interactive: false
      labelColour: Colours.fgMid
    }

    BatteryWidget {
      horizontal: true
      interactive: false
    }
  }

  // Split layout: one badge per corner.
  HostnamePill {
    visible: root.isStatusSplit
    anchors.left: root.left
    anchors.top: root.top
    anchors.margins: Config.lockStatusMargin
    z: 10
  }

  VolumePill {
    visible: root.isStatusSplit
    anchors.right: root.right
    anchors.top: root.top
    anchors.margins: Config.lockStatusMargin
    z: 10
  }

  NetworkWidget {
    visible: root.isStatusSplit
    horizontal: true
    interactive: false
    labelColour: Colours.fgMid
    anchors.left: root.left
    anchors.bottom: root.bottom
    anchors.margins: Config.lockStatusMargin
    z: 10
  }

  BatteryWidget {
    id: lockSplitBattery
    visible: root.isStatusSplit && lockSplitBattery.batPresent
    horizontal: true
    interactive: false
    anchors.right: root.right
    anchors.bottom: root.bottom
    anchors.margins: Config.lockStatusMargin
    z: 10
  }
}
