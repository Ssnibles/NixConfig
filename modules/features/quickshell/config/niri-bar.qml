import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

Scope {
  id: root

  property string currentTime: ""
  property var allWorkspaces: []
  property int batteryPercent: 0
  property bool batteryCharging: false

  Process {
    id: niriEvents
    command: ["niri", "msg", "--json", "event-stream"]
    running: true

    stdout: SplitParser {
      onRead: line => {
        var cleanLine = line.trim()
        if (!cleanLine.startsWith("{")) return
        try {
          var event = JSON.parse(cleanLine)
          handleEvent(event)
        } catch (e) {}
      }
    }
  }

  Process {
    id: batProc
    command: ["sh", "-c", "while true; do c=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 0); s=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo Unknown); echo \"$c $s\"; sleep 10; done"]
    running: true

    stdout: SplitParser {
      onRead: line => {
        var parts = line.trim().split(" ")
        if (parts.length >= 2) {
          batteryPercent = parseInt(parts[0])
          batteryCharging = parts[1] === "Charging"
        }
      }
    }
  }

  function handleEvent(event) {
    if (event.WorkspacesChanged) {
      var wsList = event.WorkspacesChanged.workspaces
      wsList.sort((a, b) => a.idx - b.idx)
      root.allWorkspaces = wsList
    } else if (event.WorkspaceActivated) {
      var activated = event.WorkspaceActivated
      var outputName = null
      for (var i = 0; i < root.allWorkspaces.length; i++) {
        if (root.allWorkspaces[i].id === activated.id) {
          outputName = root.allWorkspaces[i].output
          break
        }
      }
      if (!outputName) return
      var updated = []
      for (var i = 0; i < root.allWorkspaces.length; i++) {
        var ws = root.allWorkspaces[i]
        if (ws.output === outputName) {
          updated.push({
            id: ws.id, idx: ws.idx, name: ws.name, output: ws.output,
            is_active: ws.id === activated.id,
            is_focused: activated.focused ? ws.id === activated.id : ws.is_focused,
            is_urgent: ws.is_urgent
          })
        } else {
          updated.push(ws)
        }
      }
      root.allWorkspaces = updated
    }
  }

  function focusWorkspace(id) {
    Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", id.toString()])
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel
      required property var modelData
      screen: panel.modelData

      anchors.left: true
      anchors.top: true
      anchors.bottom: true

      implicitWidth: 46
      color: "#141415"

      property var wsForOutput: {
        var result = []
        var wsList = root.allWorkspaces
        var outputName = panel.modelData.name
        for (var i = 0; i < wsList.length; i++) {
          if (wsList[i].output === outputName)
            result.push(wsList[i])
        }
        return result
      }

      Item {
        id: barContent
        anchors.fill: parent
        anchors.margins: 6

        Column {
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          spacing: 6

          Text {
            id: clockText
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.currentTime
            color: "#cdcdcd"
            font.pixelSize: 11
            font.family: "Inter"
          }

          Column {
            spacing: 4

            Repeater {
              model: panel.wsForOutput

              Rectangle {
                width: 34
                height: 34
                radius: 6

                property var wsData: modelData
                property bool isFocused: wsData && wsData.is_focused
                property bool isActive: wsData && wsData.is_active

                color: isFocused ? "#6e94b2" : (isActive ? "#606079" : "#252530")

                Text {
                  anchors.centerIn: parent
                  text: wsData ? (wsData.name || wsData.idx.toString()) : ""
                  color: "#cdcdcd"
                  font.pixelSize: 11
                  font.family: "Inter"
                }

                MouseArea {
                  anchors.fill: parent
                  onClicked: root.focusWorkspace(wsData.id)
                }
              }
            }
          }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 2
          text: batteryPercent + "%"
          color: batteryCharging ? "#98c379" : (batteryPercent < 20 ? "#e06c75" : "#cdcdcd")
          font.pixelSize: 11
          font.family: "Inter"
        }
      }
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.currentTime = Qt.formatDateTime(new Date(), "HH:mm")
  }

  Component.onCompleted: root.currentTime = Qt.formatDateTime(new Date(), "HH:mm")
}
