pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."

// Notification history list shown in the Command Centre.
Card {
  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 12
    spacing: 10

    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Row {
        spacing: 6
        Layout.alignment: Qt.AlignVCenter

        Text {
          text: NotificationService.dnd ? "󰂛" : "󰂚"
          color: NotificationService.dnd ? Colours.red : Colours.accent
          font.family: Session.monoFont
          font.pixelSize: 17
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: "Notifications"
          color: Colours.fg
          font.family: Session.sansFont
          font.pixelSize: Config.fontSizeLg
          font.bold: true
          anchors.verticalCenter: parent.verticalCenter
        }

        // Badge count pill
        Pill {
          visible: NotificationService.historyModel.count > 0
          pillHeight: 18
          padding: 5
          pillColour: Colours.bgSubtle
          anchors.verticalCenter: parent.verticalCenter

          Text {
            anchors.centerIn: parent
            text: NotificationService.historyModel.count
            color: Colours.fgDim
            font.family: Session.sansFont
            font.pixelSize: Config.fontSizeXs
          }
        }
      }

      Item { Layout.fillWidth: true }

      // Controls: Mute toggle & Clear button
      Row {
        spacing: 6
        Layout.alignment: Qt.AlignVCenter

        // Mute / DND Toggle Button
        Pill {
          id: mutePill
          pillHeight: 26
          padding: 6
          baseColour: NotificationService.dnd ? Colours.red : "transparent"
          hoverColour: NotificationService.dnd ? Colours.red : Colours.bgSubtle
          hoverHighlight: true
          border.color: NotificationService.dnd ? Colours.red : Colours.border
          clickable: true
          onClicked: NotificationService.toggleDnd()

          Row {
            anchors.centerIn: parent
            spacing: 4

            Text {
              text: NotificationService.dnd ? "󰂛" : "󰂚"
              color: NotificationService.dnd ? Colours.bg : (mutePill.hovered ? Colours.red : Colours.fgDim)
              font.family: Session.monoFont
              font.pixelSize: Config.iconSizeSm
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              text: NotificationService.dnd ? "Muted" : "Mute"
              color: NotificationService.dnd ? Colours.bg : (mutePill.hovered ? Colours.fg : Colours.fgMid)
              font.family: Session.sansFont
              font.pixelSize: Config.fontSizeSm
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }

        // Clear Button
        Pill {
          id: clearPill
          visible: NotificationService.historyModel.count > 0
          pillHeight: 26
          padding: 6
          baseColour: "transparent"
          hoverColour: Colours.bgSubtle
          hoverHighlight: true
          clickable: true
          onClicked: NotificationService.clearHistory()

          Row {
            anchors.centerIn: parent
            spacing: 4

            Text {
              text: "󰎟"
              color: clearPill.hovered ? Colours.red : Colours.fgDim
              font.family: Session.monoFont
              font.pixelSize: Config.iconSizeSm
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              text: "Clear"
              color: clearPill.hovered ? Colours.fg : Colours.fgMid
              font.family: Session.sansFont
              font.pixelSize: Config.fontSizeSm
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }
      }
    }

    Divider {
      Layout.fillWidth: true
    }

    // Empty State view
    Item {
      visible: NotificationService.historyModel.count === 0
      Layout.fillWidth: true
      Layout.fillHeight: true

      Row {
        anchors.centerIn: parent
        spacing: 8

        Text {
          text: "󰂜"
          color: Colours.fgDim
          font.family: Session.monoFont
          font.pixelSize: 22
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: "No notifications"
          color: Colours.fgDim
          font.family: Session.sansFont
          font.pixelSize: 14
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }

    Item {
      visible: NotificationService.historyModel.count > 0
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true

      ListView {
        id: notifHistList
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        anchors.topMargin: 2
        anchors.bottomMargin: 2
        spacing: 6
        model: NotificationService.historyModel

        delegate: NotificationCard {
          width: notifHistList.width
          isHistory: true
        }
      }
    }
  }
}
