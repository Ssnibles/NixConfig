# =============================================================================
# Quickshell Notifications + Control Panel
# =============================================================================
# Replaces SwayNC behavior with a Quickshell notification daemon, popup stack,
# and control panel (toggleable via IPC from Hyprland keybinds).
# =============================================================================
{ config, ... }:
let
  c =
    (import ../../../lib/stylix/semantic-colors.nix { stylixColors = config.lib.stylix.colors; })
    .withHash;
in
{
  xdg.configFile."quickshell/shell.qml".text = ''
    import Quickshell
    import Quickshell.Io
    import Quickshell.Services.Notifications
    import QtQuick
    import QtQml

    ShellRoot {
      id: root

      property bool controlPanelVisible: false
      property bool doNotDisturb: false
      property int popupTimeoutMs: 5000
      property int maxPopups: 4
      property int nextPopupId: 1

      readonly property color bg: "${c.bg}"
      readonly property color bgRaised: "${c.bgRaised}"
      readonly property color bgSubtle: "${c.bgSubtle}"
      readonly property color border: "${c.border}"
      readonly property color fg: "${c.fg}"
      readonly property color fgMid: "${c.fgMid}"
      readonly property color fgDim: "${c.fgDim}"
      readonly property color accent: "${c.accent}"
      readonly property color red: "${c.red}"

      function removePopupById(popupId) {
        for (let i = 0; i < popupModel.count; i++) {
          const entry = popupModel.get(i);
          if (entry.popupId === popupId) {
            popupModel.remove(i, 1);
            return;
          }
        }
      }

      function clearNotifications() {
        const notifications = notificationServer.trackedNotifications.values;
        for (let i = notifications.length - 1; i >= 0; i--) {
          notifications[i].dismiss();
        }
      }

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
      }

      ListModel {
        id: popupModel
      }

      NotificationServer {
        id: notificationServer
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true
        bodyImagesSupported: true
        persistenceSupported: true

        onNotification: (notification) => {
          notification.tracked = true;

          if (root.doNotDisturb) return;

          const summary = notification.summary && notification.summary.length > 0
            ? notification.summary
            : (notification.appName && notification.appName.length > 0 ? notification.appName : "Notification");

          popupModel.append({
            "popupId": root.nextPopupId++,
            "appName": notification.appName && notification.appName.length > 0 ? notification.appName : "Notification",
            "summary": summary,
            "body": notification.body || "",
            "isCritical": notification.urgency === NotificationUrgency.Critical
          });

          if (popupModel.count > root.maxPopups) {
            popupModel.remove(0, popupModel.count - root.maxPopups);
          }
        }
      }

      PanelWindow {
        visible: popupModel.count > 0
        focusable: false
        aboveWindows: true

        anchors {
          top: true
          right: true
        }

        margins {
          top: 24
          right: 24
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
                required property int popupId
                required property string appName
                required property string summary
                required property string body
                required property bool isCritical

                width: popupColumn.width
                implicitHeight: popupContent.implicitHeight + 24
                height: implicitHeight
                radius: 8
                color: root.bgRaised
                border.width: 1
                border.color: isCritical ? root.red : root.border

                Column {
                  id: popupContent
                  x: 12
                  y: 12
                  width: parent.width - 24
                  spacing: 6

                  Row {
                    width: parent.width
                    spacing: 8

                    Text {
                      text: appName
                      color: root.accent
                      font.pixelSize: 11
                      font.bold: true
                      elide: Text.ElideRight
                      width: Math.max(0, parent.width - closePopup.width - parent.spacing)
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
                        font.pixelSize: 13
                        font.bold: true
                      }

                      MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: closePopup.color = root.bgSubtle
                        onExited: closePopup.color = "transparent"
                        onClicked: root.removePopupById(popupId)
                      }
                    }
                  }

                  Text {
                    text: summary
                    width: parent.width
                    color: root.fg
                    font.pixelSize: 13
                    font.bold: true
                    wrapMode: Text.Wrap
                    textFormat: Text.PlainText
                    visible: text.length > 0
                  }

                  Text {
                    text: body
                    width: parent.width
                    color: root.fgMid
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    textFormat: Text.PlainText
                    visible: text.length > 0
                  }
                }

                Timer {
                  interval: root.popupTimeoutMs
                  running: true
                  repeat: false
                  onTriggered: root.removePopupById(popupId)
                }
              }
            }
          }
        }
      }

      PanelWindow {
        visible: root.controlPanelVisible
        focusable: true
        aboveWindows: true

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
                text: "Control Panel"
                color: root.fg
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
                width: 180
                height: 30
                radius: 6
                color: root.doNotDisturb ? root.accent : root.bgSubtle
                border.width: 1
                border.color: root.doNotDisturb ? root.accent : root.border

                Text {
                  anchors.centerIn: parent
                  text: root.doNotDisturb ? "DND: ON" : "DND: OFF"
                  color: root.doNotDisturb ? root.bg : root.fg
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
                width: 120
                height: 30
                radius: 6
                color: "transparent"
                border.width: 1
                border.color: root.border

                Text {
                  anchors.centerIn: parent
                  text: "Clear All"
                  color: root.fgMid
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
                  x: 12
                  y: 12
                  width: parent.width - 24
                  spacing: 6

                  Row {
                    width: parent.width
                    spacing: 8

                    Text {
                      text: notification.appName && notification.appName.length > 0 ? notification.appName : "Notification"
                      color: root.accent
                      font.pixelSize: 11
                      font.bold: true
                      elide: Text.ElideRight
                      width: Math.max(0, parent.width - dismissButton.width - parent.spacing)
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
                    text: notification.summary || ""
                    width: parent.width
                    color: root.fg
                    font.pixelSize: 13
                    font.bold: true
                    wrapMode: Text.Wrap
                    textFormat: Text.PlainText
                    visible: text.length > 0
                  }

                  Text {
                    text: notification.body || ""
                    width: parent.width
                    color: root.fgMid
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
