pragma ComponentBehavior: Bound
import QtQuick
import ".."

// Shared surface card container used by CommandCentre sections, popovers,
// MediaCard, NotificationCard, and LockScreen.
Rectangle {
  id: root

  property color cardColour: Colours.bgRaised
  property color borderColour: Colours.border
  property real cardRadius: Config.commandCentreCardRadius

  color: root.cardColour
  radius: root.cardRadius
  border.width: Config.borderWidth
  border.color: root.borderColour
  antialiasing: true

  Behavior on color { ColorAnimation { duration: Config.animNormalMs } }
  Behavior on border.color { ColorAnimation { duration: Config.animNormalMs } }
}
