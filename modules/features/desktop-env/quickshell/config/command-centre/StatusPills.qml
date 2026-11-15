pragma ComponentBehavior: Bound
import QtQuick
import ".."

// Network, battery and Bluetooth badges shown in the Command Centre header.
// The Bluetooth label only has room in the wider sidebar layout.
Row {
  id: root

  property bool showBluetoothLabel: false

  spacing: Config.spaceSm

  NetworkWidget {
    horizontal: true
    anchors.verticalCenter: parent.verticalCenter
  }

  BatteryWidget {
    horizontal: true
    anchors.verticalCenter: parent.verticalCenter
  }

  BluetoothWidget {
    horizontal: true
    showLabel: root.showBluetoothLabel
    labelMaxWidth: Config.wifiMaxTextLength
    anchors.verticalCenter: parent.verticalCenter
  }
}
