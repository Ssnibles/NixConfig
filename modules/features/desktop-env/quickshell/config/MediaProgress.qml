import Quickshell
import QtQuick

// Wrapper providing backward-compatibility with MediaService
Item {
  id: root

  property bool enabled: true
  property var player: MediaService.player
  property int tickInterval: 300

  readonly property real lastPosition: MediaService.lastPosition
  readonly property real lastLength: MediaService.lastLength
  readonly property real estimatedPosition: MediaService.estimatedPosition
  readonly property real progress: MediaService.progress

  // Register as active consumer on MediaService while enabled
  onEnabledChanged: {
    if (enabled) {
      MediaService.activeConsumers++
    } else {
      MediaService.activeConsumers = Math.max(0, MediaService.activeConsumers - 1)
    }
  }

  Component.onCompleted: {
    if (enabled) MediaService.activeConsumers++
  }

  Component.onDestruction: {
    if (enabled) MediaService.activeConsumers = Math.max(0, MediaService.activeConsumers - 1)
  }
}