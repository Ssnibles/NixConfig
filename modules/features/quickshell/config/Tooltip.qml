import QtQuick
import QtQml
import Quickshell

Item {
  id: root

  property Item target: parent
  property string icon: ""
  property string title: ""
  property var details: []
  property color iconColor: Colors.fg
  property int showDelay: 150
  property int maxWidth: 280
  property real topOffset: 0
  property PanelWindow sharedWindow: null

  readonly property bool hovered: _hoverHandler.hovered
  readonly property bool tipVisible: _hoverHandler.hovered && _ready

  anchors.fill: parent

  HoverHandler { id: _hoverHandler }

  onHoveredChanged: {
    if (hovered) {
      if (sharedWindow && sharedWindow.recentlyActive) {
        _ready = true
      } else {
        _delayTimer.restart()
      }
    } else {
      _delayTimer.stop()
      _ready = false
    }
  }

  onTipVisibleChanged: {
    if (!sharedWindow) return
    if (tipVisible) {
      sharedWindow._active = root
    } else if (sharedWindow._active === root) {
      sharedWindow._active = null
    }
  }

  property bool _ready: false

  Timer {
    id: _delayTimer
    interval: root.showDelay
    onTriggered: root._ready = true
  }
}
