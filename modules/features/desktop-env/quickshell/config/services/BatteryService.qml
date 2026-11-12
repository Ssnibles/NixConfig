pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.UPower
import QtQuick
import "../Utils.js" as Utils
import ".."

// Laptop battery state from UPower.
Singleton {
  id: root

  readonly property var batDevice: Utils.findBatteryDevice(UPower.devices, UPower.displayDevice)
  readonly property bool batPresent: root.batDevice !== null && root.batDevice.isLaptopBattery
  readonly property int batPct: root.batDevice ? Math.round(root.batDevice.percentage * 100) : 0
  readonly property bool batCharging: !!(root.batDevice && root.batDevice.state === UPowerDeviceState.Charging)
  readonly property bool batPlugged: !!(root.batDevice && root.batDevice.state === UPowerDeviceState.FullyCharged)
  readonly property int batState: root.batDevice ? root.batDevice.state : UPowerDeviceState.Unknown
  readonly property string batIcon: Utils.batteryIcon(root.batPct, root.batCharging, root.batPlugged, root.batPresent)

  readonly property color batColour: {
    if (!root.batPresent) return Colours.fg
    if (root.batCharging || root.batPlugged) return Colours.green
    if (root.batPct <= 15) return Colours.red
    if (root.batPct <= 30) return Colours.yellow
    return Colours.fg
  }

  readonly property string batTitle: {
    var state
    switch (root.batState) {
      case UPowerDeviceState.Charging:         state = "Charging"; break
      case UPowerDeviceState.FullyCharged:     state = "Plugged in"; break
      case UPowerDeviceState.PendingCharge:    state = "Pending charge"; break
      case UPowerDeviceState.PendingDischarge: state = "Pending discharge"; break
      case UPowerDeviceState.Empty:            state = "Empty"; break
      default:                                 state = "Discharging"; break
    }
    return root.batPct + "% · " + state
  }

  readonly property var batDetails: {
    var d = []
    if (root.batDevice) {
      if (root.batCharging && root.batDevice.timeToFull > 0) {
        let mins = Math.round(root.batDevice.timeToFull / 60)
        let h = Math.floor(mins / 60)
        let m = mins % 60
        d.push((h > 0 ? h + "h " : "") + m + "m until full")
      } else if (!root.batCharging && !root.batPlugged && root.batDevice.timeToEmpty > 0) {
        let mins2 = Math.round(root.batDevice.timeToEmpty / 60)
        let h2 = Math.floor(mins2 / 60)
        let m2 = mins2 % 60
        d.push((h2 > 0 ? h2 + "h " : "") + m2 + "m remaining")
      }
    }
    return d
  }
}
