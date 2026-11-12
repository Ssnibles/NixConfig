pragma ComponentBehavior: Bound
import QtQuick
import ".."

// Thin horizontal rule used to separate sections.
Rectangle {
  implicitHeight: Config.borderWidth
  height: Config.borderWidth
  color: Colours.border
}
