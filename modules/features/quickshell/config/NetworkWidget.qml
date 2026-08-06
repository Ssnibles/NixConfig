import QtQuick
import Quickshell
import Quickshell.Networking
import "Utils.js" as Utils

Pill {
  id: root

  property PanelWindow sharedWindow: null
  property string uiFont: Config.monoFont

  // Bar is 38px wide — keep icon-only so nothing overflows.
  pillHeight: 30
  padding: 0
  anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined

  pillColor: Colors.bgRaised
  border.width: 1
  border.color: (root.isWired || root.isWifi)
                  ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.5)
                  : Colors.border

  // Networking state
  property var wiredDev: Utils.findFirst(Networking.devices.values, function(d) { return d.type === DeviceType.Wired })
  property var wifiDev:  Utils.findFirst(Networking.devices.values, function(d) { return d.type === DeviceType.Wifi })

  property bool isWired: root.wiredDev && root.wiredDev.connected
  property bool isWifi:  root.wifiDev  && root.wifiDev.connected

  property var wifiNet: Utils.findFirst(root.wifiDev ? root.wifiDev.networks.values : [], function(n) { return n.connected })
  property string wifiSsid: root.wifiNet ? root.wifiNet.name : ""

  property string netIcon: {
    if (root.isWired) return "󰈀"
    if (root.isWifi)  return Utils.wifiIcon(root.wifiNet ? root.wifiNet.signalStrength : 0, true)
    return "󰤮"
  }

  property color netColor: (root.isWired || root.isWifi) ? Colors.accent : Colors.fgDim

  Tooltip {
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

  Text {
    // Use absolute centering rather than relying on the contentItem anchor layout
    x: (root.width  - implicitWidth)  / 2
    y: (root.height - implicitHeight) / 2
    text: root.netIcon
    color: root.netColor
    font.family: root.uiFont
    font.pixelSize: 15
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.RightButton
    onClicked: Quickshell.execDetached(["kitty", "-e", "nmtui"])
  }
}
