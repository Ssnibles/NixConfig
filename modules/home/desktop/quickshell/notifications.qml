import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQml

Item {
  id: notif
  property bool doNotDisturb: false
  property bool barVisible: true
  property alias notificationServer: notificationServer
  property int  popupTimeoutMs: 6000
  property int  maxPopups: 5
  property string uiFont: "JetBrains Mono"

  readonly property int  topMargin: barVisible ? 54 : 24
  readonly property int  sideMargin: 24
  readonly property int  panelWidth: 520
  readonly property int  cardRadius: 20
  readonly property int  cardPadding: 14
  readonly property int  cardSpacing: 6
  readonly property int  iconSize: 24

  property var _stripCache: ({})

  function stripMarkup(text) {
    if (!text || text.length === 0) return "";
    var c = notif._stripCache;
    var r = c[text];
    if (r !== undefined) return r;
    r = text.replace(/<[^>]*>/g, "");
    if (Object.keys(c).length < 100) c[text] = r;
    return r;
  }

  function urgencyColor(notification) {
    if (!notification) return Colors.accent;
    if (notification.urgency === NotificationUrgency.Critical) return Colors.red;
    if (notification.urgency === NotificationUrgency.Low)      return Colors.fgDim;
    if (notification.urgency === NotificationUrgency.Normal)   return Colors.accent;
    return Colors.yellow;
  }

  function cardBgFor(notification) {
    return Colors.bgRaised;
  }

  function cardBorderFor(notification) {
    if (!notification) return Colors.border;
    if (notification.urgency === NotificationUrgency.Critical)
      return Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.30);
    if (notification.urgency === NotificationUrgency.Low)
      return Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.20);
    return Colors.border;
  }

  function popupTimeoutFor(notification) {
    if (!notification) return notif.popupTimeoutMs;
    if (notification.urgency === NotificationUrgency.Critical) return 0;
    if (notification.expireTimeout > 0) {
      var ms = Math.round(notification.expireTimeout * 1000);
      return Math.max(2500, Math.min(15000, ms));
    }
    if (notification.urgency === NotificationUrgency.Low) return 3500;
    return notif.popupTimeoutMs;
  }

  function removePopup(notification) {
    var idx = popupList.indexOf(notification);
    if (idx >= 0) popupList.splice(idx, 1);
    popupListChanged();
  }

  function addPopup(notification) {
    if (!notification) return;
    var idx = popupList.indexOf(notification);
    if (idx === 0) return;                    // already newest — nothing to do
    if (idx > 0) popupList.splice(idx, 1);    // remove from old position
    popupList.unshift(notification);
    if (popupList.length > notif.maxPopups) popupList.length = notif.maxPopups;
    popupListChanged();
    notification.closed.connect(function() { notif.removePopup(notification); });
  }

  function clearNotifications() {
    popupList = [];
    var all = notificationServer.trackedNotifications.values;
    while (all.length > 0) all[0].dismiss();
  }

  onDoNotDisturbChanged: { if (doNotDisturb) popupList = []; }

  property var popupList: []

  property bool _hasPopups: popupList.length > 0

  NotificationServer {
    id: notificationServer
    keepOnReload: true

    actionsSupported:        true
    actionIconsSupported:    true
    bodySupported:           true
    bodyMarkupSupported:     false
    bodyHyperlinksSupported: false
    imageSupported:          true
    bodyImagesSupported:     false
    persistenceSupported:    true

    onNotification: function(notification) {
      notification.tracked = true;
      if (notification.lastGeneration) return;
      if (notif.doNotDisturb && notification.urgency !== NotificationUrgency.Critical) return;
      notif.addPopup(notification);
    }
  }

  // Lazy popup window — only created when popups exist
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
        margins { top: notif.topMargin; left: notif.sideMargin }

        implicitWidth: notif.panelWidth
        implicitHeight: popupColumn.implicitHeight

        Column {
          id: popupColumn
          width: parent.width
          spacing: 8

          Repeater {
            model: popupList

            Rectangle {
              id: popupCard
              property var notification: modelData
              property int timeoutMs: notif.popupTimeoutFor(notification)

              width: popupColumn.width
              implicitHeight: popupInner.implicitHeight + notif.cardPadding * 2
              height: implicitHeight
              radius: notif.cardRadius
              color: notif.cardBgFor(notification)
              border.width: 1
              border.color: notif.cardBorderFor(notification)

              opacity: 0
              transform: Translate { id: popupTranslate; x: -(notif.panelWidth + notif.sideMargin) }
              Component.onCompleted: {
                if (!notification._qsShown) {
                  notification._qsShown = true;
                  appearAnim.start();
                  if (popupTimer.interval > 0) popupTimer.start();
                } else {
                  opacity = 1;
                  popupTranslate.x = 0;
                }
              }
              ParallelAnimation {
                id: appearAnim
                NumberAnimation { target: popupCard;    property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
                NumberAnimation { target: popupTranslate; property: "x";    to: 0; duration: 220; easing.type: Easing.OutCubic }
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
                    Layout.preferredWidth: 28; Layout.preferredHeight: 28
                    radius: 8
                    color: Colors.bgSubtle
                    border.width: 1
                    border.color: Colors.border

                    AppIcon {
                      anchors.centerIn: parent
                      notification: popupCard.notification
                      iconSize: 18
                      fallbackBg: Colors.bgSubtle
                    }
                  }

                  Rectangle {
                    Layout.preferredWidth: 4; Layout.preferredHeight: 14
                    radius: 2
                    color: notif.urgencyColor(notification)
                    Layout.alignment: Qt.AlignVCenter
                  }

                  Text {
                    text: (notification && notification.appName && notification.appName.length > 0)
                      ? notification.appName.toUpperCase() : "NOTIFICATION"
                    color: Colors.accent
                    font.family: notif.uiFont
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1.2
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                  }

                  Rectangle {
                    id: closePopup
                    Layout.preferredWidth: 20; Layout.preferredHeight: 20
                    radius: 5
                    color: "transparent"
                    border.width: 1
                    border.color: Colors.border
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                      anchors.centerIn: parent
                      text: "\u00D7"
                      color: Colors.fgDim
                      font.family: notif.uiFont
                      font.pixelSize: 12
                      font.bold: true
                    }

                    MouseArea {
                      anchors.fill: parent
                      hoverEnabled: true
                      onEntered: closePopup.color = Colors.bgSubtle
                      onExited:  closePopup.color = "transparent"
                      onClicked: notif.removePopup(notification)
                    }
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
                  onActionInvoked: notif.removePopup(notification)
                }
              }

              Timer {
                id: popupTimer
                interval: popupCard.timeoutMs
                repeat: false
                onTriggered: {
                  if (!notif) return;
                  var n = notification;
                  if (n) n.expire();
                  notif.removePopup(n);
                }
              }

              HoverHandler {
                id: popupHover
                onHoveredChanged: {
                  if (hovered) popupTimer.stop();
                  else if (popupTimer.interval > 0) popupTimer.restart();
                }
              }
            }
          }
        }
      }
    }
  }
}
