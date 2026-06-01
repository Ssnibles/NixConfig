import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQml

// ═══════════════════════════════════════════════════════════════════════════
// Notification Daemon — Quickshell QML
// ═══════════════════════════════════════════════════════════════════════════
// Colors loaded from Colors.qml (generated from Stylix). Rebuild to refresh.
// ═══════════════════════════════════════════════════════════════════════════

Item {
  id: notif
  property bool doNotDisturb: false
  property bool barVisible: true
  property alias notificationServer: notificationServer
  property int  popupTimeoutMs: 6000
  property int  maxPopups: 5
  property string uiFont: "JetBrains Mono"

  readonly property int  topMargin: barVisible ? 54 : sideMargin
  readonly property int  sideMargin: 24
  readonly property int  panelWidth: 520
  readonly property int  cardRadius: 8
  readonly property int  cardPadding: 14
  readonly property int  cardSpacing: 6
  readonly property int  iconSize: 24
  readonly property int  closeBtnSize: 22
  readonly property int  actionBtnHeight: 26

  function stripMarkup(text) {
    if (!text || text.length === 0) return "";
    return text.replace(/<[^>]*>/g, "");
  }

  function urgencyColor(notification) {
    if (!notification) return Colors.accent;
    if (notification.urgency === NotificationUrgency.Critical) return Colors.red;
    if (notification.urgency === NotificationUrgency.Low)      return Colors.fgDim;
    if (notification.urgency === NotificationUrgency.Normal)   return Colors.accent;
    return Colors.yellow;
  }

  function popupTimeoutFor(notification) {
    if (!notification) return notif.popupTimeoutMs;
    if (notification.urgency === NotificationUrgency.Critical) return 0;
    if (notification.expireTimeout > 0) {
      const ms = Math.round(notification.expireTimeout * 1000);
      return Math.max(2500, Math.min(15000, ms));
    }
    if (notification.urgency === NotificationUrgency.Low) return 3500;
    return notif.popupTimeoutMs;
  }

  function removePopup(notification) {
    const idx = popupList.indexOf(notification);
    if (idx >= 0) popupList.splice(idx, 1);
    popupListChanged();
  }

  function addPopup(notification) {
    if (!notification) return;
    const deduped = popupList.filter(n => n && n.id !== notification.id);
    deduped.unshift(notification);
    popupList = deduped.slice(0, notif.maxPopups);
    notification.closed.connect(() => notif.removePopup(notification));
  }

  function clearNotifications() {
    const all = [...notificationServer.trackedNotifications.values];
    for (let i = 0; i < all.length; i++) all[i].dismiss();
  }

  onDoNotDisturbChanged: {
    if (doNotDisturb) popupList = [];
  }

  property var popupList: []

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

    onNotification: (notification) => {
      notification.tracked = true;
      if (notification.lastGeneration) return;
      if (notif.doNotDisturb && notification.urgency !== NotificationUrgency.Critical) return;
      notif.addPopup(notification);
    }
  }

  // ── Notification popups ──────────────────────────────────────────────────
  PanelWindow {
    id: popupWindow
    visible: popupList.length > 0
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
            property var removeFn: notif.removePopup
            property int timeoutMs: notif.popupTimeoutFor(notification)

            width: popupColumn.width
            implicitHeight: popupInner.implicitHeight + notif.cardPadding * 2
          height: implicitHeight
          radius: notif.cardRadius
          color: Colors.bgRaised
          border.width: 1
          border.color: Colors.border

          opacity: 0
          transform: Translate { id: popupTranslate; x: -(notif.panelWidth + notif.sideMargin) }
          Component.onCompleted: {
            appearAnim.start();
            if (popupTimer.interval > 0) popupTimer.start();
          }
          ParallelAnimation {
            id: appearAnim
            NumberAnimation { target: popupCard;    property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { target: popupTranslate; property: "x";    to: 0; duration: 220; easing.type: Easing.OutCubic }
          }

          Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 3
            radius: notif.cardRadius
            color: notif.urgencyColor(notification)
          }

          Column {
            id: popupInner
            x: notif.cardPadding + 8
            y: notif.cardPadding
            width: parent.width - x - notif.cardPadding
            spacing: notif.cardSpacing

            Row {
              width: parent.width
              spacing: 8

              AppIcon { notification: popupCard.notification; fallbackBg: Colors.bgSubtle }

              Text {
                text: (notification && notification.appName && notification.appName.length > 0)
                  ? notification.appName
                  : "Notification"
                color: Colors.accent
                font.family: notif.uiFont
                font.pixelSize: 11
                font.bold: true
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                height: notif.iconSize
                width: Math.max(0, parent.width - closePopup.width - parent.spacing - notif.iconSize - parent.spacing)
              }

              Rectangle {
                id: closePopup
                width: notif.closeBtnSize
                height: notif.closeBtnSize
                radius: 4
                color: "transparent"
                border.width: 1
                border.color: Colors.border

                Text {
                  anchors.centerIn: parent
                  text: "×"
                  color: Colors.fgDim
                  font.family: notif.uiFont
                  font.pixelSize: 13
                  font.bold: true
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  onEntered: closePopup.color = Colors.bgSubtle
                  onExited:  closePopup.color = "transparent"
                  onClicked: removeFn(notification)
                }
              }
            }

            Text {
              text: (notification && notification.summary && notification.summary.length > 0)
                ? notif.stripMarkup(notification.summary)
                : ((notification && notification.appName && notification.appName.length > 0)
                    ? notification.appName
                    : "Notification")
              width: parent.width
              color: Colors.fg
              font.family: notif.uiFont
              font.pixelSize: 13
              font.bold: true
              wrapMode: Text.Wrap
              textFormat: Text.PlainText
              visible: text.length > 0
            }

            Text {
              text: notification ? notif.stripMarkup(notification.body || "") : ""
              width: parent.width
              color: Colors.fgMid
              font.family: notif.uiFont
              font.pixelSize: 12
              wrapMode: Text.Wrap
              textFormat: Text.PlainText
              visible: text.length > 0
            }

            ActionRow {
              width: parent.width
              actions: (notification && notification.actions) ? notification.actions : []
              onActionInvoked: removeFn(notification)
            }
          }

          Timer {
            id: popupTimer
            interval: popupCard.timeoutMs
            repeat: false
            onTriggered: {
              const n = notification;
              if (n) n.expire();
              removeFn(n);
            }
          }

          HoverHandler {
            id: popupHover
            onHoveredChanged: {
              if (hovered) {
                popupTimer.stop();
              } else if (popupTimer.interval > 0) {
                popupTimer.restart();
              }
            }
          }
        }
      }
    }
  }

}
