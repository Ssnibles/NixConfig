import QtQuick

Item {
  id: root

  property string titleText: ""
  property string uiFont: "JetBrainsMono Nerd Font"

  width: 22
  height: Math.min(titleLabel.implicitWidth, 120)
  anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
  visible: titleText !== ""
  clip: true

  Text {
    id: titleLabel
    text: root.titleText
    color: Colors.fgMid
    font.family: root.uiFont
    font.pixelSize: 11
    font.italic: true

    transform: [
      Rotation {
        angle: 270
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
