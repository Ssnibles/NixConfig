pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."

// Centred network and Bluetooth menus, opened from the status pills. The card
// takes keyboard focus so the Wi-Fi password field works, and Escape or a click
// outside closes it.
Scope {
  id: root

  // The bar and Command Centre both track the cursor's screen, so this stays
  // stable while the menu is open.
  readonly property var screen: UiState.lastActiveScreen
    || (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

  Variants {
    model: UiState.statusMenu !== "" && root.screen ? [root.screen] : []

    delegate: PanelWindow {
      id: panel
      required property var modelData
      screen: modelData

      anchors.top: true
      anchors.bottom: true
      anchors.left: true
      anchors.right: true
      color: "transparent"
      aboveWindows: true
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
      exclusionMode: ExclusionMode.Ignore
      visible: true

      MouseArea {
        anchors.fill: parent
        onClicked: UiState.closeStatusMenu()
      }

      Card {
        id: menuCard
        anchors.centerIn: parent
        width: Config.statusMenuWidth
        height: Config.statusMenuHeight
        cardColour: Colours.bg
        cardRadius: Config.commandCentreRadius
        focus: true

        Component.onCompleted: forceActiveFocus()

        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            UiState.closeStatusMenu()
            event.accepted = true
          }
        }

        MouseArea {
          anchors.fill: parent
          onClicked: function(mouse) { mouse.accepted = true }
        }

        Loader {
          anchors.fill: parent
          sourceComponent: UiState.statusMenu === "network" ? networkMenuComponent : bluetoothMenuComponent
        }
      }
    }
  }

  Component {
    id: networkMenuComponent

    NetworkMenu { }
  }

  Component {
    id: bluetoothMenuComponent

    BluetoothMenu { }
  }
}
