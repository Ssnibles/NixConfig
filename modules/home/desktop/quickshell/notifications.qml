import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQml

Item {
  id: notif

  property bool doNotDisturb: false
  property bool barVisible: true
  property alias notificationServer: notificationServer
  property int popupTimeoutMs: 6000
  property int maxPopups: 5
  property string uiFont: "JetBrainsMono Nerd Font"

  readonly property int topMargin: barVisible ? 54 : 24
  readonly property int sideMargin: 24
  readonly property int panelWidth: 400
  readonly property int cardRadius: 12
  readonly property int cardPadding: 14
  readonly property int cardSpacing: 6
  readonly property int iconSize: 24

  property var _stripCache: ({})

  function stripMarkup(text) {
    if (!text || text.length === 0) return ""
    var c = notif._stripCache
    var r = c[text]
    if (r !== undefined) return r
    r = text.replace(/<[^>]*>/g, "")
    if (Object.keys(c).length < 100) c[text] = r
    return r
  }

  function _urgencyColor(notification) {
    if (!notification) return Colors.accent
    if (notification.urgency === NotificationUrgency.Critical) return Colors.red
    if (notification.urgency === NotificationUrgency.Low) return Colors.fgDim
    if (notification.urgency === NotificationUrgency.Normal) return Colors.accent
    return Colors.yellow
  }

  function _cardBgFor(notification) {
    return Colors.bgRaised
  }

  function _cardBorderFor(notification) {
    if (!notification) return Colors.border
    if (notification.urgency === NotificationUrgency.Critical) {
      return Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.35)
    }
    return Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.6)
  }

  function _popupTimeoutFor(notification) {
    if (!notification) return notif.popupTimeoutMs
    if (notification.urgency === NotificationUrgency.Critical) return 0
    if (notification.expireTimeout > 0) {
      var ms = Math.round(notification.expireTimeout * 1000)
      return Math.max(2500, Math.min(15000, ms))
    }
    if (notification.urgency === NotificationUrgency.Low) return 3500
    return notif.popupTimeoutMs
  }

  function _removePopup(notification) {
    var idx = popupList.indexOf(notification)
    if (idx >= 0) popupList.splice(idx, 1)
    popupListChanged()
  }

  function _focusNotificationSource(notification) {
    if (!notification) return
    var entry = notification.desktopEntry || notification.appName || ""
    if (entry) {
      var lowerEntry = entry.toLowerCase()
      var toplevels = Hyprland.toplevels.values
      for (var i = 0; i < toplevels.length; i++) {
        var tl = toplevels[i]
        if (tl.lastIpcObject && tl.lastIpcObject.class) {
          if (tl.lastIpcObject.class.toLowerCase() === lowerEntry) {
            var addr = String(tl.address)
            if (addr.startsWith("0x")) addr = addr.slice(2)
            Hyprland.dispatch("focuswindow address:0x" + addr)
            return
          }
        }
      }
      Hyprland.dispatch("focuswindow class:(?i)^" + entry.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "$")
    }
  }

  function _addPopup(notification) {
    if (!notification) return
    var idx = popupList.indexOf(notification)
    if (idx === 0) return
    if (idx > 0) popupList.splice(idx, 1)
    popupList.unshift(notification)
    if (popupList.length > notif.maxPopups) popupList.length = notif.maxPopups
    popupListChanged()
    notification.closed.connect(function() { notif._removePopup(notification) })
  }

  function clearNotifications() {
    popupList = []
    var all = notificationServer.trackedNotifications.values
    while (all.length > 0) all[0].dismiss()
  }

  onDoNotDisturbChanged: { if (doNotDisturb) popupList = [] }

  property var popupList: []

  property bool _hasPopups: popupList.length > 0

  NotificationServer {
    id: notificationServer
    keepOnReload: true

    actionsSupported: true
    actionIconsSupported: true
    bodySupported: true
    bodyMarkupSupported: false
    bodyHyperlinksSupported: false
    imageSupported: true
    bodyImagesSupported: false
    persistenceSupported: true

    onNotification: function(notification) {
      notification.tracked = true
      if (notification.lastGeneration) return
      if (notif.doNotDisturb && notification.urgency !== NotificationUrgency.Critical) return
      notif._addPopup(notification)
    }
  }

  Loader {
    id: popupWindowLoader
    active: notif._hasPopups

    sourceComponent: Component {
      PanelWindow {
        id: popupWindow
        focusable: false
        aboveWindows: true
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        anchors { top: true; left: true }
        implicitWidth: notif.sideMargin + notif.panelWidth + 60
        implicitHeight: notif.topMargin + popupColumn.implicitHeight + 20

        Column {
          id: popupColumn
          width: notif.panelWidth
          spacing: 8
          anchors { top: parent.top; left: parent.left; topMargin: notif.topMargin; leftMargin: notif.sideMargin }

          Repeater {
            model: popupList

            Rectangle {
              id: popupCard
              property var notification: modelData
              property int timeoutMs: notif._popupTimeoutFor(notification)
              property color urgencyCol: notif._urgencyColor(notification)

              width: popupColumn.width
              implicitHeight: popupInner.implicitHeight + notif.cardPadding * 2
              height: implicitHeight
              radius: notif.cardRadius
              color: notif._cardBgFor(notification)
              border.width: notification && notification.urgency === NotificationUrgency.Critical ? 1.5 : 1
              border.color: notif._cardBorderFor(notification)

              opacity: 0
              x: 40
              Component.onCompleted: {
                if (!notification._qsShown) {
                  notification._qsShown = true
                  notification._qsExpiresAt = Date.now() + popupTimer.interval
                  appearAnim.start()
                  if (popupTimer.interval > 0) popupTimer.start()
                } else {
                  opacity = 1
                  x = 0
                  var remaining = notification._qsExpiresAt - Date.now()
                  if (remaining > 0 && popupTimer.interval > 0) {
                    popupTimer.interval = remaining
                    popupTimer.start()
                  } else if (remaining <= 0 && popupTimer.interval > 0) {
                    if (notification) notification.expire()
                    notif._removePopup(notification)
                  }
                }
              }

              ParallelAnimation {
                id: appearAnim
                NumberAnimation {
                  target: popupCard
                  property: "opacity"
                  from: 0
                  to: 1
                  duration: 280
                  easing.type: Easing.OutCubic
                }
                NumberAnimation {
                  target: popupCard
                  property: "x"
                  from: 40
                  to: 0
                  duration: 320
                  easing.type: Easing.OutCubic
                }
              }

              Rectangle {
                id: urgencyStrip
                width: 3
                height: parent.height - notif.cardRadius
                radius: 1.5
                anchors { left: parent.left; leftMargin: 5; verticalCenter: parent.verticalCenter }
                color: popupCard.urgencyCol
                opacity: 0.9
              }

              MouseArea {
                anchors.fill: parent
                z: -1
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: function(mouse) {
                  if (mouse.button === Qt.LeftButton) {
                    notif._removePopup(notification)
                  } else if (mouse.button === Qt.RightButton) {
                    notif._focusNotificationSource(notification)
                  }
                }
              }

              Column {
                id: popupInner
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: notif.cardPadding; leftMargin: notif.cardPadding + 10 }
                spacing: 6

                RowLayout {
                  width: parent.width
                  spacing: 10

                  Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 8
                    color: Qt.rgba(popupCard.urgencyCol.r, popupCard.urgencyCol.g, popupCard.urgencyCol.b, 0.12)
                    border.width: 0

                    AppIcon {
                      anchors.centerIn: parent
                      notification: popupCard.notification
                      iconSize: 18
                      fallbackBg: "transparent"
                    }
                  }

                  ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 1

                    Text {
                      text: (notification && notification.appName && notification.appName.length > 0)
                        ? notification.appName
                        : "Notification"
                      color: Colors.fgMid
                      font.family: notif.uiFont
                      font.pixelSize: 10
                      font.bold: true
                      font.letterSpacing: 0.5
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }

                    Text {
                      text: notification ? notif.stripMarkup(notification.summary || "") : ""
                      Layout.fillWidth: true
                      color: Colors.fg
                      font.family: notif.uiFont
                      font.pixelSize: 12
                      font.bold: true
                      elide: Text.ElideRight
                      maximumLineCount: 1
                      wrapMode: Text.NoWrap
                      textFormat: Text.PlainText
                      visible: text.length > 0
                    }
                  }
                }

                Text {
                  text: notification ? notif.stripMarkup(notification.body || "") : ""
                  width: parent.width
                  color: Colors.fgMid
                  font.family: notif.uiFont
                  font.pixelSize: 11
                  wrapMode: Text.Wrap
                  textFormat: Text.PlainText
                  visible: text.length > 0
                  maximumLineCount: 3
                  lineHeight: 1.3
                }

                ActionRow {
                  width: parent.width
                  actions: (notification && notification.actions) ? notification.actions : []
                  onActionInvoked: notif._removePopup(notification)
                }
              }

              Timer {
                id: popupTimer
                interval: popupCard.timeoutMs
                repeat: false
                onTriggered: {
                  if (!notif) return
                  var n = notification
                  if (n) n.expire()
                  notif._removePopup(n)
                }
              }

              HoverHandler {
                id: popupHover
                onHoveredChanged: {
                  if (hovered) {
                    if (popupTimer.running) {
                      notification._qsRemainingOnPause = notification._qsExpiresAt - Date.now()
                    }
                    popupTimer.stop()
                  } else {
                    if (notification._qsRemainingOnPause > 0) {
                      notification._qsExpiresAt = Date.now() + notification._qsRemainingOnPause
                      popupTimer.interval = notification._qsRemainingOnPause
                      popupTimer.restart()
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
