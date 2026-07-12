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
  readonly property int panelWidth: 520
  readonly property int cardRadius: 20
  readonly property int cardPadding: 14
  readonly property int cardSpacing: 6
  readonly property int iconSize: 24

  // Tiny LRU-ish cache so we don't re-strip HTML tags from the same text repeatedly.
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
      return Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.30)
    }
    if (notification.urgency === NotificationUrgency.Low) {
      return Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.20)
    }
    return Colors.border
  }

  // Determine how long a popup stays open.
  // Critical notifications never auto-expire (0 = infinite).
  // Otherwise respect the app's requested timeout, clamped to a sane 2.5s–15s range.
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
    if (idx === 0) return // already newest — nothing to do
    if (idx > 0) popupList.splice(idx, 1) // remove from old position
    // Push to front so newest notifications appear at the top.
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
      // lastGeneration is true for notifications that existed before quickshell started;
      // we only want to show newly arriving ones as popups.
      if (notification.lastGeneration) return
      if (notif.doNotDisturb && notification.urgency !== NotificationUrgency.Critical) return
      notif._addPopup(notification)
    }
  }

  // Lazy popup window — only created when popups exist.
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

        anchors { top: true; bottom: true; left: true; right: true }

        Column {
          id: popupColumn
          width: notif.panelWidth
          spacing: 8
          anchors.centerIn: parent

          Repeater {
            model: popupList

            Rectangle {
              id: popupCard
              property var notification: modelData
              property int timeoutMs: notif._popupTimeoutFor(notification)

              width: popupColumn.width
              implicitHeight: popupInner.implicitHeight + notif.cardPadding * 2
              height: implicitHeight
              radius: notif.cardRadius
              color: notif._cardBgFor(notification)
              border.width: 1
              border.color: notif._cardBorderFor(notification)

              opacity: 0
              Component.onCompleted: {
                if (!notification._qsShown) {
                  notification._qsShown = true
                  appearAnim.start()
                  if (popupTimer.interval > 0) popupTimer.start()
                } else {
                  opacity = 1
                }
              }

              NumberAnimation {
                id: appearAnim
                target: popupCard
                property: "opacity"
                to: 1
                duration: 220
                easing.type: Easing.OutCubic
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
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: notif.cardPadding }
                spacing: 8

                // Header: icon + urgency bar + app name + close
                RowLayout {
                  width: parent.width
                  spacing: 8

                  Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 8
                    color: Colors.bgSubtle
                    border.width: 1
                    border.color: Colors.border

                    AppIcon {
          anchors { top: parent.top; left: parent.left; topMargin: notif.topMargin; leftMargin: notif.sideMargin }
                      notification: popupCard.notification
                      iconSize: 18
                      fallbackBg: Colors.bgSubtle
                    }
                  }

                  Rectangle {
                    Layout.preferredWidth: 4
                    Layout.preferredHeight: 14
                    radius: 2
                    color: notif._urgencyColor(notification)
                    Layout.alignment: Qt.AlignVCenter
                  }

                  Text {
                    text: (notification && notification.appName && notification.appName.length > 0)
                      ? notification.appName.toUpperCase()
                      : "NOTIFICATION"
                    color: Colors.accent
                    font.family: notif.uiFont
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1.2
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                  }
                }

                // Summary
                Text {
                  text: notification ? notif.stripMarkup(notification.summary || "") : ""
                  width: parent.width
                  color: Colors.fg
                  font.family: notif.uiFont
                  font.pixelSize: 12
                  font.bold: true
                  wrapMode: Text.Wrap
                  textFormat: Text.PlainText
                  visible: text.length > 0
                }

                // Body
                Text {
                  text: notification ? notif.stripMarkup(notification.body || "") : ""
                  width: parent.width
                  color: Colors.fgMid
                  font.family: notif.uiFont
                  font.pixelSize: 11
                  wrapMode: Text.Wrap
                  textFormat: Text.PlainText
                  visible: text.length > 0
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

              // Pause auto-dismiss timer while the user is hovering the popup.
              HoverHandler {
                id: popupHover
                onHoveredChanged: {
                  if (hovered) popupTimer.stop()
                  else if (popupTimer.interval > 0) popupTimer.restart()
                }
              }
            }
          }
        }
      }
    }
  }
}
