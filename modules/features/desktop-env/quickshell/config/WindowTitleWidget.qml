pragma ComponentBehavior: Bound
import QtQuick

Item {
  id: root

  property string titleText: WmService.currentTitle
  property string uiFont: Config.monoFont
  property color textColour: Colours.fgMid
  property int fontSize: Config.fontSizeMd
  property real targetRotation: horizontal ? 0 : 270
  property bool horizontal: false
  property int maxText: horizontal ? Config.windowTitleMaxWidthHorizontal : Config.windowTitleMaxWidthVertical
  property bool italic: true
  property int horizontalPadding: Config.pillPaddingHorizontal + 2

  readonly property real textExtent: Math.min(titleLabel.implicitWidth, root.maxText)

  implicitWidth: horizontal ? (root.textExtent + root.horizontalPadding * 2) : 26
  implicitHeight: horizontal ? Config.pillHeightHorizontal : root.textExtent
  width: implicitWidth
  height: implicitHeight
  visible: titleText !== ""
  clip: true

  Behavior on width {
    enabled: root.horizontal
    NumberAnimation { duration: Config.animSmoothMs; easing.type: Easing.OutCubic }
  }

  // Horizontal pill background (used in top bar mode)
  Rectangle {
    visible: root.horizontal
    anchors.fill: parent
    radius: height / 2
    color: Colours.bgRaised
    border.width: 1
    border.color: Colours.border
    antialiasing: true
  }

  Text {
    id: titleLabel
    text: root.titleText
    color: root.textColour
    font.family: root.uiFont
    font.pixelSize: root.fontSize
    font.italic: root.italic
    elide: root.horizontal ? Text.ElideRight : Text.ElideNone
    verticalAlignment: Text.AlignVCenter

    anchors.centerIn: root.horizontal ? parent : undefined

    transform: [
      Rotation {
        angle: root.horizontal ? 0 : root.targetRotation
        origin.x: 0
        origin.y: 0
      },
      Translate {
        x: 0
        y: root.horizontal ? 0 : titleLabel.implicitWidth
      }
    ]

    width: root.horizontal ? root.textExtent : titleLabel.implicitWidth
    height: root.horizontal ? parent.height : 26
  }
}