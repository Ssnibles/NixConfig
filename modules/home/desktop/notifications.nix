{
  config,
  pkgs,
  ...
}:
let
  c =
    (import ../../../lib/stylix/semantic-colors.nix { stylixColors = config.lib.stylix.colors; })
    .withHash;
in
{
  programs.quickshell = {
    enable = true;
    package = pkgs.unstable.quickshell;
  };

  home.sessionVariables.QML2_IMPORT_PATH = "${pkgs.unstable.quickshell}/lib/qt-6/qml";

  xdg.configFile."quickshell/shell.qml".text = ''
    import Quickshell
    import Quickshell.Io
    import Quickshell.Services.Notifications
    import QtQuick
    import QtQuick.Layouts
    import QtQml

    ShellRoot {
      id: root

      // ---------------------------------------------------------------------
      // Notification state
      // ---------------------------------------------------------------------
      property bool controlPanelVisible: false
      property bool doNotDisturb: false
      property int popupTimeoutMs: 6000
      property int maxPopups: 5
      property string uiFont: "JetBrains Mono"

      // ---------------------------------------------------------------------
      // Theme palette from Stylix semantic colors
      // ---------------------------------------------------------------------
      readonly property color bg: "${c.bg}"
      readonly property color bgRaised: "${c.bgRaised}"
      readonly property color bgSubtle: "${c.bgSubtle}"
      readonly property color border: "${c.border}"
      readonly property color fg: "${c.fg}"
      readonly property color fgMid: "${c.fgMid}"
      readonly property color fgDim: "${c.fgDim}"
      readonly property color accent: "${c.accent}"
      readonly property color yellow: "${c.yellow}"
      readonly property color teal: "${c.teal}"
      readonly property color purple: "${c.purple}"
      readonly property color red: "${c.red}"
      readonly property color green: "${c.green}"

      // ---------------------------------------------------------------------
      // Notification Logic Helpers
      // ---------------------------------------------------------------------
      function stripMarkup(text) {
        if (!text || text.length === 0) return "";
        return text.replace(/<[^>]*>/g, "");
      }

      function urgencyColor(notification) {
        if (!notification) return root.accent;
        if (notification.urgency === NotificationUrgency.Critical) return root.red;
        if (notification.urgency === NotificationUrgency.Low) return root.fgDim;
        if (notification.urgency === NotificationUrgency.Normal) return root.accent;
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
        popupModel.values = popupModel.values.filter((candidate) => candidate !== notification);
      }

      function addPopup(notification) {
        if (!notification) return;
        const deduped = popupModel.values.filter(
          (candidate) => candidate && candidate.id !== notification.id
        );
        deduped.unshift(notification);
        popupModel.values = deduped.slice(0, root.maxPopups);

        notification.closed.connect(() => {
          root.removePopup(notification);
        });
      }

      function clearNotifications() {
        const notifications = [...notificationServer.trackedNotifications.values];
        for (let i = 0; i < notifications.length; i++) {
          notifications[i].dismiss();
        }
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

        actionsSupported: true
        actionIconsSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        imageSupported: true
        bodyImagesSupported: false
        persistenceSupported: true

        onNotification: (notification) => {
          notification.tracked = true;
          if (notification.lastGeneration) return;

          if (root.doNotDisturb && notification.urgency !== NotificationUrgency.Critical) return;
          root.addPopup(notification);
        }
      }

      // ---------------------------------------------------------------------
      // IPC surface
      // ---------------------------------------------------------------------
      IpcHandler {
        target: "controlpanel"

        function toggle(): void {
          root.controlPanelVisible = !root.controlPanelVisible;
        }

        function show(): void {
          root.controlPanelVisible = true;
        }

        function hide(): void {
          root.controlPanelVisible = false;
        }

        function toggleDnd(): void {
          root.doNotDisturb = !root.doNotDisturb;
        }
      }

      // ---------------------------------------------------------------------
      // Notification Popups
      // ---------------------------------------------------------------------
      PanelWindow {
        visible: popupModel.values.length > 0
        focusable: false
        aboveWindows: true
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        anchors {
          top: true
          left: true
        }

        margins {
          top: 64
          left: 24
        }

        width: 520
        height: popupColumn.implicitHeight

        Rectangle {
          anchors.fill: parent
          color: "transparent"

          Column {
            id: popupColumn
            width: parent.width
            spacing: 10

            Repeater {
              model: popupModel

              Rectangle {
                property var notification: modelData

                width: popupColumn.width
                implicitHeight: popupContent.implicitHeight + 20
                height: implicitHeight
                radius: 8
                color: root.bgRaised
                border.width: 1
                border.color: root.border

                Rectangle {
                  anchors.left: parent.left
                  anchors.top: parent.top
                  anchors.bottom: parent.bottom
                  width: 4
                  radius: 4
                  color: root.urgencyColor(notification)
                }

                Column {
                  id: popupContent
                  x: 14
                  y: 10
                  width: parent.width - 28
                  spacing: 6

                  Row {
                    width: parent.width
                    spacing: 8

                    Item {
                      width: 24
                      height: 24

                      Image {
                        id: popupIcon
                        anchors.fill: parent
                        source: root.appIconSource(notification)
                        fillMode: Image.PreserveAspectFit
                        visible: status === Image.Ready
                      }

                      Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: root.bgSubtle
                        border.width: 1
                        border.color: root.border
                        visible: !popupIcon.visible

                        Text {
                          anchors.centerIn: parent
                          text: notification && notification.appName && notification.appName.length > 0
                            ? notification.appName[0].toUpperCase()
                            : "N"
                          color: root.teal
                          font.family: root.uiFont
                          font.pixelSize: 11
                          font.bold: true
                        }
                      }
                    }

                    Text {
                      text: notification && notification.appName && notification.appName.length > 0
                        ? notification.appName
                        : "Notification"
                      color: root.accent
                      font.family: root.uiFont
                      font.pixelSize: 11
                      font.bold: true
                      elide: Text.ElideRight
                      width: Math.max(0, parent.width - closePopup.width - parent.spacing - 24)
                    }

                    Rectangle {
                      id: closePopup
                      width: 22
                      height: 22
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
                        onExited: closePopup.color = "transparent"
                        onClicked: root.removePopup(notification)
                      }
                    }
                  }

                  Text {
                    text: notification && notification.summary && notification.summary.length > 0
                      ? root.stripMarkup(notification.summary)
                      : (notification && notification.appName && notification.appName.length > 0 ? notification.appName : "Notification")
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

                  Row {
                    width: parent.width
                    spacing: 6
                    visible: notification && notification.actions && notification.actions.length > 0

                    Repeater {
                      model: notification && notification.actions ? notification.actions : []

                      Rectangle {
                        required property QtObject modelData

                        height: 26
                        radius: 6
                        color: "transparent"
                        border.width: 1
                        border.color: root.border
                        width: actionText.implicitWidth + 20

                        Text {
                          id: actionText
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
                          onExited: parent.color = "transparent"
                          onClicked: {
                            modelData.invoke();
                            root.removePopup(notification);
                          }
                        }
                      }
                    }
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

                HoverHandler {
                  id: popupHover
                }

                Connections {
                  target: notification

                  function onClosed(reason) {
                    root.removePopup(notification);
                  }
                }
              }
            }
          }
        }
      }

      // ---------------------------------------------------------------------
      // Control Panel
      // ---------------------------------------------------------------------
      PanelWindow {
        visible: root.controlPanelVisible
        focusable: true
        aboveWindows: true
        exclusionMode: exclusionMode.Ignore
        color: "transparent"

        anchors {
          top: true
          right: true
        }

        margins {
          top: 24
          right: 24
        }

        width: 520
        height: 640

        Rectangle {
          anchors.fill: parent
          radius: 8
          color: root.bgRaised
          border.width: 1
          border.color: root.border

          Column {
            anchors.fill: parent
            anchors.margins: 14
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
                width: parent.width - closePanel.width - parent.spacing
                verticalAlignment: Text.AlignVCenter
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
                  onExited: closePanel.color = "transparent"
                  onClicked: root.controlPanelVisible = false
                }
              }
            }

            Row {
              width: parent.width
              spacing: 8

              Rectangle {
                id: dndToggle
                width: 210
                height: 30
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
                width: 138
                height: 30
                radius: 6
                color: "transparent"
                border.width: 1
                border.color: root.border

                Text {
                  anchors.centerIn: parent
                  text: "Clear All (" + notificationServer.trackedNotifications.count + ")"
                  color: root.fgMid
                  font.family: root.uiFont
                  font.pixelSize: 11
                  font.bold: true
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  onEntered: clearAll.color = root.bgSubtle
                  onExited: clearAll.color = "transparent"
                  onClicked: root.clearNotifications()
                }
              }
            }

            Text {
              width: parent.width
              text: root.doNotDisturb
                ? "Do Not Disturb is enabled. Critical alerts still appear."
                : "Popup timeout adapts to notification urgency and app timeout hints."
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
              height: parent.height - 110
              spacing: 10
              clip: true
              model: notificationServer.trackedNotifications

              delegate: Rectangle {
                required property QtObject modelData

                width: notificationList.width
                implicitHeight: notificationContent.implicitHeight + 24
                height: implicitHeight
                radius: 8
                color: root.bgSubtle
                border.width: 1
                border.color: modelData.urgency === NotificationUrgency.Critical ? root.red : root.border

                property QtObject notification: modelData

                Column {
                  id: notificationContent
                  x: 14
                  y: 10
                  width: parent.width - 28
                  spacing: 6

                  Row {
                    width: parent.width
                    spacing: 8

                    Item {
                      width: 24
                      height: 24

                      Image {
                        id: panelIcon
                        anchors.fill: parent
                        source: root.appIconSource(notification)
                        fillMode: Image.PreserveAspectFit
                        visible: status === Image.Ready
                      }

                      Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: root.bgRaised
                        border.width: 1
                        border.color: root.border
                        visible: !panelIcon.visible

                        Text {
                          anchors.centerIn: parent
                          text: notification && notification.appName && notification.appName.length > 0
                            ? notification.appName[0].toUpperCase()
                            : "N"
                          color: root.teal
                          font.family: root.uiFont
                          font.pixelSize: 11
                          font.bold: true
                        }
                      }
                    }

                    Text {
                      text: notification.appName && notification.appName.length > 0 ? notification.appName : "Notification"
                      color: root.accent
                      font.family: root.uiFont
                      font.pixelSize: 11
                      font.bold: true
                      elide: Text.ElideRight
                      width: Math.max(0, parent.width - dismissButton.width - parent.spacing - 24)
                    }

                    Rectangle {
                      id: dismissButton
                      width: 22
                      height: 22
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
                        onEntered: dismissButton.color = root.bgRaised
                        onExited: dismissButton.color = "transparent"
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

                  Row {
                    width: parent.width
                    spacing: 6
                    visible: actionButtons.count > 0

                    Repeater {
                      id: actionButtons
                      model: notification.actions

                      Rectangle {
                        required property QtObject modelData

                        height: 26
                        radius: 6
                        color: "transparent"
                        border.width: 1
                        border.color: root.border
                        width: actionLabel.implicitWidth + 20

                        Text {
                          id: actionLabel
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
                          onEntered: parent.color = root.bgRaised
                          onExited: parent.color = "transparent"
                          onClicked: modelData.invoke()
                        }
                      }
                    }
                  }
                }
              }

              Rectangle {
                anchors.centerIn: parent
                color: "transparent"
                visible: notificationList.count === 0

                Text {
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
  '';
}
