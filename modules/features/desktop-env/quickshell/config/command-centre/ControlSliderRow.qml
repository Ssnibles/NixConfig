pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."

// Icon, slider, and percentage row used by the Command Centre controls.
RowLayout {
  id: rowRoot

  property string icon: ""
  // Red tint for muted/unavailable states; drives all the derived colours.
  property bool alert: false
  property color accent: Colours.accent
  property color iconColour: rowRoot.alert ? Colours.red : Colours.fg
  property color iconBorderColour: rowRoot.alert ? Colours.red : Colours.border
  property color sliderFillColour: rowRoot.alert ? Colours.red : rowRoot.accent
  property color percentColour: rowRoot.alert ? Colours.red : Colours.fg
  property bool iconClickable: false
  signal iconClicked()
  property real sliderValue: 0
  signal sliderMoved(real value)
  property string percentText: ""

  spacing: 10

  IconButton {
    buttonSize: 32
    icon: rowRoot.icon
    baseColour: Colours.bgSubtle
    hoverColour: Colours.bgRaised
    borderColour: rowRoot.iconBorderColour
    hoverBorderColour: rowRoot.iconBorderColour
    iconColour: rowRoot.iconColour
    hoverIconColour: rowRoot.iconColour
    // Without an icon action the icon is read-only, not disabled-looking.
    disabledIconColour: rowRoot.iconColour
    enabled: rowRoot.iconClickable
    onClicked: rowRoot.iconClicked()
  }

  SliderControl {
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignVCenter
    value: rowRoot.sliderValue
    fillColour: rowRoot.sliderFillColour
    snapPercent: 5
    onMoved: function(v) { rowRoot.sliderMoved(v) }
  }

  // Fixed, right aligned column sized to 38px so the slider keeps identical
  // length regardless of 1, 2, or 3 digits.
  Text {
    text: rowRoot.percentText
    color: rowRoot.percentColour
    font.family: Session.monoFont
    font.pixelSize: 14
    Layout.minimumWidth: 38
    Layout.preferredWidth: 38
    Layout.maximumWidth: 38
    horizontalAlignment: Text.AlignRight
    Layout.alignment: Qt.AlignVCenter
  }
}
