import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
Scope {
  id: root

  property string currentTime: ""
  property int minWorkspaces: Config.mangowcMinWorkspaces


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

      implicitHeight: Config.barHeight
      color: Colors.bg

      mask: Region { item: panel.contentItem }

      // Background MouseArea to absorb all hover and pointer events
      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        onClicked: function(mouse) { mouse.accepted = true }
      }

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

      Item {
        id: barContent
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        height: panel.implicitHeight

        Text {
          id: clockText
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: root.currentTime
          color: Colors.fg
          font.pixelSize: 16
          font.bold: true
          font.family: Config.sansFont
        }

        Row {
          id: tagRow
          anchors.centerIn: parent
          spacing: 6

          Repeater {
            model: panel.visibleTagCount

            Rectangle {
              width: 30
              height: 26
              radius: 6

              property var tagData: (panel.tagsList && index < panel.tagsList.length) ? panel.tagsList[index] : null
              property bool isActive: tagData ? tagData.is_active : (index === 0)
              property bool isOccupied: tagData ? (tagData.client_count > 0) : false

              color: isActive ? Colors.accent : (isOccupied ? Colors.fgDim : Colors.bgSubtle)

              Text {
                anchors.centerIn: parent
                text: index + 1
                color: Colors.fg
                font.pixelSize: 13
                font.family: Config.sansFont
              }

              MouseArea {
                anchors.fill: parent
                onClicked: root.viewTag(index + 1)
              }
            }
          }
        }
      }
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.currentTime = Qt.formatDateTime(new Date(), Config.mangowcClockFormat)
  }

  Component.onCompleted: root.currentTime = Qt.formatDateTime(new Date(), Config.mangowcClockFormat)

}