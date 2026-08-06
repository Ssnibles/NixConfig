import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick

Scope {
  id: root

  property string position: Config.notifPosition
  property int timeoutMs: Config.notifTimeoutMs
  property int maxVisible: Config.notifMaxVisible

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

  function dismissAt(i) {
    var q = root.queue.slice()
    q.splice(i, 1)
    root.queue = q
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

      implicitWidth: Config.notifWidth + Config.notifCardMargins * 2
      implicitHeight: notifColumn.implicitHeight + Config.notifCardMargins * 2
      color: "transparent"

      Column {
        id: notifColumn
        width: parent.width - Config.notifCardMargins * 2
        spacing: Config.notifSpacing
        anchors.margins: Config.notifCardMargins
        anchors.top: panel.onTop ? parent.top : undefined
        anchors.bottom: panel.onTop ? undefined : parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        Repeater {
          model: root.queue

          delegate: NotificationCard {
            summary: modelData ? modelData.summary : ""
            body: modelData ? modelData.body : ""
            onDismissed: root.dismissAt(index)
          }
        }
      }
    }
  }
}