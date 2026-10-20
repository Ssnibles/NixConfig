pragma ComponentBehavior: Bound
import QtQuick

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
  // Lets a caller widen the hover area beyond the tooltip's own item (e.g. a
  // whole control row) without moving the tooltip off its anchor.
  property bool extraHover: false

  readonly property bool hovered: _hoverHandler.hovered || root.extraHover
  readonly property bool tipVisible: root.hovered && _ready

  anchors.fill: parent

  HoverHandler { id: _hoverHandler }

  onHoveredChanged: {
    // Without a window to render into there is nothing to show.
    if (root.hovered && root.sharedWindow) {
      if (root.sharedWindow.recentlyActive) {
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

  property bool _ready: false

  Timer {
    id: _delayTimer
    interval: root.showDelay
    onTriggered: root._ready = true
  }
}
