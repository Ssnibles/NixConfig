import QtQuick
import Quickshell
import Quickshell.Io
import "Utils.js" as Utils

Pill {
  id: root

  property PanelWindow sharedWindow: null
  property string uiFont: Config.monoFont
  property bool showLabel: false

  property bool isPowered: false
  property bool isConnected: false
  property string connectedDevice: ""
  property var connectedDevicesList: []

  property string btIcon: {
    if (root.isConnected) return "󰂱"
    if (root.isPowered) return "󰂯"
    return "󰂲"
  }

  property color btColor: (root.isConnected || root.isPowered) ? Colors.accent : Colors.fgDim

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

  pillColor: btTooltip.hovered ? Colors.bgSubtle : Colors.bgRaised
  border.width: 1
  border.color: Colors.border

  Behavior on pillColor { ColorAnimation { duration: 120 } }
  Behavior on border.color { ColorAnimation { duration: 120 } }

  // Process to check bluetooth status via bluetoothctl
  Process {
    id: showProc
    stdout: StdioCollector {
      onDataChanged: {
        var text = this.text || ""
        root.isPowered = text.indexOf("Powered: yes") !== -1
        if (root.isPowered) {
          connProc.exec(["bluetoothctl", "devices", "Connected"])
        } else {
          root.isConnected = false
          root.connectedDevice = ""
          root.connectedDevicesList = []
        }
      }
    }
  }

  Process {
    id: connProc
    stdout: StdioCollector {
      onDataChanged: {
        var text = this.text || ""
        var lines = text.trim().split("\n")
        var devices = []
        for (var i = 0; i < lines.length; i++) {
          var line = lines[i].trim()
          if (line !== "") {
            var parts = line.split(" ")
            if (parts.length >= 3) {
              devices.push(parts.slice(2).join(" "))
            }
          }
        }
        if (devices.length > 0) {
          root.isConnected = true
          root.connectedDevicesList = devices
          root.connectedDevice = devices[0]
        } else {
          root.isConnected = false
          root.connectedDevicesList = []
          root.connectedDevice = ""
        }
      }
    }
  }

  // Persistent monitor process to receive bluetoothctl event output without polling
  Process {
    id: monitorProc
    command: ["bluetoothctl"]
    running: true
    stdout: StdioCollector {
      onDataChanged: {
        refreshTimer.restart()
      }
    }
  }

  Timer {
    id: refreshTimer
    interval: 150
    repeat: false
    onTriggered: {
      showProc.exec(["bluetoothctl", "show"])
    }
  }

  Timer {
    id: delayedRefreshTimer
    interval: 400
    repeat: false
    onTriggered: {
      showProc.exec(["bluetoothctl", "show"])
    }
  }

  Component.onCompleted: {
    showProc.exec(["bluetoothctl", "show"])
  }

  // Bar mode content (centered icon, pixelSize 18)
  Text {
    visible: !root.showLabel
    anchors.verticalCenter: parent.verticalCenter
    text: root.btIcon
    color: root.btColor
    font.family: root.uiFont
    font.pixelSize: 18
  }

  // Pill / CommandCenter mode content (icon + text row, matching Wi-Fi & Battery layout)
  Row {
    id: labelRow
    visible: root.showLabel
    anchors.verticalCenter: parent.verticalCenter
    spacing: 4

    Text {
      text: root.btIcon
      color: root.btColor
      font.family: root.uiFont
      font.pixelSize: 12
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: root.statusText
      color: Colors.fg
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
    iconColor: root.btColor
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
        root.isPowered = !root.isPowered
        Quickshell.execDetached(["bluetoothctl", "power", root.isPowered ? "on" : "off"])
        delayedRefreshTimer.restart()
      } else {
        Quickshell.execDetached(["blueman-manager"])
      }
    }
  }
}
