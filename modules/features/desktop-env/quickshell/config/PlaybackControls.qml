import QtQuick
import QtQuick.Layouts

// Reusable prev / play-pause / next button cluster with hover scaling.
// Used in CommandCenter media card and MediaWidget popover.
RowLayout {
  id: root
  spacing: 6

  property bool canPrevious: false
  property bool canNext: false
  property bool isPlaying: false
  property string uiFont: Config.monoFont

  signal previousClicked()
  signal playPauseClicked()
  signal nextClicked()

  // Previous button
  Rectangle {
    Layout.preferredWidth: 28
    Layout.preferredHeight: 28
    Layout.alignment: Qt.AlignVCenter
    radius: 14
    color: prevHover.containsMouse ? Colors.bgSubtle : "transparent"
    Behavior on scale { NumberAnimation { duration: 100 } }

    Text {
      text: "󰒮"
      color: root.canPrevious ? (prevHover.containsMouse ? Colors.accent : Colors.fg) : Colors.fgDim
      font.family: root.uiFont
      font.pixelSize: 16
      anchors.centerIn: parent
    }

    MouseArea {
      id: prevHover
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: root.canPrevious ? Qt.PointingHandCursor : Qt.ArrowCursor
      onEntered: parent.scale = 0.90
      onExited: parent.scale = 1.0
      onClicked: { if (root.canPrevious) root.previousClicked() }
    }
  }

  // Play / Pause button
  Rectangle {
    Layout.preferredWidth: 32
    Layout.preferredHeight: 32
    Layout.alignment: Qt.AlignVCenter
    radius: 16
    color: playHover.containsMouse ? Colors.accent : Colors.bgSubtle
    border.color: Colors.border
    border.width: 1
    Behavior on scale { NumberAnimation { duration: 100 } }

    Text {
      text: root.isPlaying ? "󰏤" : "󰐊"
      color: playHover.containsMouse ? Colors.bg : Colors.fg
      font.family: root.uiFont
      font.pixelSize: 18
      anchors.centerIn: parent
    }

    MouseArea {
      id: playHover
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: parent.scale = 0.90
      onExited: parent.scale = 1.0
      onClicked: root.playPauseClicked()
    }
  }

  // Next button
  Rectangle {
    Layout.preferredWidth: 28
    Layout.preferredHeight: 28
    Layout.alignment: Qt.AlignVCenter
    radius: 14
    color: nextHover.containsMouse ? Colors.bgSubtle : "transparent"
    Behavior on scale { NumberAnimation { duration: 100 } }

    Text {
      text: "󰒭"
      color: root.canNext ? (nextHover.containsMouse ? Colors.accent : Colors.fg) : Colors.fgDim
      font.family: root.uiFont
      font.pixelSize: 16
      anchors.centerIn: parent
    }

    MouseArea {
      id: nextHover
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: root.canNext ? Qt.PointingHandCursor : Qt.ArrowCursor
      onEntered: parent.scale = 0.90
      onExited: parent.scale = 1.0
      onClicked: { if (root.canNext) root.nextClicked() }
    }
  }
}
