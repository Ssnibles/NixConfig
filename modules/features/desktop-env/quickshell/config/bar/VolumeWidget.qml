pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import ".."

Pill {
  id: root

  property PanelWindow sharedWindow: null
  property string uiFont: Config.monoFont

  // Mute is signalled by colour, so the numeric level stays readable.
  readonly property color levelColour: AudioService.muted ? Colours.red : Colours.accent

  hoverHighlight: true
  clickable: true
  acceptedButtons: Qt.LeftButton | Qt.RightButton
  padding: root.horizontal ? Config.pillPaddingHorizontal : 4

  onClicked: function(mouse) {
    if (mouse.button === Qt.RightButton) {
      AudioService.openMixer()
    } else {
      AudioService.toggleMute()
    }
  }

  onWheel: function(wheel) {
    AudioService.stepVolume(wheel.angleDelta.y)
    wheel.accepted = true
  }

  Tooltip {
    target: root
    sharedWindow: root.sharedWindow
    icon: AudioService.volumeIcon
    iconColour: root.levelColour
    title: AudioService.muted ? "Muted" : ("Volume " + AudioService.volumePercent + "%")
    details: ["Left click · Mute", "Right click · Mixer", "Scroll · Adjust"]
  }

  // Side bar: vertical level track above the icon and percentage.
  Column {
    visible: !root.horizontal
    anchors.centerIn: parent
    spacing: 4

    Item {
      width: 12
      height: Config.volBarHeight
      anchors.horizontalCenter: parent.horizontalCenter

      Rectangle {
        anchors.fill: parent
        radius: 4
        color: Colours.bgSubtle
        border.width: 1
        border.color: trackMouse.containsMouse ? root.levelColour : "transparent"

        Rectangle {
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.right: parent.right
          height: parent.height * Math.min(1.0, AudioService.volume)
          radius: 4
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
      font.family: root.uiFont
      font.pixelSize: 15
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: AudioService.volumePercent + "%"
      color: AudioService.muted ? Colours.red : Colours.fgMid
      font.family: root.uiFont
      font.pixelSize: 11
    }
  }

  // Top bar: icon beside the percentage.
  Row {
    visible: root.horizontal
    anchors.centerIn: parent
    spacing: 6

    Text {
      text: AudioService.volumeIcon
      color: root.levelColour
      font.family: root.uiFont
      font.pixelSize: 14
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      // The bar pill hugs its content rather than reserving a label column.
      text: AudioService.volumePercent + "%"
      color: AudioService.muted ? Colours.red : Colours.fg
      font.family: root.uiFont
      font.pixelSize: 12
      font.bold: true
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}
