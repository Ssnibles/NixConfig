import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets

// Single notification card. Rendered by NotificationOverlay for each queued
// notification. Click the card to dismiss it.
Rectangle {
  id: root

  property var notification: null
  property string appName: ""
  property string desktopEntry: ""

  property string summary: ""
  property string body: ""
  property string appIcon: ""
  property string image: ""
  property int urgency: 1 // 0 = Low, 1 = Normal, 2 = Critical
  property string trackTitle: ""
  property string trackArtist: ""
  property bool isMedia: false
  signal dismissed()
  signal actionTriggered()

  // Retain the notification object while this card is shown.
  RetainableLock {
    object: root.notification
    locked: root.notification !== null
  }

  // Determine icon source and visibility
  property string iconSource: image !== "" ? image : appIcon
  property bool hasIcon: iconSource !== ""

  width: parent ? parent.width : Config.notifWidth
  height: Math.max(contentCol.implicitHeight, hasIcon ? (isMedia ? 48 : 40) : 0) + Config.notifCardMargins * 2
  radius: Config.notifRadius
  
  color: hoverArea.containsMouse ? Colors.bgRaised : Colors.bg
  border.color: hoverArea.containsMouse
    ? (isMedia ? Colors.teal : (urgency === 2 ? Colors.red : Colors.accent))
    : (urgency === 2 ? Colors.red : Colors.border)
  border.width: 1

  scale: hoverArea.containsMouse ? (hoverArea.pressed ? 0.98 : 1.02) : 1.0

  Behavior on color { ColorAnimation { duration: 150 } }
  Behavior on border.color { ColorAnimation { duration: 150 } }
  Behavior on scale { NumberAnimation { duration: 100 } }

  MouseArea {
    id: hoverArea
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      if (mouse.button === Qt.RightButton) {
        root.actionTriggered()
      } else {
        root.dismissed()
      }
    }
  }

  // Left-side Icon/Image Container
  Item {
    id: iconContainer
    visible: root.hasIcon
    anchors.left: parent.left
    anchors.leftMargin: Config.notifCardMargins
    anchors.verticalCenter: parent.verticalCenter
    width: root.isMedia ? 48 : 40
    height: root.isMedia ? 48 : 40

    // Mask for rounded corners
    Item {
      id: iconMask
      width: parent.width
      height: parent.height
      visible: false
      layer.enabled: true
      Rectangle {
        width: parent.width
        height: parent.height
        radius: 8
        color: "black"
      }
    }

    IconImage {
      anchors.fill: parent
      source: root.iconSource

      layer.enabled: true
      layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: iconMask
      }
    }
  }

  // Text Column
  Column {
    id: contentCol
    anchors.left: root.hasIcon ? iconContainer.right : parent.left
    anchors.leftMargin: root.hasIcon ? 10 : Config.notifCardMargins
    anchors.right: parent.right
    anchors.rightMargin: Config.notifCardMargins
    anchors.verticalCenter: parent.verticalCenter
    spacing: 2

    Text {
      width: parent.width
      text: root.isMedia ? "Now Playing" : root.summary
      color: root.isMedia ? Colors.teal : (root.urgency === 2 ? Colors.red : Colors.accent)
      font.bold: true
      font.pixelSize: root.isMedia ? 10 : 12
      font.family: Config.sansFont
      elide: Text.ElideRight
    }

    Text {
      width: parent.width
      text: root.isMedia ? root.trackTitle : root.body
      color: Colors.fg
      font.bold: root.isMedia
      font.pixelSize: 12
      font.family: Config.sansFont
      elide: root.isMedia ? Text.ElideRight : Text.ElideNone
      wrapMode: root.isMedia ? Text.NoWrap : Text.Wrap
      visible: text !== ""
    }

    Text {
      width: parent.width
      text: root.trackArtist
      color: Colors.fgMid
      font.pixelSize: 11
      font.family: Config.sansFont
      elide: Text.ElideRight
      visible: root.isMedia && text !== ""
    }
  }
}