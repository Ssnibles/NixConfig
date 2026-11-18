pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../Utils.js" as Utils
import ".."

// Wi-Fi network list shown from the network pill and the command centre.
ColumnLayout {
  id: root

  property var pendingNetwork: null
  property string password: ""

  anchors.fill: parent
  anchors.margins: Config.spaceLg
  spacing: Config.spaceLg
  focus: true

  Component.onCompleted: NetworkService.scanWifi()

  function selectNetwork(network) {
    if (!network) return
    root.pendingNetwork = null
    root.password = ""
    if (network.connected) {
      NetworkService.disconnectNetwork(network)
      return
    }
    if (!network.known && NetworkService.isSecured(network)) {
      root.pendingNetwork = network
      root.password = ""
      passwordInput.text = ""
      return
    }
    NetworkService.connectNetwork(network)
  }

  function submitPassword() {
    if (!root.pendingNetwork) return
    NetworkService.connectNetwork(root.pendingNetwork, root.password)
    root.pendingNetwork = null
    root.password = ""
    passwordInput.text = ""
    root.forceActiveFocus()
  }

  function cancelPassword() {
    root.pendingNetwork = null
    root.password = ""
    passwordInput.text = ""
    UiState.closeStatusMenu()
  }

  MenuHeader {
    icon: "󰤨"
    iconColour: Colours.accent
    title: "Network"

    IconButton {
      buttonSize: Config.spaceXl + Config.space2xs
      iconSize: Config.iconSizeSm
      icon: "󰑐"
      onClicked: NetworkService.scanWifi()
    }
  }

  Item {
    Layout.fillWidth: true
    Layout.fillHeight: true

    ListView {
      id: networkList
      anchors.fill: parent
      visible: count > 0
      clip: true
      spacing: Config.spaceSm
      model: NetworkService.wifiNetworks

      delegate: Rectangle {
        id: networkRow
        required property var modelData

        width: networkList.width - networkBar.gutter
        height: Config.space2xl + Config.spaceMd
        radius: Config.itemRadiusSm
        color: rowMouse.containsMouse ? Colours.bgSubtle : "transparent"

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: Config.spaceLg
          anchors.rightMargin: Config.spaceLg
          spacing: Config.spaceMd

          Text {
            text: Utils.wifiSignalIcon(networkRow.modelData.signalStrength)
            color: networkRow.modelData.connected ? Colours.accent : Colours.fgMid
            font.family: Session.monoFont
            font.pixelSize: Config.fontSizeMd
          }

          Text {
            Layout.fillWidth: true
            text: networkRow.modelData.name
            color: Colours.fg
            font.family: Session.sansFont
            font.pixelSize: Config.fontSizeMd
            font.bold: networkRow.modelData.connected
            elide: Text.ElideRight
          }

          Text {
            visible: NetworkService.isSecured(networkRow.modelData)
            text: "󰌾"
            color: Colours.fgDim
            font.family: Session.monoFont
            font.pixelSize: Config.iconSizeSm
          }

          Text {
            visible: networkRow.modelData.connected
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
          onClicked: root.selectNetwork(networkRow.modelData)
        }
      }
    }

    ThinScrollBar {
      id: networkBar
      view: networkList
    }

    Text {
      anchors.centerIn: parent
      visible: networkList.count === 0
      text: NetworkService.wifiAvailable ? "No networks found" : "Wi-Fi unavailable"
      color: Colours.fgDim
      font.family: Session.sansFont
      font.pixelSize: Config.fontSizeSm
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    visible: root.pendingNetwork !== null
    spacing: Config.spaceXs

    onVisibleChanged: {
      if (!visible) return
      passwordInput.text = ""
      root.password = ""
      passwordInput.forceActiveFocus()
    }

    Text {
      Layout.fillWidth: true
      text: "Password for " + (root.pendingNetwork ? root.pendingNetwork.name : "")
      color: Colours.fgMid
      font.family: Session.sansFont
      font.pixelSize: Config.fontSizeSm
      elide: Text.ElideRight
    }

    RowLayout {
      spacing: Config.spaceSm

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Config.space2xl
        radius: Config.itemRadiusSm
        color: Colours.bgSubtle
        border.width: Config.borderWidth
        border.color: passwordInput.activeFocus ? Colours.accent : Colours.border

        TextInput {
          id: passwordInput
          anchors.fill: parent
          anchors.leftMargin: Config.spaceMd
          anchors.rightMargin: Config.spaceMd
          verticalAlignment: TextInput.AlignVCenter
          echoMode: TextInput.Password
          color: Colours.fg
          selectionColor: Colours.accent
          selectedTextColor: Colours.bg
          font.family: Session.sansFont
          font.pixelSize: Config.fontSizeMd
          onTextChanged: root.password = text
          onAccepted: root.submitPassword()
          Keys.onEscapePressed: function(event) {
            root.cancelPassword()
            event.accepted = true
          }
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          anchors.left: parent.left
          anchors.leftMargin: Config.spaceMd
          visible: passwordInput.text === ""
          text: "Password"
          color: Colours.fgDim
          font.family: Session.sansFont
          font.pixelSize: Config.fontSizeMd
        }
      }

      IconButton {
        buttonSize: Config.spaceXl + Config.space2xs
        radius: Config.itemRadiusSm
        icon: "󰄬"
        iconColour: Colours.accent
        Layout.alignment: Qt.AlignVCenter
        onClicked: root.submitPassword()
      }

      IconButton {
        buttonSize: Config.spaceXl + Config.space2xs
        radius: Config.itemRadiusSm
        icon: "󰅖"
        Layout.alignment: Qt.AlignVCenter
        onClicked: root.cancelPassword()
      }
    }
  }

  MenuFooterButton {
    label: "Open network manager"
    onClicked: {
      UiState.closeStatusMenu()
      NetworkService.openNetworkManager()
    }
  }
}
