pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import ".."

// Reusable rounded-corner image with async loading and mask clipping.
// Shows nothing when source is empty or loading; parent can use `ready`
// to show a fallback icon.
Item {
  id: root

  property alias source: img.source
  property alias sourceSize: img.sourceSize
  property real radius: Config.itemRadiusMd
  readonly property bool ready: img.source !== "" && img.status === Image.Ready

  // Emitted when the image fails to load, so callers can advance to a fallback
  // candidate or reveal a placeholder.
  signal sourceError()

  Item {
    id: maskItem
    anchors.fill: parent
    visible: false
    layer.enabled: img.visible && root.radius > 0
    layer.smooth: true
    Rectangle {
      anchors.fill: parent
      radius: root.radius
      color: "black"
      antialiasing: true
    }
  }

  Image {
    id: img
    anchors.fill: parent
    asynchronous: true
    cache: false
    fillMode: Image.PreserveAspectCrop
    visible: root.ready
    onStatusChanged: if (status === Image.Error) root.sourceError()
    layer.enabled: visible && root.radius > 0
    layer.smooth: true
    layer.effect: MultiEffect {
      maskEnabled: true
      maskSource: maskItem
      // The default thresholds squash the mask's antialiased edge to a hard
      // step, which leaves staircased corners. These values keep the full
      // alpha ramp, so the rounded edge stays smooth.
      maskThresholdMin: 0.5
      maskSpreadAtMin: 1.0
      maskThresholdMax: 1.0
      maskSpreadAtMax: 0.0
    }
  }
}
