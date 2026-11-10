pragma ComponentBehavior: Bound
import QtQuick
import "Utils.js" as Utils

// Lock screen status pills, either clustered in one corner or split across all four.
Item {
  id: root

  readonly property bool isStatusSplit: Config.lockStatusPosition === "split" || Config.lockStatusPosition === "corners"
  readonly property var pos: Utils.parseOverlayPosition(Config.lockStatusPosition, "top-right")

  Row {
    id: statusCluster
    visible: !root.isStatusSplit
    spacing: Config.lockStatusSpacing
    z: 10

    anchors.top: root.pos.onBottom ? undefined : root.top
    anchors.bottom: root.pos.onBottom ? root.bottom : undefined
    anchors.left: root.pos.onLeft ? root.left : undefined
    anchors.right: root.pos.onLeft ? undefined : root.right
    anchors.margins: Config.lockStatusMargin

    // Hostname Pill
    HostnamePill { }

    // Network Widget Pill
    NetworkWidget {
      horizontal: true
      interactive: false
    }

    // Battery Widget Pill
    BatteryWidget {
      id: lockClusterBattery
      visible: lockClusterBattery.batPresent
      horizontal: true
      interactive: false
    }

    // Volume & Mute Status Pill
    VolumePill { }
  }

  // Top Left Hostname / System Status (when Config.lockStatusPosition is "split" or "corners")
  HostnamePill {
    visible: root.isStatusSplit
    anchors.left: root.left
    anchors.top: root.top
    anchors.margins: Config.lockStatusMargin
    z: 10
  }

  // Top Right Volume & Mute Status (when Config.lockStatusPosition is "split" or "corners")
  VolumePill {
    visible: root.isStatusSplit
    anchors.right: root.right
    anchors.top: root.top
    anchors.margins: Config.lockStatusMargin
    z: 10
  }

  // Bottom Left Wi-Fi / Network Status (when Config.lockStatusPosition is "split" or "corners")
  NetworkWidget {
    visible: root.isStatusSplit
    horizontal: true
    interactive: false
    anchors.left: root.left
    anchors.bottom: root.bottom
    anchors.margins: Config.lockStatusMargin
    z: 10
  }

  // Bottom Right Battery Status (when Config.lockStatusPosition is "split" or "corners")
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
