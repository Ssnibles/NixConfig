pragma ComponentBehavior: Bound
import QtQuick
import ".."

// Hover trigger for the shared tooltip layer. Nest one inside a widget and pass
// its `sharedWindow`; override `contentComponent` to render a custom card.
Item {
  id: root

  property Item target: parent
  property string icon: ""
  property string title: ""
  property var details: []
  property color iconColour: Colours.fg
  property int showDelay: Config.popupShowDelay
  property int maxWidth: Config.popupMaxWidth
  property int contentWidth: 0
  property Component contentComponent: null
  property var sharedWindow: null

  readonly property bool hovered: _hoverHandler.hovered
  readonly property bool tipVisible: root.hovered && root._ready

  property bool _ready: false

  anchors.fill: parent

  HoverHandler { id: _hoverHandler }

  Timer {
    id: _delayTimer
    interval: root.showDelay
    onTriggered: root._ready = true
  }

  onHoveredChanged: {
    // Without a window to render into there is nothing to show.
    if (root.hovered && root.sharedWindow) {
      // Swapping between adjacent widgets skips the delay.
      if (root.sharedWindow.recentlyActive) {
        root._ready = true
      } else {
        _delayTimer.restart()
      }
    } else {
      _delayTimer.stop()
      root._ready = false
    }
  }

  onTipVisibleChanged: {
    if (!root.sharedWindow) return
    if (root.tipVisible) {
      root.sharedWindow.activeTip = root
    } else if (root.sharedWindow.activeTip === root) {
      root.sharedWindow.activeTip = null
    }
  }

  Component.onDestruction: {
    if (root.sharedWindow && root.sharedWindow.activeTip === root) {
      root.sharedWindow.activeTip = null
    }
  }

  function openNow() {
    _delayTimer.stop()
    root._ready = true
    if (root.sharedWindow) {
      root.sharedWindow.openNow(root)
    }
  }

  function closeNow() {
    _delayTimer.stop()
    root._ready = false
    if (root.sharedWindow) {
      root.sharedWindow.closeNow()
    }
  }
}
