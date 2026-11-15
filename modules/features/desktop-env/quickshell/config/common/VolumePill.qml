pragma ComponentBehavior: Bound
import QtQuick
import ".."

// Volume badge shared by the bar and the lock screen status cluster. Mute is
// signalled by the red border, icon and label, so the percentage stays
// readable in both states.
StatusPill {
  id: root

  // Vertical bars show a level track in place of the single-row badge.
  showContent: root.horizontal
  padding: root.horizontal ? Config.pillPaddingHorizontal : Config.spaceXs

  readonly property color levelColour: AudioService.muted ? Colours.red : Colours.accent

  acceptedButtons: Qt.LeftButton | Qt.RightButton
  border.color: AudioService.muted ? Colours.red : Colours.border
  icon: AudioService.volumeIcon
  iconColour: root.levelColour
  iconSize: root.horizontal ? Config.iconSizeSm : Config.iconSizeLg
  label: AudioService.volumePercent + "%"
  labelColour: AudioService.muted ? Colours.red : Colours.fg
  labelBold: true
  tooltipEnabled: root.interactive
  tooltipTitle: AudioService.muted ? "Muted" : ("Volume " + AudioService.volumePercent + "%")
  tooltipDetails: root.interactive ? ["Left click · Mute", "Right click · Mixer", "Scroll · Adjust"] : []

  onClicked: function(mouse) {
    if (mouse.button === Qt.RightButton) AudioService.openMixer()
    else AudioService.toggleMute()
  }

  onWheel: function(wheel) {
    AudioService.stepVolume(wheel.angleDelta.y)
    wheel.accepted = true
  }

  // Side bar: level track above the icon and percentage.
  Column {
    visible: !root.horizontal
    anchors.centerIn: parent
    spacing: Config.spaceSm

    Item {
      width: Config.spaceMd + Config.space2xs
      height: Config.volBarHeight
      anchors.horizontalCenter: parent.horizontalCenter

      Rectangle {
        anchors.fill: parent
        radius: Config.itemRadiusXs
        color: Colours.bgSubtle
        border.width: Config.borderWidth
        border.color: trackMouse.containsMouse ? root.levelColour : "transparent"

        Rectangle {
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.right: parent.right
          height: parent.height * Math.min(1.0, AudioService.volume)
          radius: Config.itemRadiusXs
          color: root.levelColour
          Behavior on height { NumberAnimation { duration: Config.animSmoothMs; easing.type: Easing.OutQuad } }
          Behavior on color { ColorAnimation { duration: Config.animSmoothMs } }
        }
      }

      MouseArea {
        id: trackMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function updateVolume(mouseY) {
          AudioService.setVolume((parent.height - mouseY) / parent.height)
        }

        onPressed: function(mouse) { updateVolume(mouse.y) }
        onPositionChanged: function(mouse) {
          if (pressed) updateVolume(mouse.y)
        }
        onWheel: function(wheel) {
          AudioService.stepVolume(wheel.angleDelta.y)
          wheel.accepted = true
        }
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: AudioService.volumeIcon
      color: AudioService.muted ? Colours.red : Colours.fg
      font.family: Session.monoFont
      font.pixelSize: Config.fontSizeLg
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: AudioService.volumePercent + "%"
      color: AudioService.muted ? Colours.red : Colours.fgMid
      font.family: Session.monoFont
      font.pixelSize: Config.fontSizeXs
    }
  }
}
