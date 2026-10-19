pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

Item {
  id: root

  property PanelWindow sharedWindow: null
  property string uiFont: Config.monoFont
  property bool horizontal: false

  readonly property real volPct: SystemService.volume
  readonly property bool volMuted: SystemService.muted
  readonly property string volIcon: SystemService.volumeIcon
  readonly property int volPercent: SystemService.volumePercent

  implicitWidth: root.horizontal ? horizontalRow.implicitWidth + 16 : 34
  implicitHeight: root.horizontal ? Config.pillHeightHorizontal : (volLayout.implicitHeight > 0 ? volLayout.implicitHeight + 8 : 38)
  width: implicitWidth
  height: implicitHeight

  Tooltip {
    id: volTooltip
    sharedWindow: root.sharedWindow
    icon: root.volIcon
    iconColour: root.volMuted ? Colours.red : Colours.accent
    title: root.volMuted ? "Muted" : ("Volume " + root.volPercent + "%")
    details: ["Left click · Mute", "Right click · Mixer", "Scroll · Adjust"]
  }

  Rectangle {
    id: volBg
    anchors.fill: parent
    radius: Config.itemRadiusSm
    color: volTooltip.hovered ? Colours.bgSubtle : "transparent"
    Behavior on color { ColorAnimation { duration: Config.animNormalMs } }
  }

  MouseArea {
    id: volMouse
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function(mouse) {
      if (mouse.button === Qt.RightButton) {
        SystemService.openMixer()
      } else {
        SystemService.toggleMute()
      }
    }
    onWheel: function(wheel) {
      SystemService.stepVolume(wheel.angleDelta.y)
      wheel.accepted = true
    }
  }

  // Vertical layout for sidebar
  Column {
    id: volLayout
    visible: !root.horizontal
    anchors.top: parent.top
    anchors.topMargin: 4
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 4

    Item {
      id: volTrackContainer
      width: 12
      height: Config.volBarHeight
      anchors.horizontalCenter: parent.horizontalCenter

      Rectangle {
        anchors.fill: parent
        radius: 4
        color: Colours.bgSubtle
        border.color: trackMouse.containsMouse ? (root.volMuted ? Colours.red : Colours.accent) : "transparent"
        border.width: 1

        Rectangle {
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.right: parent.right
          height: parent.height * Math.min(1.0, root.volPct)
          radius: 4
          color: root.volMuted ? Colours.red : Colours.accent
          Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
          Behavior on color { ColorAnimation { duration: 150 } }
        }
      }

      MouseArea {
        id: trackMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function updateVolume(mouseY) {
          SystemService.setVolume((parent.height - mouseY) / parent.height)
        }

        onPressed: function(mouse) {
          updateVolume(mouse.y)
        }
        onPositionChanged: function(mouse) {
          if (pressed) {
            updateVolume(mouse.y)
          }
        }
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.volIcon
      color: root.volMuted ? Colours.red : Colours.fg
      font.family: root.uiFont
      font.pixelSize: 15
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.volPercent + "%"
      color: root.volMuted ? Colours.red : Colours.fgMid
      font.family: root.uiFont
      font.pixelSize: 11
    }
  }

  // Horizontal layout for topbar
  Row {
    id: horizontalRow
    visible: root.horizontal
    anchors.centerIn: parent
    spacing: 6

    Text {
      text: root.volIcon
      color: root.volMuted ? Colours.red : Colours.accent
      font.family: root.uiFont
      font.pixelSize: 14
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: root.volMuted ? "Muted" : root.volPercent + "%"
      color: root.volMuted ? Colours.red : Colours.fg
      font.family: root.uiFont
      font.pixelSize: 12
      font.bold: true
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}
