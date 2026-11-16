pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."

// Reusable prev / play-pause / next button cluster with hover scaling.
// Used in CommandCentre media card and MediaWidget popover.
RowLayout {
  id: root
  spacing: Math.round(Config.spaceSm * root.buttonScale)

  property bool canPrevious: false
  property bool canNext: false
  property bool isPlaying: false
  property string uiFont: Session.monoFont
  // Scales the buttons for larger cards, e.g. the bento cover card.
  property real buttonScale: 1
  // Fills the play button with this colour. Transparent keeps the neutral look.
  property color accentColour: "transparent"
  property color onAccentColour: Colours.bg
  // Skip buttons follow the cover too: tinted glyphs and a tinted hover.
  property color sideIconColour: Colours.fg
  property color sideHoverColour: Colours.bgSubtle
  property color sideHoverIconColour: Colours.accent

  signal previousClicked()
  signal playPauseClicked()
  signal nextClicked()

  // The play button keeps its colours on hover and only grows.
  readonly property color playBaseColour: root.accentColour.a > 0 ? root.accentColour : Colours.bgSubtle
  readonly property color playIconColour: root.accentColour.a > 0 ? root.onAccentColour : Colours.fg
  readonly property color playBorderColour: root.accentColour.a > 0 ? "transparent" : Colours.border

  // Skip buttons share their look; only the glyph and the signal differ. The
  // idle background is the hover tint at zero alpha, so the fade in keeps the
  // same hue instead of passing through transparent black.
  component SideButton: IconButton {
    buttonSize: Math.round((Config.spaceXl + Config.space2xs) * root.buttonScale)
    iconSize: Math.round(Config.iconSizeMd * root.buttonScale)
    radius: width / 2
    uiFont: root.uiFont
    iconColour: root.sideIconColour
    baseColour: Qt.rgba(root.sideHoverColour.r, root.sideHoverColour.g, root.sideHoverColour.b, 0)
    hoverColour: root.sideHoverColour
    hoverIconColour: root.sideHoverIconColour
    hoverScale: 1.08
  }

  SideButton {
    Layout.alignment: Qt.AlignVCenter
    icon: "󰒮"
    enabled: root.canPrevious
    onClicked: root.previousClicked()
  }

  IconButton {
    Layout.alignment: Qt.AlignVCenter
    buttonSize: Math.round((Config.spaceXl + Config.spaceSm) * root.buttonScale)
    radius: width / 2
    icon: root.isPlaying ? "󰏤" : "󰐊"
    iconSize: Math.round(Config.iconSizeLg * root.buttonScale)
    uiFont: root.uiFont
    baseColour: root.playBaseColour
    hoverColour: root.playBaseColour
    borderColour: root.playBorderColour
    hoverBorderColour: root.playBorderColour
    iconColour: root.playIconColour
    hoverIconColour: root.playIconColour
    hoverScale: 1.08
    onClicked: root.playPauseClicked()
  }

  SideButton {
    Layout.alignment: Qt.AlignVCenter
    icon: "󰒭"
    enabled: root.canNext
    onClicked: root.nextClicked()
  }
}
