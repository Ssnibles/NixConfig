import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "Utils.js" as Utils

Item {
  id: root

  property PanelWindow sharedWindow: null
  property string uiFont: Config.monoFont

  // Pipewire Audio Binding
  property var volNodes: Pipewire.ready && Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
  PwObjectTracker { objects: root.volNodes }

  property var volInfo: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
  property real volPct: root.volInfo ? root.volInfo.volume : 0
  property bool volMuted: root.volInfo ? root.volInfo.muted : false

  width: parent ? parent.width : 38
  height: volLayout.height + 8
  anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined

  Tooltip {
    id: volTooltip
    sharedWindow: root.sharedWindow
    icon: Utils.volumeIcon(root.volPct, root.volMuted)
    iconColor: root.volMuted ? Colors.red : Colors.accent
    title: {
      var pct = Math.round(root.volPct * 100)
      return root.volMuted ? "Muted" : ("Volume " + pct + "%")
    }
    details: ["Left click · Mute", "Right click · Mixer", "Scroll · Adjust"]
  }

  Rectangle {
    id: volBg
    anchors.fill: parent
    radius: 4
    color: volTooltip.hovered ? Colors.bgRaised : "transparent"
    Behavior on color { ColorAnimation { duration: 100 } }
  }

  MouseArea {
    id: volMouse
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function(mouse) {
      if (mouse.button === Qt.RightButton) {
        Quickshell.execDetached(["pavucontrol"])
      } else if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
        Pipewire.defaultAudioSink.audio.muted = !root.volMuted
      }
    }
    onWheel: function(wheel) {
      if (!Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio) return
      var step = 0.05
      var dir = wheel.angleDelta.y > 0 ? 1 : -1
      var newVol = Math.max(0, Math.min(1.5, root.volPct + dir * step))
      root.volPct = newVol
      Pipewire.defaultAudioSink.audio.volume = newVol
    }
  }

  Column {
    id: volLayout
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
        color: Colors.bgSubtle
        border.color: trackMouse.containsMouse ? (root.volMuted ? Colors.red : Colors.accent) : "transparent"
        border.width: 1

        Rectangle {
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.right: parent.right
          height: parent.height * Math.min(1.0, root.volPct)
          radius: 4
          color: root.volMuted ? Colors.red : Colors.accent
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
          var pct = Math.max(0, Math.min(1.5, (parent.height - mouseY) / parent.height))
          root.volPct = pct
          if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
            Pipewire.defaultAudioSink.audio.volume = pct
          }
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
      text: Utils.volumeIcon(root.volPct, root.volMuted)
      color: root.volMuted ? Colors.red : Colors.fg
      font.family: root.uiFont
      font.pixelSize: 15
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Math.round(root.volPct * 100) + "%"
      color: root.volMuted ? Colors.red : Colors.fgMid
      font.family: root.uiFont
      font.pixelSize: 11
    }
  }
}
