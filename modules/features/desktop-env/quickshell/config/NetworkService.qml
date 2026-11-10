pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Networking
import QtQuick
import "Utils.js" as Utils

// Wired and Wi-Fi connection state for the bar and command centre.
Singleton {
  id: root

  readonly property var netDevices: (Networking.devices && Networking.devices.values) ? Networking.devices.values : []
  readonly property var wiredDev: Utils.findFirst(root.netDevices, function(d) { return d && d.type === DeviceType.Wired })
  readonly property var wifiDev: Utils.findFirst(root.netDevices, function(d) { return d && d.type === DeviceType.Wifi && d.connected })
    || Utils.findFirst(root.netDevices, function(d) { return d && d.type === DeviceType.Wifi })

  readonly property bool isWired: !!(root.wiredDev && root.wiredDev.connected)
  readonly property bool isWifi: !!(root.wifiDev && root.wifiDev.connected)
  readonly property var wifiNet: Utils.findFirst(root.wifiDev && root.wifiDev.networks ? root.wifiDev.networks.values : [], function(n) { return n && n.connected })
  readonly property string wifiSsid: root.wifiNet ? (root.wifiNet.name || "") : ""

  readonly property string netIcon: {
    if (root.isWired) return "󰈀"
    if (root.isWifi) return "󰤨"
    return "󰤮"
  }

  readonly property string netText: {
    if (root.isWired) return "Ethernet"
    if (root.isWifi) return root.wifiSsid !== "" ? root.wifiSsid : "Wi-Fi"
    return "Offline"
  }

  readonly property color netColour: (root.isWired || root.isWifi) ? Colours.accent : Colours.fgDim

  readonly property string netTitle: {
    if (root.isWired) return "Wired (" + root.wiredDev.name + ")"
    if (root.isWifi) return root.wifiSsid !== "" ? root.wifiSsid : "Connected"
    return "Disconnected"
  }

  readonly property var netDetails: {
    var d = []
    if (root.isWifi && root.wifiNet) {
      d.push("Signal · " + Math.round(root.wifiNet.signalStrength * 100) + "%")
    }
    d.push("Click · nmtui")
    return d
  }

  function openNetworkManager() {
    Quickshell.execDetached(Config.cmdNetworkManager)
  }
}
