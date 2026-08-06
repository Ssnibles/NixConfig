import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick

Scope {
  id: root

  property string position: "top-right"
  property int timeoutMs: 5000
  property int maxVisible: 3

  property var queue: []

  NotificationServer {
    id: notificationServer
    bodySupported: true

    onNotification: function (notification) {
      var q = root.queue.slice()
      q.push({ summary: notification.summary, body: notification.body })
      if (q.length > root.maxVisible) q = q.slice(-root.maxVisible)
      root.queue = q
      dismissTimer.restart()
    }
  }

  Timer {
    id: dismissTimer
    interval: root.timeoutMs
    onTriggered: {
      if (root.queue.length > 0) {
        root.queue = root.queue.slice(1)
        if (root.queue.length > 0) restart()
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel
      required property var modelData
      screen: modelData

      readonly property bool onTop: root.position.indexOf("top") !== -1
      readonly property bool onLeft: root.position.indexOf("left") !== -1

      anchors.top: onTop
      anchors.bottom: onTop ? false : true
      anchors.left: onLeft
      anchors.right: onLeft ? false : true

      implicitWidth: 300
      implicitHeight: notifColumn.implicitHeight + 16
      color: "transparent"

      Column {
        id: notifColumn
        width: parent.width - 16
        spacing: 4
        anchors.margins: 8
        anchors.top: panel.onTop ? parent.top : undefined
        anchors.bottom: panel.onTop ? undefined : parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        Repeater {
          model: root.queue

          delegate: Rectangle {
            width: 284
            height: notifContent.height + 16
            radius: 8
            color: Colors.bgRaised
            border.color: Colors.border
            border.width: 1

            Column {
              id: notifContent
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.margins: 8
              spacing: 2

              Text {
                text: modelData ? (modelData.summary || "") : ""
                color: Colors.fg
                font.bold: true
                font.pixelSize: 12
                font.family: "Inter"
                elide: Text.ElideRight
                width: 268
              }

              Text {
                text: modelData ? (modelData.body || "") : ""
                color: Colors.fgMid
                font.pixelSize: 11
                font.family: "Inter"
                elide: Text.ElideRight
                width: 268
                visible: text !== ""
              }
            }
          }
        }
      }
    }
  }
}
