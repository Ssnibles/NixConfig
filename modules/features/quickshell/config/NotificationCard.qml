import QtQuick
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
  
  color: hoverArea.containsMouse ? Colors.bgSubtle : Colors.bgRaised
  border.color: hoverArea.containsMouse
    ? (isMedia ? Colors.teal : (urgency === 2 ? Colors.red : Colors.accent))
    : (isMedia ? Colors.teal : (urgency === 2 ? Colors.red : Colors.border))
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

  // Left Urgency Indicator Accent Strip
  Rectangle {
    id: urgencyStrip
    anchors.left: parent.left
    anchors.leftMargin: 1
    anchors.top: parent.top
    anchors.topMargin: 1
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 1
    width: 4
    
    // Smooth corners on the left edge to match the card
    topLeftRadius: root.radius - 1
    bottomLeftRadius: root.radius - 1
    
    color: {
      if (root.isMedia) return Colors.teal
      if (root.urgency === 2) return Colors.red
      if (root.urgency === 0) return Colors.fgDim
      return Colors.accent
    }
  }

  // Left-side Icon/Image Container
  Item {
    id: iconContainer
    visible: root.hasIcon
    anchors.left: parent.left
    anchors.leftMargin: Config.notifCardMargins + 4 // Shift right to avoid urgency strip
    anchors.verticalCenter: parent.verticalCenter
    width: root.isMedia ? 48 : 40
    height: root.isMedia ? 48 : 40

    // Rounded clipping wrapper for the icon
    Rectangle {
      anchors.fill: parent
      radius: 6
      color: Colors.bgSubtle
      clip: true

      IconImage {
        anchors.fill: parent
        source: root.iconSource
      }
    }
  }

  // Text Column
  Column {
    id: contentCol
    anchors.left: root.hasIcon ? iconContainer.right : parent.left
    anchors.leftMargin: root.hasIcon ? 10 : (Config.notifCardMargins + 8) // Shift right to avoid urgency strip
    anchors.right: parent.right
    anchors.rightMargin: Config.notifCardMargins
    anchors.verticalCenter: parent.verticalCenter
    spacing: 2

    Text {
      width: parent.width
      text: root.isMedia ? "Now Playing" : root.summary
      color: root.isMedia ? Colors.teal : Colors.fg
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