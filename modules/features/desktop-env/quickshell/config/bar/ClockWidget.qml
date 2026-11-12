pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import ".."

Item {
  id: root

  property string uiFont: Session.monoFont
  property string timeFormat: Config.timeFormat
  readonly property string timeStr: root.timeFormat === Config.timeFormat
    ? ClockService.timeStr
    : Qt.formatTime(ClockService.now, root.timeFormat)
  property PanelWindow sharedWindow: null
  property bool horizontal: false
  property bool shown: true

  visible: root.shown

  implicitWidth: root.horizontal ? timeText.implicitWidth : timeColumn.implicitWidth
  implicitHeight: root.horizontal ? timeText.implicitHeight : timeColumn.implicitHeight

  // Stacked hours and minutes for the side bar.
  Column {
    id: timeColumn
    visible: !root.horizontal
    anchors.centerIn: parent
    spacing: -2

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: ClockService.hourStr
      color: Colours.accent
      font.family: root.uiFont
      font.pixelSize: 16
      font.bold: true
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: ClockService.minuteStr
      color: Colours.fg
      font.family: root.uiFont
      font.pixelSize: 16
      font.bold: true
    }
  }

  Text {
    id: timeText
    visible: root.horizontal
    anchors.centerIn: parent
    text: root.timeStr
    color: Colours.accent
    font.family: root.uiFont
    font.pixelSize: 14
    font.bold: true
  }

  Tooltip {
    target: root
    sharedWindow: root.sharedWindow
    icon: "\u{F017}"
    iconColour: Colours.accent
    title: ClockService.ordinalDateStr
    contentWidth: 216
    contentComponent: Component {
      CalendarPopup { uiFont: root.uiFont }
    }
  }
}
