import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "Utils.js" as Utils

Pill {
  id: root

  property PanelWindow sharedWindow: null
  property string uiFont: Config.monoFont
  property bool horizontal: false

  visible: root.batPresent
  pillHeight: root.horizontal ? 24 : 30
  padding: root.horizontal ? 8 : 0
  orientation: root.horizontal ? Qt.Horizontal : Qt.Vertical
  anchors.horizontalCenter: (parent && !horizontal) ? parent.horizontalCenter : undefined

  pillColor: batTooltip.hovered ? Colors.bgSubtle : Colors.bgRaised
  border.width: 1
  border.color: Colors.border

  Behavior on pillColor { ColorAnimation { duration: 120 } }
  Behavior on border.color { ColorAnimation { duration: 120 } }

  // UPower State
  property var batDevice: Utils.findBatteryDevice(UPower.devices, UPower.displayDevice)


  readonly property bool batPresent:  batDevice !== null && batDevice.isLaptopBattery
  readonly property int  batPct:      root.batDevice ? Math.round(root.batDevice.percentage * 100) : 0
  readonly property bool batCharging: root.batDevice && root.batDevice.state === UPowerDeviceState.Charging
  readonly property bool batPlugged:  root.batDevice && root.batDevice.state === UPowerDeviceState.FullyCharged
  readonly property int  batState:    root.batDevice ? root.batDevice.state : UPowerDeviceState.Unknown

  property string batIcon: Utils.batteryIcon(root.batPct, root.batCharging, root.batPlugged, root.batPresent)
  property color  batColor: {
    if (!root.batPresent)                    return Colors.fg
    if (root.batCharging || root.batPlugged) return Colors.green
    if (root.batPct <= 15)                   return Colors.red
    if (root.batPct <= 30)                   return Colors.yellow
    return Colors.fg
  }

  Tooltip {
    id: batTooltip
    target: root
    sharedWindow: root.sharedWindow
    icon: root.batIcon
    iconColor: root.batColor
    title: {
      var pct = Math.round(root.batPct)
      var state
      switch (root.batState) {
        case UPowerDeviceState.Charging:         state = "Charging"; break
        case UPowerDeviceState.FullyCharged:     state = "Plugged in"; break
        case UPowerDeviceState.PendingCharge:    state = "Pending charge"; break
        case UPowerDeviceState.PendingDischarge: state = "Pending discharge"; break
        case UPowerDeviceState.Empty:            state = "Empty"; break
        default:                                 state = "Discharging"; break
      }
      return pct + "% · " + state
    }
    details: {
      var d = []
      if (root.batDevice) {
        if (root.batCharging && root.batDevice.timeToFull > 0) {
          var mins = Math.round(root.batDevice.timeToFull / 60)
          var h = Math.floor(mins / 60)
          var m = mins % 60
          d.push((h > 0 ? h + "h " : "") + m + "m until full")
        } else if (!root.batCharging && !root.batPlugged && root.batDevice.timeToEmpty > 0) {
          var mins2 = Math.round(root.batDevice.timeToEmpty / 60)
          var h2 = Math.floor(mins2 / 60)
          var m2 = mins2 % 60
          d.push((h2 > 0 ? h2 + "h " : "") + m2 + "m remaining")
        }
      }
      return d
    }
  }

  Row {
    anchors.centerIn: parent
    spacing: 4

    Text {
      text: root.batIcon
      color: root.batColor
      font.family: root.uiFont
      font.pixelSize: root.horizontal ? 14 : 18
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      visible: root.horizontal
      text: root.batPct + "%"
      color: root.batColor
      font.family: Config.sansFont
      font.pixelSize: 12
      font.bold: true
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
  }
}
