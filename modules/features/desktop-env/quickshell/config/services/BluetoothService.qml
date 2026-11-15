pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Bluetooth
import QtQuick
import ".."

// Bluetooth adapter and connected-device state.
Singleton {
  id: root

  readonly property var btAdapter: Bluetooth.defaultAdapter
  readonly property bool btPowered: !!(root.btAdapter && root.btAdapter.enabled)

  readonly property var btConnectedDevices: {
    var list = []
    var devs = (Bluetooth.devices && Bluetooth.devices.values) ? Bluetooth.devices.values : []
    for (var i = 0; i < devs.length; i++) {
      if (devs[i] && devs[i].connected) {
        var n = devs[i].deviceName || devs[i].name || devs[i].address || ""
        if (n && list.indexOf(n) === -1) list.push(n)
      }
    }
    return list
  }

  readonly property bool btConnected: root.btConnectedDevices.length > 0
  readonly property string btConnectedDevice: root.btConnected ? root.btConnectedDevices[0] : ""

  readonly property var btDevices: {
    var values = (Bluetooth.devices && Bluetooth.devices.values) ? Bluetooth.devices.values : []
    var list = []
    for (var i = 0; i < values.length; i++) {
      var device = values[i]
      if (device && (device.connected || device.paired)) list.push(device)
    }
    list.sort(function(a, b) {
      if (!!a.connected !== !!b.connected) return a.connected ? -1 : 1
      var an = (a.deviceName || a.name || a.address || "").toLowerCase()
      var bn = (b.deviceName || b.name || b.address || "").toLowerCase()
      return an < bn ? -1 : (an > bn ? 1 : 0)
    })
    return list
  }

  readonly property string btIcon: {
    if (root.btConnected) return "󰂱"
    if (root.btPowered) return "󰂯"
    return "󰂲"
  }

  readonly property color btColour: (root.btConnected || root.btPowered) ? Colours.accent : Colours.fgDim

  readonly property string btStatusText: {
    if (root.btConnected) {
      if (root.btConnectedDevices.length > 1) {
        var firstDev = root.btConnectedDevice !== "" ? root.btConnectedDevice : "Connected"
        if (firstDev.length > 10) firstDev = firstDev.substring(0, 9) + "…"
        return firstDev + " (+" + (root.btConnectedDevices.length - 1) + ")"
      }
      var dev = root.btConnectedDevice !== "" ? root.btConnectedDevice : "Connected"
      if (dev.length > 14) return dev.substring(0, 13) + "…"
      return dev
    }
    if (root.btPowered) return "On"
    return "Off"
  }

  readonly property string btTitle: {
    if (root.btConnected) {
      if (root.btConnectedDevices.length > 1) {
        return root.btConnectedDevices.length + " Bluetooth Devices Connected"
      }
      return root.btConnectedDevice !== "" ? root.btConnectedDevice : "Bluetooth Connected"
    }
    if (root.btPowered) return "Bluetooth On"
    return "Bluetooth Off"
  }

  readonly property var btDetails: {
    var d = []
    if (root.btConnected && root.btConnectedDevices.length > 0) {
      d.push("Connected · " + root.btConnectedDevices.join(", "))
    }
    d.push("Left click · Bluetooth menu")
    d.push("Right click · Blueman Manager")
    return d
  }

  function setBtPowered(on) {
    if (root.btAdapter) root.btAdapter.enabled = on
  }

  function toggleBtDevice(device) {
    if (!device) return
    if (device.connected) device.disconnect()
    else if (device.paired) device.connect()
    else device.pair()
  }

  function deviceBattery(device) {
    if (!device || !device.batteryAvailable) return ""
    var level = device.battery
    return (level <= 1 ? Math.round(level * 100) : Math.round(level)) + "%"
  }

  function openBluetoothManager() {
    Quickshell.execDetached(Config.cmdBluetoothManager)
  }
}
