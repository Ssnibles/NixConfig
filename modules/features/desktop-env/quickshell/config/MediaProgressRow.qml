import QtQuick
import QtQuick.Layouts
import "Utils.js" as Utils

// Reusable elapsed-time + seekbar + total-time row.
// Used in CommandCenter, MediaWidget popover, and LockScreen.
RowLayout {
  id: root
  spacing: 8

  property real position: 0   // current position in seconds
  property real length: 0     // total length in seconds
  property real progress: 0   // 0..1 fraction (computed externally by MediaService)
  property bool seekable: true

  signal seekRequested(real progress)

  Text {
    text: Utils.formatTime(Math.round(root.position))
    color: Colors.fgDim
    font.family: Config.sansFont
    font.pixelSize: 12
    Layout.preferredWidth: 38
    horizontalAlignment: Text.AlignRight
  }

  SliderControl {
    Layout.fillWidth: true
    value: root.progress
    fillColor: Colors.accent
    enabled: root.seekable
    onMoved: function(v) { root.seekRequested(v) }
  }

  Text {
    text: Utils.formatTime(Math.round(root.length))
    color: Colors.fgDim
    font.family: Config.sansFont
    font.pixelSize: 12
    Layout.preferredWidth: 38
  }
}
