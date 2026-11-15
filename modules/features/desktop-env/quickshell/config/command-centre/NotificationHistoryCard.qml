pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

// Notification history list shown in the Command Centre.
Card {
  id: root

  // The scrollbar overlays the list's right edge, so the list column runs into
  // the card's right padding by this much. Rows that do not scroll add the
  // same inset back, which keeps them on the usual card margin.
  readonly property int scrollBarGutter: historyBar.gutter
  readonly property int scrollBarInset: Math.min(root.scrollBarGutter, Config.spaceLg)

  ColumnLayout {
    anchors.fill: parent
    anchors.topMargin: Config.spaceLg
    anchors.leftMargin: Config.spaceLg
    anchors.bottomMargin: Config.spaceLg
    anchors.rightMargin: Config.spaceLg - root.scrollBarInset
    spacing: Config.spaceMd

    RowLayout {
      Layout.fillWidth: true
      Layout.rightMargin: root.scrollBarInset
      spacing: Config.spaceMd

      Item { Layout.fillWidth: true }

      // Controls: Mute toggle and Clear button
      Row {
        spacing: Config.spaceSm
        Layout.alignment: Qt.AlignVCenter

        // Mute / DND Toggle Button
        Pill {
          id: mutePill
          pillHeight: Config.pillHeightHorizontal
          padding: Config.spaceSm
          baseColour: NotificationService.dnd ? Colours.red : "transparent"
          hoverColour: NotificationService.dnd ? Colours.red : Colours.bgSubtle
          hoverHighlight: true
          border.color: NotificationService.dnd ? Colours.red : Colours.border
          clickable: true
          onClicked: NotificationService.toggleDnd()

          Row {
            anchors.centerIn: parent
            spacing: Config.spaceSm

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
          pillHeight: Config.pillHeightHorizontal
          padding: Config.spaceSm
          baseColour: "transparent"
          hoverColour: Colours.bgSubtle
          hoverHighlight: true
          clickable: true
          onClicked: NotificationService.clearHistory()

          Row {
            anchors.centerIn: parent
            spacing: Config.spaceSm

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

    // Empty State view
    Item {
      visible: NotificationService.historyModel.count === 0
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.rightMargin: root.scrollBarInset

      Row {
        anchors.centerIn: parent
        spacing: Config.spaceMd

        Text {
          text: "󰂜"
          color: Colours.fgDim
          font.family: Session.monoFont
          font.pixelSize: Config.iconSizeXl
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: "No notifications"
          color: Colours.fgDim
          font.family: Session.sansFont
          font.pixelSize: Config.fontSizeLg
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }

    Item {
      visible: NotificationService.historyModel.count > 0
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true

      // A hovered card scales up around its centre, so it grows past its
      // resting bounds on every side. Inset the list by half that growth on
      // the width and a small fixed amount on the height, so the enlarged card
      // stays inside the clip region instead of having its edges sliced off.
      readonly property int hoverInsetX: Math.ceil(width * (Config.notifHoverScale - 1) / 2) + Config.borderWidth
      readonly property int hoverInsetY: Config.space2xs + Config.borderWidth

      ListView {
        id: notifHistList
        anchors.fill: parent
        anchors.leftMargin: parent.hoverInsetX
        anchors.rightMargin: parent.hoverInsetX
        anchors.topMargin: parent.hoverInsetY
        anchors.bottomMargin: parent.hoverInsetY
        spacing: Config.notifSpacing
        model: NotificationService.historyModel

        ScrollBar.vertical: ThinScrollBar { id: historyBar }

        // New cards are inserted at index 0. Follow them when the list is at
        // the top, but leave the reader's position alone when it is scrolled.
        Connections {
          target: NotificationService.historyModel
          function onCountChanged() {
            if (notifHistList.atYBeginning) notifHistList.positionViewAtBeginning()
          }
        }

        delegate: NotificationCard {
          width: notifHistList.width - root.scrollBarGutter
          isHistory: true
        }
      }
    }
  }
}
