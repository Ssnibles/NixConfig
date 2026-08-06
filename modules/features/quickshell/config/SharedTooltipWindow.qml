import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: root

  property var screenTarget: null
  screen: screenTarget

  property var _active: null
  property bool recentlyActive: false
  property var cachedActive: null
  property real cardOpacity: 0

  on_ActiveChanged: {
    if (_active !== null) {
      cachedActive = _active
      recentlyActive = true
      recentTimer.stop()
      fadeTimer.stop()
      cardOpacity = 1
    } else {
      recentTimer.restart()
      fadeTimer.restart()
      cardOpacity = 0
    }
  }

  Timer {
    id: recentTimer
    interval: 500
    onTriggered: root.recentlyActive = false
  }

  Timer {
    id: fadeTimer
    interval: 120
    onTriggered: {
      root.cachedActive = null
    }
  }

  Behavior on cardOpacity { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

  visible: cachedActive !== null
  focusable: false
  aboveWindows: true
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  anchors { top: true; bottom: true; left: true }
  margins { left: 46 }
  implicitWidth: cachedActive ? cachedActive.maxWidth : 280

  mask: Region {
    item: tipLoader
  }

  Loader {
    id: tipLoader
    active: root.visible

    property var _src: root.cachedActive
    property real _tgtCenterY: _src && _src.target ? _src.target.mapToItem(null, 0, _src.target.height / 2).y : 0

    x: 0
    y: _src ? Math.round(Math.max(6, Math.min(_tgtCenterY - height / 2, root.height - height - 6))) : 0
    width: item ? item.width : 0
    height: item ? item.height : 0

    sourceComponent: Component {
      Rectangle {
        id: card
        property var _src: tipLoader._src

        x: 0
        y: 0
        width: _src ? _src.maxWidth : 280
        implicitHeight: content.implicitHeight + 24
        height: implicitHeight
        radius: 8
        color: Colors.bgRaised
        antialiasing: true
        border.width: 1
        border.color: Colors.border
        opacity: root.cardOpacity

        Column {
          id: content
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: 12
          spacing: 6

          Row {
            spacing: 8
            Text {
              text: _src ? _src.icon : ""
              color: _src ? _src.iconColor : Colors.fg
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 16
              anchors.verticalCenter: parent.verticalCenter
            }
            Text {
              text: _src ? _src.title : ""
              color: Colors.fg
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 12
              font.bold: true
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          Rectangle {
            visible: _src ? _src.details.length > 0 : false
            width: parent.width
            height: 1
            color: Colors.border
          }

          Repeater {
            model: _src ? _src.details : []
            delegate: Text {
              required property var modelData
              text: modelData
              color: Colors.fgMid
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 11
            }
          }
        }
      }
    }
  }
}
