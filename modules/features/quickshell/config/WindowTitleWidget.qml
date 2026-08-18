import QtQuick

Item {
  id: root

  property string titleText: ""
  property string uiFont: Config.monoFont
  property color textColor: Colors.fgMid
  property int fontSize: 13
  property real rotation: horizontal ? 0 : 270
  property bool horizontal: false
  property int maxText: horizontal ? 350 : 120
  property bool italic: true

  implicitWidth: horizontal ? Math.min(titleLabel.implicitWidth, root.maxText) : 26
  implicitHeight: horizontal ? 24 : Math.min(titleLabel.implicitWidth, root.maxText)
  width: implicitWidth
  height: implicitHeight
  anchors.verticalCenter: horizontal ? (parent ? parent.verticalCenter : undefined) : undefined
  anchors.horizontalCenter: horizontal ? undefined : (parent ? parent.horizontalCenter : undefined)
  visible: titleText !== ""
  clip: true

  Text {
    id: titleLabel
    text: root.titleText
    color: root.textColor
    font.family: root.uiFont
    font.pixelSize: root.fontSize
    font.italic: root.italic
    elide: root.horizontal ? Text.ElideRight : Text.ElideNone
    verticalAlignment: Text.AlignVCenter

    anchors.verticalCenter: root.horizontal ? parent.verticalCenter : undefined

    transform: [
      Rotation {
        angle: root.horizontal ? 0 : root.rotation
        origin.x: 0
        origin.y: 0
      },
      Translate {
        x: 0
        y: root.horizontal ? 0 : titleLabel.implicitWidth
      }
    ]

    width: root.horizontal ? Math.min(titleLabel.implicitWidth, root.maxText) : titleLabel.implicitWidth
    height: root.horizontal ? parent.height : 26
  }
}