import QtQuick
import Quickshell
import Quickshell.Networking
import "Utils.js" as Utils

Pill {
  id: root

  property PanelWindow sharedWindow: null
  property string uiFont: "JetBrainsMono Nerd Font"

  padding: 4
  anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined

  // Networking state
  property var wifiDev: Utils.findFirst(Networking.devices.values, function(d) { return d.type === DeviceType.Wifi })
  property var wifiNet: Utils.findFirst(root.wifiDev ? root.wifiDev.networks.values : [], function(n) { return n.connected })
  property string wifiSsid: root.wifiNet ? root.wifiNet.name : ""
  property string wifiIcon: Utils.wifiIcon(root.wifiNet ? root.wifiNet.signalStrength : 0, !!root.wifiNet)

  Tooltip {
    target: root
    sharedWindow: root.sharedWindow
    icon: root.wifiIcon
    iconColor: root.wifiNet ? Colors.accent : Colors.fgDim
    title: root.wifiNet ? root.wifiNet.name : "Disconnected"
    details: {
      var d = []
      if (root.wifiNet) d.push("Signal · " + Math.round(root.wifiNet.signalStrength * 100) + "%")
      d.push("Right click · nmtui")
      return d
    }
  }

  Text {
    text: root.wifiIcon
    color: root.wifiNet ? Colors.accent : Colors.fgDim
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
