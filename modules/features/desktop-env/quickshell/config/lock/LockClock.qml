pragma ComponentBehavior: Bound
import QtQuick
import ".."

// Lock screen clock and date, shared by the primary and secondary screens.
Column {
  spacing: Config.spaceXs

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    text: ClockService.lockTimeStr
    color: Colours.fg
    font.family: Session.serifFont
    font.pixelSize: Config.fontSize4xl
    font.italic: true
    font.letterSpacing: Config.displayLetterSpacing
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    text: ClockService.lockDateStr
    color: Colours.fgDim
    font.family: Session.sansFont
    font.pixelSize: Config.fontSizeLg
  }
}
