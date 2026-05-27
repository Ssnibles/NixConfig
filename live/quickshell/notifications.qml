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
  Colors { id: colors }

  property bool controlPanelVisible: false
  property bool doNotDisturb: false
  property bool barVisible: true
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

  readonly property color bg:       colors.bg
  readonly property color bgRaised: colors.bgRaised
  readonly property color bgSubtle: colors.bgSubtle
  readonly property color border:   colors.border
  readonly property color fg:       colors.fg
  readonly property color fgMid:    colors.fgMid
  readonly property color fgDim:    colors.fgDim
  readonly property color accent:   colors.accent
  readonly property color yellow:   colors.yellow
  readonly property color teal:     colors.teal
  readonly property color purple:   colors.purple
  readonly property color red:      colors.red
  readonly property color green:    colors.green

  function stripMarkup(text) {
    if (!text || text.length === 0) return "";
    return text.replace(/<[^>]*>/g, "");
  }

  function urgencyColor(notification) {
    if (!notification) return notif.accent;
    if (notification.urgency === NotificationUrgency.Critical) return notif.red;
    if (notification.urgency === NotificationUrgency.Low)      return notif.fgDim;
    if (notification.urgency === NotificationUrgency.Normal)   return notif.accent;
    return notif.yellow;
  }

  function appIconSource(notification) {
    if (!notification) return "";
    if (notification.image && notification.image.length > 0) return notification.image;
    if (!notification.appIcon || notification.appIcon.length === 0) return "";
    if (notification.appIcon.startsWith("/")) return "file://" + notification.appIcon;
    return "image://icon/" + notification.appIcon;
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
    popupModel.values = popupModel.values.filter(n => n !== notification);
  }

  function addPopup(notification) {
    if (!notification) return;
    const deduped = popupModel.values.filter(n => n && n.id !== notification.id);
    deduped.unshift(notification);
    popupModel.values = deduped.slice(0, notif.maxPopups);
    notification.closed.connect(() => notif.removePopup(notification));
  }

  function clearNotifications() {
    const all = [...notificationServer.trackedNotifications.values];
    for (let i = 0; i < all.length; i++) all[i].dismiss();
  }

  onDoNotDisturbChanged: {
    if (doNotDisturb) popupModel.values = [];
  }

  ScriptModel {
    id: popupModel
    values: []
  }

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

  component AppIcon: Item {
    property var notification: null
    property color fallbackBg: notif.bgSubtle

    width: notif.iconSize
    height: notif.iconSize

    Image {
      id: iconImg
      anchors.fill: parent
      source: notif.appIconSource(notification)
      sourceSize.width: notif.iconSize
      sourceSize.height: notif.iconSize
      fillMode: Image.PreserveAspectFit
      visible: status === Image.Ready
    }

    Rectangle {
      anchors.fill: parent
      radius: 4
      color: fallbackBg
      border.width: 1
      border.color: notif.border
      visible: !iconImg.visible

      Text {
        anchors.centerIn: parent
        text: (notification && notification.appName && notification.appName.length > 0)
          ? notification.appName[0].toUpperCase()
          : "N"
        color: notif.teal
        font.family: notif.uiFont
        font.pixelSize: 11
        font.bold: true
      }
    }
  }

  component ActionRow: Row {
    property var actions: []
    signal actionInvoked()

    spacing: notif.cardSpacing
    visible: actions && actions.length > 0

    Repeater {
      model: actions

      Rectangle {
        required property QtObject modelData

        height: notif.actionBtnHeight
        radius: 6
        color: "transparent"
        border.width: 1
        border.color: notif.border
        width: btnLabel.implicitWidth + 20

        Text {
          id: btnLabel
          anchors.centerIn: parent
          text: modelData.text
          color: notif.fgMid
          font.family: notif.uiFont
          font.pixelSize: 11
          textFormat: Text.PlainText
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          onEntered: parent.color = notif.bgSubtle
          onExited:  parent.color = "transparent"
          onClicked: {
            modelData.invoke();
            actionInvoked();
          }
        }
      }
    }
  }

  // ── Notification popups ──────────────────────────────────────────────────
  PanelWindow {
    id: popupWindow
    visible: popupModel.values.length > 0
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
        model: popupModel

          Rectangle {
            id: popupCard
            property var notification: modelData

            width: popupColumn.width
            implicitHeight: popupInner.implicitHeight + notif.cardPadding * 2
          height: implicitHeight
          radius: notif.cardRadius
          color: notif.bgRaised
          border.width: 1
          border.color: notif.border

          opacity: 0
          transform: Translate { id: popupTranslate; x: -(notif.panelWidth + notif.sideMargin) }
          Component.onCompleted: appearAnim.start()
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

              AppIcon { notification: popupCard.notification; fallbackBg: notif.bgSubtle }

              Text {
                text: (notification && notification.appName && notification.appName.length > 0)
                  ? notification.appName
                  : "Notification"
                color: notif.accent
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
                border.color: notif.border

                Text {
                  anchors.centerIn: parent
                  text: "×"
                  color: notif.fgDim
                  font.family: notif.uiFont
                  font.pixelSize: 13
                  font.bold: true
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  onEntered: closePopup.color = notif.bgSubtle
                  onExited:  closePopup.color = "transparent"
                  onClicked: notif.removePopup(notification)
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
              color: notif.fg
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
              color: notif.fgMid
              font.family: notif.uiFont
              font.pixelSize: 12
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
            interval: notif.popupTimeoutFor(notification)
            running: interval > 0 && !popupHover.hovered
            repeat: false
            onTriggered: {
              if (notification) notification.expire();
              notif.removePopup(notification);
            }
          }

          HoverHandler { id: popupHover }

          Connections {
            target: notification
            function onClosed(reason) { notif.removePopup(notification); }
          }
        }
      }
    }
  }

  // ── Control panel ────────────────────────────────────────────────────────
  PanelWindow {
    id: controlPanel
    visible: notif.controlPanelVisible
    focusable: true
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    anchors { top: true; right: true }
    margins { top: notif.topMargin; right: notif.sideMargin }

    implicitWidth: notif.panelWidth
    implicitHeight: 640

    Rectangle {
      anchors.fill: parent
      radius: notif.cardRadius
      color: notif.bgRaised
      border.width: 1
      border.color: notif.border

      Column {
        anchors.fill: parent
        anchors.margins: notif.cardPadding
        spacing: 12

        Row {
          width: parent.width
          spacing: 8

          Text {
            text: "Notifications"
            color: notif.fg
            font.family: notif.uiFont
            font.pixelSize: 14
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            height: 26
            width: parent.width - closePanel.width - parent.spacing
          }

          Rectangle {
            id: closePanel
            width: 26
            height: 26
            radius: 6
            color: "transparent"
            border.width: 1
            border.color: notif.border

            Text {
              anchors.centerIn: parent
              text: "×"
              color: notif.fgDim
              font.family: notif.uiFont
              font.pixelSize: 14
              font.bold: true
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onEntered: closePanel.color = notif.bgSubtle
              onExited:  closePanel.color = "transparent"
              onClicked: notif.controlPanelVisible = false
            }
          }
        }

        Row {
          width: parent.width
          spacing: 8

          Rectangle {
            id: dndToggle
            height: 30
            width: (parent.width - parent.spacing) / 2
            radius: 6
            color: notif.doNotDisturb ? notif.accent : notif.bgSubtle
            border.width: 1
            border.color: notif.doNotDisturb ? notif.accent : notif.border

            Text {
              anchors.centerIn: parent
              text: notif.doNotDisturb ? "DND: ON" : "DND: OFF"
              color: notif.doNotDisturb ? notif.bg : notif.fg
              font.family: notif.uiFont
              font.pixelSize: 11
              font.bold: true
            }

            MouseArea {
              anchors.fill: parent
              onClicked: notif.doNotDisturb = !notif.doNotDisturb
            }
          }

          Rectangle {
            id: clearAll
            height: 30
            width: (parent.width - parent.spacing) / 2
            radius: 6
            color: "transparent"
            border.width: 1
            border.color: notif.border

            Text {
              anchors.centerIn: parent
              text: "Clear All (" + notificationServer.trackedNotifications.values.length + ")"
              color: notif.fgMid
              font.family: notif.uiFont
              font.pixelSize: 11
              font.bold: true
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onEntered: clearAll.color = notif.bgSubtle
              onExited:  clearAll.color = "transparent"
              onClicked: notif.clearNotifications()
            }
          }
        }

        Text {
          width: parent.width
          text: notif.doNotDisturb
            ? "Do Not Disturb is enabled. Critical alerts still appear."
            : "Popup timeout adapts to notification urgency and app hints."
          color: notif.fgDim
          font.family: notif.uiFont
          font.pixelSize: 11
          wrapMode: Text.Wrap
        }

        Rectangle {
          width: parent.width
          height: 1
          color: notif.border
        }

        ListView {
          id: notificationList
          width: parent.width
          height: parent.height - 120
          spacing: 8
          clip: true
          model: notificationServer.trackedNotifications

          delegate: Rectangle {
            required property QtObject modelData
            property QtObject notification: modelData

            width: notificationList.width
            implicitHeight: panelCardContent.implicitHeight + notif.cardPadding * 2
            height: implicitHeight
            radius: notif.cardRadius
            color: notif.bgSubtle
            border.width: 1
            border.color: notification && notification.urgency === NotificationUrgency.Critical
              ? notif.red
              : notif.border

            Column {
              id: panelCardContent
              x: notif.cardPadding
              y: notif.cardPadding
              width: parent.width - notif.cardPadding * 2
              spacing: notif.cardSpacing

              Row {
                width: parent.width
                spacing: 8

                AppIcon { notification: modelData; fallbackBg: notif.bgRaised }

                Text {
                  text: (notification && notification.appName && notification.appName.length > 0)
                    ? notification.appName
                    : "Notification"
                  color: notif.accent
                  font.family: notif.uiFont
                  font.pixelSize: 11
                  font.bold: true
                  elide: Text.ElideRight
                  verticalAlignment: Text.AlignVCenter
                  height: notif.iconSize
                  width: Math.max(0, parent.width - dismissBtn.width - parent.spacing - notif.iconSize - parent.spacing)
                }

                Rectangle {
                  id: dismissBtn
                  width: notif.closeBtnSize
                  height: notif.closeBtnSize
                  radius: 4
                  color: "transparent"
                  border.width: 1
                  border.color: notif.border

                  Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: notif.fgDim
                    font.family: notif.uiFont
                    font.pixelSize: 13
                    font.bold: true
                  }

                  MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: dismissBtn.color = notif.bgRaised
                    onExited:  dismissBtn.color = "transparent"
                    onClicked: notification.dismiss()
                  }
                }
              }

              Text {
                text: notification ? notif.stripMarkup(notification.summary || "") : ""
                width: parent.width
                color: notif.fg
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
                color: notif.fgMid
                font.family: notif.uiFont
                font.pixelSize: 12
                wrapMode: Text.Wrap
                textFormat: Text.PlainText
                visible: text.length > 0
              }

              ActionRow {
                width: parent.width
                actions: notification && notification.actions ? notification.actions : []
              }
            }
          }

          Item {
            anchors.centerIn: parent
            visible: notificationList.count === 0
            width: parent.width

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "No notifications"
              color: notif.fgDim
              font.family: notif.uiFont
              font.pixelSize: 12
            }
          }
        }
      }
    }
  }
}
