import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQml

// ═══════════════════════════════════════════════════════════════════════════
// Notification Daemon — Quickshell QML
// ═══════════════════════════════════════════════════════════════════════════
// Colors generated from Stylix (rose-pine). Rebuild to refresh palette.
// ═══════════════════════════════════════════════════════════════════════════

ShellRoot {
  id: root

  property bool controlPanelVisible: false
  property bool doNotDisturb: false
  property int  popupTimeoutMs: 6000
  property int  maxPopups: 5
  property string uiFont: "JetBrains Mono"

  readonly property int  topMargin: 54
  readonly property int  sideMargin: 24
  readonly property int  panelWidth: 520
  readonly property int  cardRadius: 8
  readonly property int  cardPadding: 14
  readonly property int  cardSpacing: 6
  readonly property int  iconSize: 24
  readonly property int  closeBtnSize: 22
  readonly property int  actionBtnHeight: 26

  readonly property color bg:       "#191724"
  readonly property color bgRaised: "#1f1d2e"
  readonly property color bgSubtle: "#26233a"
  readonly property color border:   "#26233a"
  readonly property color fg:       "#e0def4"
  readonly property color fgMid:    "#908caa"
  readonly property color fgDim:    "#6e6a86"
  readonly property color accent:   "#c4a7e7"
  readonly property color yellow:   "#ebbcba"
  readonly property color teal:     "#9ccfd8"
  readonly property color purple:   "#f6c177"
  readonly property color red:      "#eb6f92"
  readonly property color green:    "#31748f"

  function stripMarkup(text) {
    if (!text || text.length === 0) return "";
    return text.replace(/<[^>]*>/g, "");
  }

  function urgencyColor(notification) {
    if (!notification) return root.accent;
    if (notification.urgency === NotificationUrgency.Critical) return root.red;
    if (notification.urgency === NotificationUrgency.Low)      return root.fgDim;
    if (notification.urgency === NotificationUrgency.Normal)   return root.accent;
    return root.yellow;
  }

  function appIconSource(notification) {
    if (!notification) return "";
    if (notification.image && notification.image.length > 0) return notification.image;
    if (!notification.appIcon || notification.appIcon.length === 0) return "";
    if (notification.appIcon.startsWith("/")) return "file://" + notification.appIcon;
    return "image://icon/" + notification.appIcon;
  }

  function popupTimeoutFor(notification) {
    if (!notification) return root.popupTimeoutMs;
    if (notification.urgency === NotificationUrgency.Critical) return 0;
    if (notification.expireTimeout > 0) {
      const ms = Math.round(notification.expireTimeout * 1000);
      return Math.max(2500, Math.min(15000, ms));
    }
    if (notification.urgency === NotificationUrgency.Low) return 3500;
    return root.popupTimeoutMs;
  }

  function removePopup(notification) {
    popupModel.values = popupModel.values.filter(n => n !== notification);
  }

  function addPopup(notification) {
    if (!notification) return;
    const deduped = popupModel.values.filter(n => n && n.id !== notification.id);
    deduped.unshift(notification);
    popupModel.values = deduped.slice(0, root.maxPopups);
    notification.closed.connect(() => root.removePopup(notification));
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
      if (root.doNotDisturb && notification.urgency !== NotificationUrgency.Critical) return;
      root.addPopup(notification);
    }
  }

  IpcHandler {
    target: "controlpanel"

    function toggle(): void  { root.controlPanelVisible = !root.controlPanelVisible; }
    function show(): void    { root.controlPanelVisible = true; }
    function hide(): void    { root.controlPanelVisible = false; }
    function toggleDnd(): void { root.doNotDisturb = !root.doNotDisturb; }
  }

  component AppIcon: Item {
    property var notification: null
    property color fallbackBg: root.bgSubtle

    width: root.iconSize
    height: root.iconSize

    Image {
      id: iconImg
      anchors.fill: parent
      source: root.appIconSource(notification)
      fillMode: Image.PreserveAspectFit
      visible: status === Image.Ready
    }

    Rectangle {
      anchors.fill: parent
      radius: 4
      color: fallbackBg
      border.width: 1
      border.color: root.border
      visible: !iconImg.visible

      Text {
        anchors.centerIn: parent
        text: (notification && notification.appName && notification.appName.length > 0)
          ? notification.appName[0].toUpperCase()
          : "N"
        color: root.teal
        font.family: root.uiFont
        font.pixelSize: 11
        font.bold: true
      }
    }
  }

  component ActionRow: Row {
    property var actions: []
    signal actionInvoked()

    spacing: root.cardSpacing
    visible: actions && actions.length > 0

    Repeater {
      model: actions

      Rectangle {
        required property QtObject modelData

        height: root.actionBtnHeight
        radius: 6
        color: "transparent"
        border.width: 1
        border.color: root.border
        width: btnLabel.implicitWidth + 20

        Text {
          id: btnLabel
          anchors.centerIn: parent
          text: modelData.text
          color: root.fgMid
          font.family: root.uiFont
          font.pixelSize: 11
          textFormat: Text.PlainText
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          onEntered: parent.color = root.bgSubtle
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
    margins { top: root.topMargin; left: root.sideMargin }

    implicitWidth: root.panelWidth
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
          implicitHeight: popupInner.implicitHeight + root.cardPadding * 2
          height: implicitHeight
          radius: root.cardRadius
          color: root.bgRaised
          border.width: 1
          border.color: root.border

          opacity: 0
          transform: Translate { id: popupTranslate; x: -(root.panelWidth + root.sideMargin) }
          Component.onCompleted: appearAnim.start()
          ParallelAnimation {
            id: appearAnim
            NumberAnimation { target: popupCard;    property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { target: popupTranslate; property: "x";    to: 0; duration: 220; easing.type: Easing.OutCubic }
          }

          Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 3
            radius: root.cardRadius
            color: root.urgencyColor(notification)
          }

          Column {
            id: popupInner
            x: root.cardPadding + 8
            y: root.cardPadding
            width: parent.width - x - root.cardPadding
            spacing: root.cardSpacing

            Row {
              width: parent.width
              spacing: 8

              AppIcon { notification: popupCard.notification; fallbackBg: root.bgSubtle }

              Text {
                text: (notification && notification.appName && notification.appName.length > 0)
                  ? notification.appName
                  : "Notification"
                color: root.accent
                font.family: root.uiFont
                font.pixelSize: 11
                font.bold: true
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                height: root.iconSize
                width: Math.max(0, parent.width - closePopup.width - parent.spacing - root.iconSize - parent.spacing)
              }

              Rectangle {
                id: closePopup
                width: root.closeBtnSize
                height: root.closeBtnSize
                radius: 4
                color: "transparent"
                border.width: 1
                border.color: root.border

                Text {
                  anchors.centerIn: parent
                  text: "×"
                  color: root.fgDim
                  font.family: root.uiFont
                  font.pixelSize: 13
                  font.bold: true
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  onEntered: closePopup.color = root.bgSubtle
                  onExited:  closePopup.color = "transparent"
                  onClicked: root.removePopup(notification)
                }
              }
            }

            Text {
              text: (notification && notification.summary && notification.summary.length > 0)
                ? root.stripMarkup(notification.summary)
                : ((notification && notification.appName && notification.appName.length > 0)
                    ? notification.appName
                    : "Notification")
              width: parent.width
              color: root.fg
              font.family: root.uiFont
              font.pixelSize: 13
              font.bold: true
              wrapMode: Text.Wrap
              textFormat: Text.PlainText
              visible: text.length > 0
            }

            Text {
              text: notification ? root.stripMarkup(notification.body || "") : ""
              width: parent.width
              color: root.fgMid
              font.family: root.uiFont
              font.pixelSize: 12
              wrapMode: Text.Wrap
              textFormat: Text.PlainText
              visible: text.length > 0
            }

            ActionRow {
              width: parent.width
              actions: (notification && notification.actions) ? notification.actions : []
              onActionInvoked: root.removePopup(notification)
            }
          }

          Timer {
            id: popupTimer
            interval: root.popupTimeoutFor(notification)
            running: interval > 0 && !popupHover.hovered
            repeat: false
            onTriggered: {
              if (notification) notification.expire();
              root.removePopup(notification);
            }
          }

          HoverHandler { id: popupHover }

          Connections {
            target: notification
            function onClosed(reason) { root.removePopup(notification); }
          }
        }
      }
    }
  }

  // ── Control panel ────────────────────────────────────────────────────────
  PanelWindow {
    id: controlPanel
    visible: root.controlPanelVisible
    focusable: true
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    anchors { top: true; right: true }
    margins { top: root.topMargin; right: root.sideMargin }

    implicitWidth: root.panelWidth
    implicitHeight: 640

    Rectangle {
      anchors.fill: parent
      radius: root.cardRadius
      color: root.bgRaised
      border.width: 1
      border.color: root.border

      Column {
        anchors.fill: parent
        anchors.margins: root.cardPadding
        spacing: 12

        Row {
          width: parent.width
          spacing: 8

          Text {
            text: "Notifications"
            color: root.fg
            font.family: root.uiFont
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
            border.color: root.border

            Text {
              anchors.centerIn: parent
              text: "×"
              color: root.fgDim
              font.family: root.uiFont
              font.pixelSize: 14
              font.bold: true
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onEntered: closePanel.color = root.bgSubtle
              onExited:  closePanel.color = "transparent"
              onClicked: root.controlPanelVisible = false
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
            color: root.doNotDisturb ? root.accent : root.bgSubtle
            border.width: 1
            border.color: root.doNotDisturb ? root.accent : root.border

            Text {
              anchors.centerIn: parent
              text: root.doNotDisturb ? "DND: ON" : "DND: OFF"
              color: root.doNotDisturb ? root.bg : root.fg
              font.family: root.uiFont
              font.pixelSize: 11
              font.bold: true
            }

            MouseArea {
              anchors.fill: parent
              onClicked: root.doNotDisturb = !root.doNotDisturb
            }
          }

          Rectangle {
            id: clearAll
            height: 30
            width: (parent.width - parent.spacing) / 2
            radius: 6
            color: "transparent"
            border.width: 1
            border.color: root.border

            Text {
              anchors.centerIn: parent
              text: "Clear All (" + notificationServer.trackedNotifications.values.length + ")"
              color: root.fgMid
              font.family: root.uiFont
              font.pixelSize: 11
              font.bold: true
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onEntered: clearAll.color = root.bgSubtle
              onExited:  clearAll.color = "transparent"
              onClicked: root.clearNotifications()
            }
          }
        }

        Text {
          width: parent.width
          text: root.doNotDisturb
            ? "Do Not Disturb is enabled. Critical alerts still appear."
            : "Popup timeout adapts to notification urgency and app hints."
          color: root.fgDim
          font.family: root.uiFont
          font.pixelSize: 11
          wrapMode: Text.Wrap
        }

        Rectangle {
          width: parent.width
          height: 1
          color: root.border
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
            implicitHeight: panelCardContent.implicitHeight + root.cardPadding * 2
            height: implicitHeight
            radius: root.cardRadius
            color: root.bgSubtle
            border.width: 1
            border.color: notification.urgency === NotificationUrgency.Critical
              ? root.red
              : root.border

            Column {
              id: panelCardContent
              x: root.cardPadding
              y: root.cardPadding
              width: parent.width - root.cardPadding * 2
              spacing: root.cardSpacing

              Row {
                width: parent.width
                spacing: 8

                AppIcon { notification: modelData; fallbackBg: root.bgRaised }

                Text {
                  text: (notification.appName && notification.appName.length > 0)
                    ? notification.appName
                    : "Notification"
                  color: root.accent
                  font.family: root.uiFont
                  font.pixelSize: 11
                  font.bold: true
                  elide: Text.ElideRight
                  verticalAlignment: Text.AlignVCenter
                  height: root.iconSize
                  width: Math.max(0, parent.width - dismissBtn.width - parent.spacing - root.iconSize - parent.spacing)
                }

                Rectangle {
                  id: dismissBtn
                  width: root.closeBtnSize
                  height: root.closeBtnSize
                  radius: 4
                  color: "transparent"
                  border.width: 1
                  border.color: root.border

                  Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: root.fgDim
                    font.family: root.uiFont
                    font.pixelSize: 13
                    font.bold: true
                  }

                  MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: dismissBtn.color = root.bgRaised
                    onExited:  dismissBtn.color = "transparent"
                    onClicked: notification.dismiss()
                  }
                }
              }

              Text {
                text: root.stripMarkup(notification.summary || "")
                width: parent.width
                color: root.fg
                font.family: root.uiFont
                font.pixelSize: 13
                font.bold: true
                wrapMode: Text.Wrap
                textFormat: Text.PlainText
                visible: text.length > 0
              }

              Text {
                text: root.stripMarkup(notification.body || "")
                width: parent.width
                color: root.fgMid
                font.family: root.uiFont
                font.pixelSize: 12
                wrapMode: Text.Wrap
                textFormat: Text.PlainText
                visible: text.length > 0
              }

              ActionRow {
                width: parent.width
                actions: notification.actions ? notification.actions : []
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
              color: root.fgDim
              font.family: root.uiFont
              font.pixelSize: 12
            }
          }
        }
      }
    }
  }
}
