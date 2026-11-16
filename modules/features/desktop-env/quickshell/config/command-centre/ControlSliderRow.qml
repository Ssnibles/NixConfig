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
  // Track style passed to the slider; solid unless a row asks otherwise.
  property string sliderStyle: "solid"
  signal sliderMoved(real value)
  property string percentText: ""

  spacing: Config.spaceMd

  IconButton {
    buttonSize: Config.spaceXl + Config.spaceSm
    radius: Config.itemRadiusSm
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
    style: rowRoot.sliderStyle
    snapPercent: 5
    onMoved: function(v) { rowRoot.sliderMoved(v) }
  }

  // Fixed, right aligned column sized to one spacing step so the slider keeps
  // identical length regardless of 1, 2, or 3 digits.
  Text {
    text: rowRoot.percentText
    color: rowRoot.percentColour
    font.family: Session.monoFont
    font.pixelSize: Config.fontSizeLg
    Layout.minimumWidth: Config.space2xl
    Layout.preferredWidth: Config.space2xl
    Layout.maximumWidth: Config.space2xl
    horizontalAlignment: Text.AlignRight
    Layout.alignment: Qt.AlignVCenter
  }
}
