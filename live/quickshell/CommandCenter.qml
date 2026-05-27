import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import QtQml

PanelWindow {
  id: controlPanel

  property QtObject root: null

  // -- Volume control --
  property var volNodes: Pipewire.ready && Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
  PwObjectTracker { objects: controlPanel.volNodes }
  property var volInfo: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
  property real volPct: volInfo ? volInfo.volume : 0
  property bool volMuted: volInfo ? volInfo.muted : false

  visible: false
  focusable: true
  aboveWindows: true
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  anchors { top: true; right: true }
  margins { top: root ? root.topMargin : 54; right: root ? root.sideMargin : 24 }

  implicitWidth: root ? root.panelWidth : 520
  implicitHeight: 640

  component AppIcon: Item {
    property var notification: null
    property color fallbackBg: root ? root.bgSubtle : "#333333"

    width: root ? root.iconSize : 24
    height: root ? root.iconSize : 24

    Image {
      id: iconImg
      anchors.fill: parent
      source: root ? root.appIconSource(notification) : ""
      sourceSize.width: root ? root.iconSize : 24
      sourceSize.height: root ? root.iconSize : 24
      fillMode: Image.PreserveAspectFit
      visible: status === Image.Ready
    }

    Rectangle {
      anchors.fill: parent
      radius: 4
      color: fallbackBg
      border.width: 1
      border.color: root ? root.border : "#555555"
      visible: !iconImg.visible

      Text {
        anchors.centerIn: parent
        text: (notification && notification.appName && notification.appName.length > 0)
          ? notification.appName[0].toUpperCase()
          : "N"
        color: root ? root.teal : "#00bcd4"
        font.family: root ? root.uiFont : "monospace"
        font.pixelSize: 11
        font.bold: true
      }
    }
  }

  component ActionRow: Row {
    property var actions: []
    signal actionInvoked()

    spacing: root ? root.cardSpacing : 6
    visible: actions && actions.length > 0

    Repeater {
      model: actions

      Rectangle {
        required property QtObject modelData

        height: root ? root.actionBtnHeight : 26
        radius: 6
        color: "transparent"
        border.width: 1
        border.color: root ? root.border : "#555555"
        width: btnLabel.implicitWidth + 20

        Text {
          id: btnLabel
          anchors.centerIn: parent
          text: modelData.text
          color: root ? root.fgMid : "#aaaaaa"
          font.family: root ? root.uiFont : "monospace"
          font.pixelSize: 11
          textFormat: Text.PlainText
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          onEntered: parent.color = root ? root.bgSubtle : "#333333"
          onExited:  parent.color = "transparent"
          onClicked: {
            modelData.invoke();
            actionInvoked();
          }
        }
      }
    }
  }

  Rectangle {
    anchors.fill: parent
    radius: root ? root.cardRadius : 8
    color: root ? root.bgRaised : "#1e1e2e"
    border.width: 1
    border.color: root ? root.border : "#555555"

    Column {
      anchors.fill: parent
      anchors.margins: root ? root.cardPadding : 14
      spacing: 12

      Row {
        width: parent.width
        spacing: 8

        Text {
          text: "Notifications"
          color: root ? root.fg : "#ffffff"
          font.family: root ? root.uiFont : "monospace"
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
          border.color: root ? root.border : "#555555"

          Text {
            anchors.centerIn: parent
            text: "\u00d7"
            color: root ? root.fgDim : "#777777"
            font.family: root ? root.uiFont : "monospace"
            font.pixelSize: 14
            font.bold: true
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: closePanel.color = root ? root.bgSubtle : "#333333"
            onExited:  closePanel.color = "transparent"
            onClicked: controlPanel.visible = false
          }
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: root ? root.border : "#555555"
      }

      Text {
        text: "System"
        color: root ? root.fg : "#ffffff"
        font.family: root ? root.uiFont : "monospace"
        font.pixelSize: 12
        font.bold: true
      }

      Item {
        width: parent.width
        height: 36

        Row {
          anchors.verticalCenter: parent.verticalCenter
          spacing: 10

          Rectangle {
            id: volIconBtn
            width: 36
            height: 36
            radius: 6
            color: controlPanel.volMuted ? (root ? root.red : "#ef4444") : (root ? root.bgSubtle : "#2a2a3e")
            border.width: 1
            border.color: controlPanel.volMuted ? (root ? root.red : "#ef4444") : (root ? root.border : "#555555")

            Text {
              anchors.centerIn: parent
              text: {
                if (controlPanel.volMuted) return "󰝟"
                var v = controlPanel.volPct
                if (v <= 0) return "󰝟"
                if (v < 0.33) return "󰕿"
                if (v < 0.66) return "󰖀"
                return "󰕾"
              }
              color: controlPanel.volMuted ? (root ? root.bg : "#141415") : (root ? root.fg : "#ffffff")
              font.family: root ? root.uiFont : "monospace"
              font.pixelSize: 16
            }

            MouseArea {
              anchors.fill: parent
              onClicked: {
                if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                  Pipewire.defaultAudioSink.audio.muted = !controlPanel.volMuted
                }
              }
            }
          }

          Item {
            width: parent.parent.width - volIconBtn.width - volLabel.width - 20
            height: 36
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width
              height: 8
              radius: 4
              color: root ? root.bgSubtle : "#2a2a3e"

              Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: parent.width * controlPanel.volPct
                radius: 4
                color: controlPanel.volMuted ? (root ? root.red : "#ef4444") : (root ? root.accent : "#7c3aed")

                Behavior on width {
                  NumberAnimation { duration: 100; easing.type: Easing.InOutQuad }
                }
                Behavior on color {
                  ColorAnimation { duration: 100 }
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                property bool dragging: false

                onPressed: function(mouse) {
                  dragging = true
                  if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                    var pct = Math.max(0, Math.min(1, mouse.x / width))
                    Pipewire.defaultAudioSink.audio.volume = pct
                  }
                }

                onReleased: dragging = false
                onExited: dragging = false
                onPositionChanged: function(mouse) {
                  if (dragging && Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                    var pct = Math.max(0, Math.min(1, mouse.x / width))
                    Pipewire.defaultAudioSink.audio.volume = pct
                  }
                }
              }
            }
          }

          Text {
            id: volLabel
            text: Math.round(controlPanel.volPct * 100) + "%"
            color: controlPanel.volMuted ? (root ? root.red : "#ef4444") : (root ? root.fg : "#ffffff")
            font.family: root ? root.uiFont : "monospace"
            font.pixelSize: 12
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            height: 36
          }
        }
      }

      Text {
        width: parent.width
        text: controlPanel.volPct <= 0
          ? "Volume is at zero"
          : "Click or drag to adjust volume"
        color: root ? root.fgDim : "#777777"
        font.family: root ? root.uiFont : "monospace"
        font.pixelSize: 11
        wrapMode: Text.Wrap
      }

      Rectangle {
        width: parent.width
        height: 1
        color: root ? root.border : "#555555"
      }

      Row {
        width: parent.width
        spacing: 8

        Rectangle {
          id: dndToggle
          height: 30
          width: (parent.width - parent.spacing) / 2
          radius: 6
          color: (root && root.doNotDisturb) ? root.accent : (root ? root.bgSubtle : "#2a2a3e")
          border.width: 1
          border.color: (root && root.doNotDisturb) ? root.accent : (root ? root.border : "#555555")

          Text {
            anchors.centerIn: parent
            text: (root && root.doNotDisturb) ? "DND: ON" : "DND: OFF"
            color: (root && root.doNotDisturb) ? root.bg : (root ? root.fg : "#ffffff")
            font.family: root ? root.uiFont : "monospace"
            font.pixelSize: 11
            font.bold: true
          }

          MouseArea {
            anchors.fill: parent
            onClicked: { if (root) root.doNotDisturb = !root.doNotDisturb; }
          }
        }

        Rectangle {
          id: clearAll
          height: 30
          width: (parent.width - parent.spacing) / 2
          radius: 6
          color: "transparent"
          border.width: 1
          border.color: root ? root.border : "#555555"

          Text {
            anchors.centerIn: parent
            text: root
              ? "Clear All (" + root.notificationServer.trackedNotifications.values.length + ")"
              : "Clear All (0)"
            color: root ? root.fgMid : "#aaaaaa"
            font.family: root ? root.uiFont : "monospace"
            font.pixelSize: 11
            font.bold: true
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: clearAll.color = root ? root.bgSubtle : "#333333"
            onExited:  clearAll.color = "transparent"
            onClicked: { if (root) root.clearNotifications(); }
          }
        }
      }

      Text {
        width: parent.width
        text: (root && root.doNotDisturb)
          ? "Do Not Disturb is enabled. Critical alerts still appear."
          : "Popup timeout adapts to notification urgency and app hints."
        color: root ? root.fgDim : "#777777"
        font.family: root ? root.uiFont : "monospace"
        font.pixelSize: 11
        wrapMode: Text.Wrap
      }

      Rectangle {
        width: parent.width
        height: 1
        color: root ? root.border : "#555555"
      }

      ListView {
        id: notificationList
        width: parent.width
        height: parent.height - 120
        spacing: 8
        clip: true
        model: root ? root.notificationServer.trackedNotifications : null

        delegate: Rectangle {
          required property QtObject modelData
          property QtObject notification: modelData

          width: notificationList.width
          implicitHeight: panelCardContent.implicitHeight + (root ? root.cardPadding : 14) * 2
          height: implicitHeight
          radius: root ? root.cardRadius : 8
          color: root ? root.bgSubtle : "#2a2a3e"
          border.width: 1
          border.color: notification && notification.urgency === NotificationUrgency.Critical
            ? (root ? root.red : "#ef4444")
            : (root ? root.border : "#555555")

          Column {
            id: panelCardContent
            x: root ? root.cardPadding : 14
            y: root ? root.cardPadding : 14
            width: parent.width - (root ? root.cardPadding : 14) * 2
            spacing: root ? root.cardSpacing : 6

            Row {
              width: parent.width
              spacing: 8

              AppIcon { notification: modelData; fallbackBg: root ? root.bgRaised : "#1e1e2e" }

              Text {
                text: (notification && notification.appName && notification.appName.length > 0)
                  ? notification.appName
                  : "Notification"
                color: root ? root.accent : "#7c3aed"
                font.family: root ? root.uiFont : "monospace"
                font.pixelSize: 11
                font.bold: true
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                height: root ? root.iconSize : 24
                width: Math.max(0, parent.width - dismissBtn.width - parent.spacing - (root ? root.iconSize : 24) - parent.spacing)
              }

              Rectangle {
                id: dismissBtn
                width: root ? root.closeBtnSize : 22
                height: root ? root.closeBtnSize : 22
                radius: 4
                color: "transparent"
                border.width: 1
                border.color: root ? root.border : "#555555"

                Text {
                  anchors.centerIn: parent
                  text: "\u00d7"
                  color: root ? root.fgDim : "#777777"
                  font.family: root ? root.uiFont : "monospace"
                  font.pixelSize: 13
                  font.bold: true
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  onEntered: dismissBtn.color = root ? root.bgRaised : "#1e1e2e"
                  onExited:  dismissBtn.color = "transparent"
                  onClicked: notification.dismiss()
                }
              }
            }

            Text {
              text: notification ? (root ? root.stripMarkup(notification.summary || "") : notification.summary || "") : ""
              width: parent.width
              color: root ? root.fg : "#ffffff"
              font.family: root ? root.uiFont : "monospace"
              font.pixelSize: 13
              font.bold: true
              wrapMode: Text.Wrap
              textFormat: Text.PlainText
              visible: text.length > 0
            }

            Text {
              text: notification ? (root ? root.stripMarkup(notification.body || "") : notification.body || "") : ""
              width: parent.width
              color: root ? root.fgMid : "#aaaaaa"
              font.family: root ? root.uiFont : "monospace"
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
            color: root ? root.fgDim : "#777777"
            font.family: root ? root.uiFont : "monospace"
            font.pixelSize: 12
          }
        }
      }
    }
  }
}
