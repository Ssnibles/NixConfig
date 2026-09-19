import QtQuick
import QtQuick.Effects

// Reusable rounded-corner image with async loading and mask clipping.
// Shows nothing when source is empty or loading; parent can use `ready`
// to show a fallback icon.
Item {
  id: root

  property alias source: img.source
  property alias sourceSize: img.sourceSize
  property alias fillMode: img.fillMode
  property real radius: 8
  readonly property bool ready: img.source !== "" && img.status === Image.Ready

  Item {
    id: maskItem
    anchors.fill: parent
    visible: false
    layer.enabled: img.visible
    Rectangle {
      anchors.fill: parent
      radius: root.radius
      color: "black"
    }
  }

  Image {
    id: img
    anchors.fill: parent
    asynchronous: true
    fillMode: Image.PreserveAspectCrop
    visible: root.ready
    layer.enabled: visible
    layer.effect: MultiEffect {
      maskEnabled: true
      maskSource: maskItem
    }
  }
}
