pragma ComponentBehavior: Bound
import QtQuick
import ".."

// Rounded track artwork with a glyph fallback, shared by the media card and the
// compact lock screen media row.
Rectangle {
  id: root

  property string source: ""
  property int artSize: Config.space3xl
  property int glyphSize: Config.iconSizeXl

  implicitWidth: root.artSize
  implicitHeight: root.artSize
  radius: Config.itemRadiusMd
  color: Colours.bgSubtle
  border.color: Colours.border
  border.width: Config.borderWidth

  Text {
    visible: !art.ready
    text: "󰎇"
    color: Colours.fgDim
    font.family: Session.monoFont
    font.pixelSize: root.glyphSize
    font.bold: true
    anchors.centerIn: parent
  }

  RoundedImage {
    id: art
    anchors.fill: parent
    sourceSize: Qt.size(root.artSize * 2, root.artSize * 2)
    radius: Config.itemRadiusMd
    source: root.source
  }
}
