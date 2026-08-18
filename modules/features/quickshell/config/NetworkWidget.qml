import QtQuick
import Quickshell
import Quickshell.Networking
import "Utils.js" as Utils

Pill {
  id: root

  property PanelWindow sharedWindow: null
  property string uiFont: Config.monoFont
  property int maxTextWidth: Config.wifiMaxTextLength
  property bool horizontal: false

  // Networking state
  property var wiredDev: Utils.findFirst(Networking.devices.values, function(d) { return d.type === DeviceType.Wired })
  property var wifiDev:  Utils.findFirst(Networking.devices.values, function(d) { return d.type === DeviceType.Wifi })

  property bool isWired: root.wiredDev && root.wiredDev.connected
  property bool isWifi:  root.wifiDev  && root.wifiDev.connected

  property var wifiNet: Utils.findFirst(root.wifiDev ? root.wifiDev.networks.values : [], function(n) { return n.connected })
  property string wifiSsid: root.wifiNet ? root.wifiNet.name : ""

  property string netIcon: {
    if (root.isWired) return "󰈀"
    if (root.isWifi)  return "󰤨"
    return "󰤮"
  }

  property string netText: {
    if (root.isWired) return "Ethernet"
    if (root.isWifi)  return root.wifiSsid !== "" ? root.wifiSsid : "Wi-Fi"
    return "Offline"
  }

  property color netColor: (root.isWired || root.isWifi) ? Colors.accent : Colors.fgDim

  // Match Command Center Wi-Fi Pill styling
  pillHeight: root.horizontal ? 24 : 30
  padding: 8
  orientation: root.horizontal ? Qt.Horizontal : Qt.Vertical
  anchors.horizontalCenter: (parent && !horizontal) ? parent.horizontalCenter : undefined

  pillColor: netTooltip.hovered ? Colors.bgRaised : Colors.bgSubtle
  border.width: 1
  border.color: Colors.border

  Behavior on pillColor { ColorAnimation { duration: 120 } }
  Behavior on border.color { ColorAnimation { duration: 120 } }

  Row {
    id: labelRow
    anchors.centerIn: parent
    spacing: 4
    rotation: root.horizontal ? 0 : 270
    transformOrigin: Item.Center

    Text {
      text: root.netIcon
      color: root.netColor
      font.family: Config.monoFont
      font.pixelSize: 12
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: root.netText
      color: Colors.fg
      font.family: Config.sansFont
      font.pixelSize: 12
      elide: Text.ElideRight
      maximumLineCount: 1
      width: Math.min(implicitWidth, root.maxTextWidth)
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  Tooltip {
    id: netTooltip
    target: root
    sharedWindow: root.sharedWindow
    icon: root.netIcon
    iconColor: root.netColor
    title: {
      if (root.isWired) return "Wired (" + root.wiredDev.name + ")"
      if (root.isWifi)  return root.wifiSsid !== "" ? root.wifiSsid : "Connected"
      return "Disconnected"
    }
    details: {
      var d = []
      if (root.isWifi && root.wifiNet)
        d.push("Signal · " + Math.round(root.wifiNet.signalStrength * 100) + "%")
      d.push("Right click · nmtui")
      return d
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: Quickshell.execDetached(["kitty", "-e", "nmtui"])
  }
}
