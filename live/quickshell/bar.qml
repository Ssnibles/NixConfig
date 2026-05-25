import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQml
import "colors.js" as Colors

Item {
  id: bar

  property var wsMap: ({})
  property int currentWs: 1
  property string currentTitle: ""
  property string timeStr: ""

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: {
      var d = new Date();
      bar.timeStr = d.getHours().toString().padStart(2,'0') + ":" + d.getMinutes().toString().padStart(2,'0');
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
    command: "hyprctl"
    arguments: ["workspaces", "-j"]
    onFinished: (code) => {
      if (code !== 0) return;
      try {
        var list = JSON.parse(stdout);
        var map = {};
        for (var i = 0; i < list.length; i++)
          map[list[i].id] = list[i].windows;
        bar.wsMap = map;
      } catch(e) {}
    }
  }

  Process {
    id: wsActive
    command: "hyprctl"
    arguments: ["activeworkspace", "-j"]
    onFinished: (code) => {
      if (code !== 0) return;
      try { bar.currentWs = JSON.parse(stdout).id; } catch(e) {}
    }
  }

  Process {
    id: winQuery
    command: "hyprctl"
    arguments: ["activewindow", "-j"]
    onFinished: (code) => {
      if (code !== 0) { bar.currentTitle = ""; return; }
      try {
        var w = JSON.parse(stdout);
        var title = (w.class || "") + (w.title && w.title !== w.class ? " — " + w.title : "");
        title = title.replace(/ — Mozilla Firefox$/, "");
        title = title.replace(/ — Zen Browser$/, "Zen");
        title = title.replace(/ - Neovim$/, "Neovim");
        title = title.replace(/ - foot$/, "");
        bar.currentTitle = title;
      } catch(e) { bar.currentTitle = ""; }
    }
  }

  Process {
    id: wsSwitch
    command: "hyprctl"
    arguments: ["dispatch", "workspace", "1"]
    running: false
  }

  function switchWs(id) {
    wsSwitch.arguments = ["dispatch", "workspace", String(id)];
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

  PanelWindow {
    id: barPanel
    focusable: false
    aboveWindows: true

    anchors { top: true; left: true; right: true }
    height: 30
    exclusionMode: ExclusionMode.Exclusive
    color: Colors.bg

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 8
      anchors.rightMargin: 10
      spacing: 6

      Row {
        Layout.alignment: Qt.AlignLeft
        spacing: 3
        Repeater {
          model: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
          Rectangle {
            width: 24; height: 24
            radius: 4
            color: (index + 1) === bar.currentWs ? Colors.accent : Colors.bgSubtle
            border.color: (index + 1) === bar.currentWs ? Colors.accent : Colors.border
            border.width: 1
            anchors.verticalCenter: parent.verticalCenter

            Text {
              anchors.centerIn: parent
              text: index + 1
              color: (index + 1) === bar.currentWs ? Colors.bg : Colors.fgDim
              font.family: "JetBrains Mono"
              font.pixelSize: 11
              font.bold: true
            }

            MouseArea {
              anchors.fill: parent
              onClicked: bar.switchWs(index + 1)
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
        text: bar.currentTitle
        color: Colors.fgMid
        font.family: "JetBrains Mono"
        font.pixelSize: 12
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignLeft
      }

      Text {
        text: bar.timeStr
        color: Colors.fg
        font.family: "JetBrains Mono"
        font.pixelSize: 13
        font.bold: true
      }
    }
  }
}
