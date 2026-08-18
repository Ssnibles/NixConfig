import Quickshell
import Quickshell.Wayland
import QtQuick

Scope {
  id: root

  // Global MangoWC IPC Service
  MangoService {
    id: mangoService
  }

  property int minWorkspaces: Config.mangowcMinWorkspaces

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: barPanel
      required property var modelData
      screen: barPanel.modelData
      focusable: false
      aboveWindows: true

      anchors {
        top: true
        left: true
        right: true
      }
      implicitHeight: Config.barHeight
      exclusionMode: ExclusionMode.Auto
      color: Colors.bg

      mask: Region { item: barPanel.contentItem }

      // Background MouseArea to absorb all hover and pointer events
      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        onClicked: function(mouse) { mouse.accepted = true }
      }

      // Thin bottom border line
      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Colors.border
      }

      // Bar Content Container
      Item {
        id: barContent
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        // Left Section: Clock, Command Center Button, Window Title
        Row {
          id: leftRow
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: 12

          ClockWidget {
            id: clockWidget
            horizontal: true
            sharedWindow: sharedTipWindow
          }

          CommandCenterButton {
            id: commandCenterButton
            horizontal: true
            anchors.verticalCenter: parent.verticalCenter
          }

          WindowTitleWidget {
            id: windowTitleWidget
            horizontal: true
            titleText: mangoService.currentTitle
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        // Center Section: MangoWC Workspace / Tag Indicators
        property var tagsList: mangoService.tagsForOutput(barPanel.modelData.name)

        property int highestUsedTag: {
          var maxIndex = 1
          for (var i = 0; i < tagsList.length; i++) {
            var tag = tagsList[i]
            if (tag.is_active || tag.client_count > 0) {
              maxIndex = Math.max(maxIndex, tag.index)
            }
          }
          return maxIndex
        }

        property int visibleTagCount: Math.max(root.minWorkspaces, highestUsedTag)

        property var mangoWorkspaces: {
          var result = []
          var tags = barContent.tagsList
          var count = barContent.visibleTagCount
          for (var i = 0; i < count; i++) {
            var tagData = (tags && i < tags.length) ? tags[i] : null
            var active = tagData ? tagData.is_active : (i === 0)
            var countClients = tagData ? (tagData.client_count > 0) : false
            result.push({
              id: i + 1,
              is_focused: active,
              is_active: active,
              is_occupied: countClients,
              is_urgent: false
            })
          }
          return result
        }

        WorkspacesWidget {
          id: workspacesWidget
          horizontal: true
          workspaces: barContent.mangoWorkspaces
          onFocusRequested: function(workspaceId) {
            mangoService.focusTag(workspaceId)
          }
        }

        // Right Section: Media, Volume, Network, Battery Widgets
        Row {
          id: rightRow
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: 10

          MediaWidget {
            id: mediaWidget
            horizontal: true
            anchors.verticalCenter: parent.verticalCenter
            sharedWindow: sharedTipWindow
          }

          VolumeWidget {
            id: volumeWidget
            horizontal: true
            anchors.verticalCenter: parent.verticalCenter
            sharedWindow: sharedTipWindow
          }

          NetworkWidget {
            id: networkWidget
            horizontal: true
            anchors.verticalCenter: parent.verticalCenter
            sharedWindow: sharedTipWindow
          }

          BatteryWidget {
            id: batteryWidget
            horizontal: true
            anchors.verticalCenter: parent.verticalCenter
            sharedWindow: sharedTipWindow
          }
        }
      }

      // Shared Tooltip Window Layer
      SharedTooltipWindow {
        id: sharedTipWindow
        screenTarget: barPanel.modelData
        barSide: "top"
      }
    }
  }
}