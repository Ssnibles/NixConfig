import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Scope {
  id: root

  property string currentTime: ""
  property var allMonitorsTags: [] // Store raw monitor data from JSON
  property int minWorkspaces: 5    // Always show at least 5

  // Continuous listener for MangoWC JSON stream
  Process {
    id: statusWatcher
    command: ["mmsg", "watch", "all-tags"]
    running: true

    stdout: SplitParser {
      onRead: line => {
        var cleanLine = line.trim();
        if (!cleanLine.startsWith("{")) return;

        try {
          var data = JSON.parse(cleanLine);
          if (data.all_tags) {
            root.allMonitorsTags = data.all_tags;
          }
        } catch (e) {
          // Ignore partial or malformed lines
        }
      }
    }
  }

  // Switch workspace tag
  function viewTag(tagNum) {
    Quickshell.execDetached(["mmsg", "tag", tagNum.toString()]);
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel
      required property var modelData

      // Binds each panel strictly to its own screen so windows don't overlap
      screen: panel.modelData

      anchors.top: true
      anchors.left: true
      anchors.right: true

      implicitHeight: 32
      color: "#141415"

      // Find the tag list matching this specific monitor (e.g. "eDP-1")
      property var monitorData: {
        if (!root.allMonitorsTags || root.allMonitorsTags.length === 0) return null;
        for (var i = 0; i < root.allMonitorsTags.length; i++) {
          if (root.allMonitorsTags[i].monitor === panel.modelData.name) {
            return root.allMonitorsTags[i];
          }
        }
        // Fallback to the first monitor if name matching fails
        return root.allMonitorsTags[0];
      }

      property var tagsList: monitorData ? (monitorData.tags || []) : []

      // Calculate highest workspace in use for this monitor
      property int highestUsedTag: {
        var maxIndex = 1;
        for (var i = 0; i < tagsList.length; i++) {
          var tag = tagsList[i];
          if (tag.is_active || tag.client_count > 0) {
            maxIndex = Math.max(maxIndex, tag.index);
          }
        }
        return maxIndex;
      }

      property int visibleTagCount: Math.max(root.minWorkspaces, highestUsedTag)

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        Text {
          text: root.currentTime
          color: "#cdcdcd"
          font.pixelSize: 13
          font.family: "Inter"
          verticalAlignment: Text.AlignVCenter
          Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        Row {
          spacing: 6
          Layout.alignment: Qt.AlignCenter

          Repeater {
            model: panel.visibleTagCount

            Rectangle {
              width: 28
              height: 24
              radius: 6

              property var tagData: (panel.tagsList && index < panel.tagsList.length) ? panel.tagsList[index] : null
              property bool isActive: tagData ? tagData.is_active : (index === 0)
              property bool isOccupied: tagData ? (tagData.client_count > 0) : false

              color: isActive ? "#6e94b2" : (isOccupied ? "#606079" : "#252530")

              Text {
                anchors.centerIn: parent
                text: index + 1
                color: "#cdcdcd"
                font.pixelSize: 11
                font.family: "Inter"
              }

              MouseArea {
                anchors.fill: parent
                onClicked: root.viewTag(index + 1)
              }
            }
          }
        }

        Item { Layout.fillWidth: true }
      }
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.currentTime = Qt.formatDateTime(new Date(), "HH:mm:ss")
  }

  Component.onCompleted: root.currentTime = Qt.formatDateTime(new Date(), "HH:mm:ss")
}
