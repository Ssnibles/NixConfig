import QtQuick
import Quickshell
import Quickshell.Networking
import "Utils.js" as Utils

Pill {
  id: root

  property PanelWindow sharedWindow: null
  property string uiFont: Config.monoFont

  padding: 4
  anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined

  // Networking state
  property var wiredDev: Utils.findFirst(Networking.devices.values, function(d) { return d.type === DeviceType.Wired })
  property var wifiDev: Utils.findFirst(Networking.devices.values, function(d) { return d.type === DeviceType.Wifi })

  property bool isWired: root.wiredDev && root.wiredDev.connected
  property bool isWifi: root.wifiDev && root.wifiDev.connected

  property var wifiNet: Utils.findFirst(root.wifiDev ? root.wifiDev.networks.values : [], function(n) { return n.connected })
  property string wifiSsid: root.wifiNet ? root.wifiNet.name : ""

  property string netIcon: {
    if (root.isWired) return "󰈀"
    if (root.isWifi) return Utils.wifiIcon(root.wifiNet ? root.wifiNet.signalStrength : 0, true)
    return "󰤮"
  }

  property color netColor: (root.isWired || root.isWifi) ? Colors.accent : Colors.fgDim

  Tooltip {
    target: root
    sharedWindow: root.sharedWindow
    icon: root.netIcon
    iconColor: root.netColor
    title: {
      if (root.isWired) return "Wired Connection (" + root.wiredDev.name + ")"
      if (root.isWifi) return root.wifiNet ? root.wifiNet.name : "Connected"
      return "Disconnected"
    }
    details: {
      var d = []
      if (root.isWifi && root.wifiNet) {
        d.push("Signal · " + Math.round(root.wifiNet.signalStrength * 100) + "%")
      }
      d.push("Right click · nmtui")
      return d
    }
  }

  Text {
    text: root.netIcon
    color: root.netColor
    font.family: root.uiFont
    font.pixelSize: 12
    anchors.centerIn: parent
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.RightButton
    onClicked: Quickshell.execDetached(["kitty", "-e", "nmtui"])
  }
}
