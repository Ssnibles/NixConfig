import Quickshell
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

  property var wsMap: ({})
  property var wsList: []
  property int currentWs: 1
  property string currentTitle: ""
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

  Component.onCompleted: poll()

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: poll()
  }

  function poll() {
    wsQuery.running = true;
    wsActive.running = true;
    winQuery.running = true;
  }

  Process {
    id: wsQuery
    command: ["hyprctl", "workspaces", "-j"]
    stdout: StdioCollector {
      id: wsQueryOut
    }
    onExited: (exitCode, exitStatus) => {
      if (exitCode !== 0) return;
      try {
        var list = JSON.parse(wsQueryOut.text);
        var map = {};
        for (var i = 0; i < list.length; i++)
          map[list[i].id] = list[i].windows;
        barPanel.wsMap = map;
        barPanel.wsList = Object.keys(map).map(Number).sort((a,b) => a-b);
      } catch(e) {}
    }
  }

  Process {
    id: wsActive
    command: ["hyprctl", "activeworkspace", "-j"]
    stdout: StdioCollector {
      id: wsActiveOut
    }
    onExited: (exitCode, exitStatus) => {
      if (exitCode !== 0) return;
      try { barPanel.currentWs = JSON.parse(wsActiveOut.text).id; } catch(e) {}
    }
  }

  Process {
    id: winQuery
    command: ["hyprctl", "activewindow", "-j"]
    stdout: StdioCollector {
      id: winQueryOut
    }
    onExited: (exitCode, exitStatus) => {
      if (exitCode !== 0) { barPanel.currentTitle = ""; return; }
      try {
        var w = JSON.parse(winQueryOut.text);
        var title = (w.class || "") + (w.title && w.title !== w.class ? " — " + w.title : "");
        title = title.replace(/ — Mozilla Firefox$/, "");
        title = title.replace(/ — Zen Browser$/, "Zen");
        title = title.replace(/ - Neovim$/, "Neovim");
        title = title.replace(/ - foot$/, "");
        barPanel.currentTitle = title;
      } catch(e) { barPanel.currentTitle = ""; }
    }
  }

  Process {
    id: wsSwitch
    command: ["hyprctl", "dispatch", "workspace", "1"]
    running: false
  }

  function switchWs(id) {
    wsSwitch.command = ["hyprctl", "dispatch", "workspace", String(id)];
    wsSwitch.running = true;
  }

  IpcHandler {
    target: "bar"
    function toggle(): void {
      barPanel.visible = !barPanel.visible;
    }
    function show(): void {
      barPanel.visible = true;
    }
    function hide(): void {
      barPanel.visible = false;
    }
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
        model: barPanel.wsList
        Rectangle {
          width: 24; height: 24
          radius: 4
          color: modelData === barPanel.currentWs ? Colors.accent : Colors.bgSubtle
          border.color: modelData === barPanel.currentWs ? Colors.accent : Colors.border
          border.width: 1
          anchors.verticalCenter: parent.verticalCenter

          Text {
            anchors.centerIn: parent
            text: modelData
            color: modelData === barPanel.currentWs ? Colors.bg : Colors.fgDim
            font.family: "JetBrains Mono"
            font.pixelSize: 11
            font.bold: true
          }

          MouseArea {
            anchors.fill: parent
            onClicked: barPanel.switchWs(modelData)
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
