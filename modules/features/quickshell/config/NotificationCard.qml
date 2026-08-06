import QtQuick

// Single notification card. Rendered by NotificationOverlay for each queued
// notification. Click the card to dismiss it.
Rectangle {
  id: root

  property string summary: ""
  property string body: ""
  signal dismissed()

  width: parent ? parent.width : Config.notifWidth
  height: contentCol.implicitHeight + Config.notifCardMargins * 2
  radius: Config.notifRadius
  color: Colors.bgRaised
  border.color: Colors.border
  border.width: 1

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.dismissed()
  }

  Column {
    id: contentCol
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.margins: Config.notifCardMargins
    spacing: 2

    Text {
      width: parent.width
      text: root.summary
      color: Colors.fg
      font.bold: true
      font.pixelSize: 12
      font.family: Config.sansFont
      elide: Text.ElideRight
    }

    Text {
      width: parent.width
      text: root.body
      color: Colors.fgMid
      font.pixelSize: 11
      font.family: Config.sansFont
      elide: Text.ElideRight
      visible: text !== ""
    }
  }
}