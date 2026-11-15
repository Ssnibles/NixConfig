pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

// Paired Bluetooth devices shown from the Bluetooth pill and the command centre.
ColumnLayout {
  id: root

  anchors.fill: parent
  anchors.margins: Config.spaceLg
  spacing: Config.spaceMd

  RowLayout {
    Layout.fillWidth: true
    spacing: Config.spaceSm

    Text {
      text: BluetoothService.btIcon
      color: BluetoothService.btColour
      font.family: Session.monoFont
      font.pixelSize: Config.iconSizeLg
    }

    Text {
      Layout.fillWidth: true
      text: "Bluetooth"
      color: Colours.fg
      font.family: Session.sansFont
      font.pixelSize: Config.fontSizeLg
      font.bold: true
    }

    Pill {
      pillHeight: Config.pillHeightHorizontal
      padding: Config.spaceSm
      baseColour: BluetoothService.btPowered ? Colours.bgSubtle : "transparent"
      hoverColour: Colours.bgSubtle
      border.color: BluetoothService.btPowered ? Colours.accent : Colours.border
      hoverHighlight: true
      clickable: true
      onClicked: BluetoothService.setBtPowered(!BluetoothService.btPowered)

      Text {
        anchors.centerIn: parent
        text: BluetoothService.btPowered ? "On" : "Off"
        color: BluetoothService.btPowered ? Colours.fg : Colours.fgMid
        font.family: Session.sansFont
        font.pixelSize: Config.fontSizeSm
      }
    }

    IconButton {
      buttonSize: Config.spaceXl + Config.space2xs
      iconSize: Config.iconSizeSm
      icon: "󰅖"
      onClicked: UiState.closeStatusMenu()
    }
  }

  Item {
    Layout.fillWidth: true
    Layout.fillHeight: true

    ListView {
      id: deviceList
      anchors.fill: parent
      visible: count > 0 && BluetoothService.btPowered
      clip: true
      spacing: Config.space2xs
      model: BluetoothService.btDevices

      ScrollBar.vertical: ThinScrollBar { }

      delegate: Rectangle {
        id: deviceRow
        required property var modelData

        width: deviceList.width
        height: Config.space2xl + Config.spaceSm
        radius: Config.itemRadiusSm
        color: rowMouse.containsMouse ? Colours.bgSubtle : "transparent"

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: Config.spaceMd
          anchors.rightMargin: Config.spaceMd
          spacing: Config.spaceMd

          Text {
            text: "󰂯"
            color: deviceRow.modelData.connected ? Colours.accent : Colours.fgMid
            font.family: Session.monoFont
            font.pixelSize: Config.fontSizeMd
          }

          Text {
            Layout.fillWidth: true
            text: deviceRow.modelData.deviceName || deviceRow.modelData.name || deviceRow.modelData.address
            color: Colours.fg
            font.family: Session.sansFont
            font.pixelSize: Config.fontSizeMd
            font.bold: deviceRow.modelData.connected
            elide: Text.ElideRight
          }

          Text {
            visible: deviceRow.modelData.batteryAvailable
            text: BluetoothService.deviceBattery(deviceRow.modelData)
            color: Colours.fgDim
            font.family: Session.sansFont
            font.pixelSize: Config.fontSizeXs
          }

          Text {
            visible: deviceRow.modelData.connected
            text: "󰄬"
            color: Colours.accent
            font.family: Session.monoFont
            font.pixelSize: Config.iconSizeSm
          }
        }

        MouseArea {
          id: rowMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: BluetoothService.toggleBtDevice(deviceRow.modelData)
        }
      }
    }

    Text {
      anchors.centerIn: parent
      visible: deviceList.count === 0 || !BluetoothService.btPowered
      text: BluetoothService.btPowered ? "No paired devices" : "Bluetooth is off"
      color: Colours.fgDim
      font.family: Session.sansFont
      font.pixelSize: Config.fontSizeSm
    }
  }

  Pill {
    Layout.fillWidth: true
    pillHeight: Config.spaceXl + Config.space2xs
    padding: Config.spaceSm
    baseColour: Colours.bgSubtle
    hoverColour: Colours.bgRaised
    hoverHighlight: true
    border.color: Colours.border
    clickable: true
    onClicked: {
      UiState.closeStatusMenu()
      BluetoothService.openBluetoothManager()
    }

    Row {
      anchors.centerIn: parent
      spacing: Config.spaceSm

      Text {
        text: "󰒓"
        color: Colours.fgDim
        font.family: Session.monoFont
        font.pixelSize: Config.iconSizeSm
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: "Open Bluetooth manager"
        color: Colours.fgMid
        font.family: Session.sansFont
        font.pixelSize: Config.fontSizeSm
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }
}
