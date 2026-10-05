pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Bluetooth

Pill {
  id: root

  property PanelWindow sharedWindow: null
  property string uiFont: Config.monoFont
  property bool showLabel: false

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool isPowered: adapter ? adapter.enabled : false

  readonly property var connectedDevicesList: {
    var list = []
    var devs = Bluetooth.devices ? Bluetooth.devices.values : []
    for (var i = 0; i < devs.length; i++) {
      if (devs[i] && devs[i].connected) {
        var n = devs[i].deviceName || devs[i].name || devs[i].address || ""
        if (n && list.indexOf(n) === -1) list.push(n)
      }
    }
    return list
  }

  readonly property bool isConnected: connectedDevicesList.length > 0
  readonly property string connectedDevice: isConnected ? connectedDevicesList[0] : ""

  property string btIcon: {
    if (root.isConnected) return "󰂱"
    if (root.isPowered) return "󰂯"
    return "󰂲"
  }

  property color btColour: (root.isConnected || root.isPowered) ? Colours.accent : Colours.fgDim

  property string statusText: {
    if (root.isConnected) {
      if (root.connectedDevicesList.length > 1) {
        var firstDev = root.connectedDevice !== "" ? root.connectedDevice : "Connected"
        if (firstDev.length > 10) firstDev = firstDev.substring(0, 9) + "…"
        return firstDev + " (+" + (root.connectedDevicesList.length - 1) + ")"
      }
      var dev = root.connectedDevice !== "" ? root.connectedDevice : "Connected"
      if (dev.length > 14) return dev.substring(0, 13) + "…"
      return dev
    }
    if (root.isPowered) return "On"
    return "Off"
  }

  pillHeight: showLabel ? 25 : 30
  padding: showLabel ? 6 : 0
  anchors.horizontalCenter: (parent && !showLabel) ? parent.horizontalCenter : undefined

  pillColour: btTooltip.hovered ? Colours.bgSubtle : Colours.bgRaised
  border.width: 1
  border.color: Colours.border

  Behavior on pillColour { ColorAnimation { duration: 120 } }
  Behavior on border.color { ColorAnimation { duration: 120 } }

  // Bar mode content (centred icon, pixelSize 18)
  Text {
    visible: !root.showLabel
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenter: parent.horizontalCenter
    text: root.btIcon
    color: root.btColour
    font.family: root.uiFont
    font.pixelSize: 18
  }

  // Pill / CommandCentre mode content (icon + text row, matching Wi-Fi & Battery layout)
  Row {
    id: labelRow
    visible: root.showLabel
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 4

    Text {
      text: root.btIcon
      color: root.btColour
      font.family: root.uiFont
      font.pixelSize: 12
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: root.statusText
      color: Colours.fg
      font.family: Config.sansFont
      font.pixelSize: 12
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  Tooltip {
    id: btTooltip
    visible: !root.showLabel
    target: root
    sharedWindow: root.sharedWindow
    icon: root.btIcon
    iconColour: root.btColour
    title: {
      if (root.isConnected) {
        if (root.connectedDevicesList.length > 1) {
          return root.connectedDevicesList.length + " Bluetooth Devices Connected"
        }
        return root.connectedDevice !== "" ? root.connectedDevice : "Bluetooth Connected"
      }
      if (root.isPowered) return "Bluetooth On"
      return "Bluetooth Off"
    }
    details: {
      var d = []
      if (root.isConnected && root.connectedDevicesList.length > 0) {
        d.push("Connected · " + root.connectedDevicesList.join(", "))
      }
      d.push("Left click · Toggle Power")
      d.push("Right click · Blueman Manager")
      return d
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function(mouse) {
      if (mouse.button === Qt.LeftButton) {
        if (root.adapter) {
          root.adapter.enabled = !root.adapter.enabled
        } else {
          Quickshell.execDetached(["bluetoothctl", "power", root.isPowered ? "off" : "on"])
        }
      } else {
        Quickshell.execDetached(Config.cmdBluetoothManager)
      }
    }
  }
}
