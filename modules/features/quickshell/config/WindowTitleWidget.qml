import QtQuick

Item {
  id: root

  property string titleText: ""
  property string uiFont: Config.monoFont
  property color textColor: Colors.fgMid
  property int fontSize: 11
  property real rotation: 270
  property int maxText: 120
  property bool italic: true

  width: 22
  height: Math.min(titleLabel.implicitWidth, root.maxText)
  anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
  visible: titleText !== ""
  clip: true

  Text {
    id: titleLabel
    text: root.titleText
    color: root.textColor
    font.family: root.uiFont
    font.pixelSize: root.fontSize
    font.italic: root.italic

    transform: [
      Rotation {
        angle: root.rotation
        origin.x: 0
        origin.y: 0
      },
      Translate {
        x: 0
        y: titleLabel.implicitWidth
      }
    ]

    width: titleLabel.implicitWidth
    height: 22
  }
}