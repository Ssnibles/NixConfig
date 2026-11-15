pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Networking
import QtQuick
import "../Utils.js" as Utils
import ".."

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

  readonly property bool wifiAvailable: root.wifiDev !== null
  readonly property var wifiNetworks: {
    if (!root.wifiDev || !root.wifiDev.networks) return []
    var values = root.wifiDev.networks.values || []
    var list = []
    for (var i = 0; i < values.length; i++) list.push(values[i])
    list.sort(function(a, b) {
      if (!!a.connected !== !!b.connected) return a.connected ? -1 : 1
      return (b.signalStrength || 0) - (a.signalStrength || 0)
    })
    return list
  }

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
    d.push("Left click · Network menu")
    d.push("Right click · nmtui")
    return d
  }

  function isSecured(network) {
    return !!network && network.security !== WifiSecurityType.Open
  }

  function connectNetwork(network, psk) {
    if (!network) return
    if (psk !== undefined && psk !== "") network.connectWithPsk(psk)
    else network.connect()
  }

  function disconnectNetwork(network) {
    if (network) network.disconnect()
  }

  function scanWifi() {
    if (!root.wifiDev) return
    root.wifiDev.scannerEnabled = false
    Qt.callLater(function() {
      if (root.wifiDev) root.wifiDev.scannerEnabled = true
    })
  }

  function openNetworkManager() {
    Quickshell.execDetached(Config.cmdNetworkManager)
  }
}
