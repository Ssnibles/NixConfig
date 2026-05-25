import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQml
import "colors.js" as Colors

PanelWindow {
  id: barPanel
  focusable: false
  aboveWindows: true

  anchors { top: true; left: true; right: true }
  height: 30
  exclusionMode: ExclusionMode.Auto
  color: Colors.bg

  property string timeStr: ""

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: {
      var d = new Date();
      barPanel.timeStr = d.getHours().toString().padStart(2,'0') + ":" + d.getMinutes().toString().padStart(2,'0');
    }
  }

  function formatTitle(t) {
    return t
      .replace(/ — Mozilla Firefox$/, "")
      .replace(/ — Zen Browser$/, "Zen")
      .replace(/ - Neovim$/, "Neovim")
      .replace(/ - foot$/, "");
  }

  property string currentTitle: Hyprland.activeToplevel ? formatTitle(Hyprland.activeToplevel.title) : ""

  function switchWs(id) {
    Hyprland.dispatch("workspace " + id);
  }

  IpcHandler {
    target: "bar"
    function toggle(): void { barPanel.visible = !barPanel.visible; }
    function show(): void   { barPanel.visible = true; }
    function hide(): void   { barPanel.visible = false; }
  }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 8
    anchors.rightMargin: 10
    spacing: 6

    Row {
      Layout.alignment: Qt.AlignLeft
      spacing: 3
      Repeater {
        model: Hyprland.workspaces
        delegate: Rectangle {
          required property var modelData
          width: 24; height: 24
          radius: 4
          color: modelData.focused ? Colors.accent : Colors.bgSubtle
          border.color: modelData.focused ? Colors.accent : Colors.border
          border.width: 1
          anchors.verticalCenter: parent.verticalCenter

          Text {
            anchors.centerIn: parent
            text: modelData.id
            color: modelData.focused ? Colors.bg : Colors.fgDim
            font.family: "JetBrains Mono"
            font.pixelSize: 11
            font.bold: true
          }

          MouseArea {
            anchors.fill: parent
            onClicked: modelData.activate()
          }
        }
      }
    }

    Rectangle {
      width: 1; height: 18
      color: Colors.border
      Layout.alignment: Qt.AlignLeft
    }

    Text {
      Layout.fillWidth: true
      text: barPanel.currentTitle
      color: Colors.fgMid
      font.family: "JetBrains Mono"
      font.pixelSize: 12
      elide: Text.ElideRight
      horizontalAlignment: Text.AlignLeft
    }

    Text {
      text: barPanel.timeStr
      color: Colors.fg
      font.family: "JetBrains Mono"
      font.pixelSize: 13
      font.bold: true
    }
  }
}
