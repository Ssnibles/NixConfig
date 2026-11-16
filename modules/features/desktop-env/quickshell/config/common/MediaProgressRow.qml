pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../Utils.js" as Utils
import ".."

// Reusable elapsed-time + seekbar + total-time row.
// Used in CommandCentre, MediaWidget popover, and LockScreen.
RowLayout {
  id: root
  spacing: Config.spaceMd

  property real position: 0   // current position in seconds
  property real length: 0     // total length in seconds
  property real progress: 0   // 0..1 fraction (computed externally by MediaService)
  property bool seekable: true
  property bool live: false   // live stream: no finite length, not seekable
  // Seek bar colour; the cover card tints it from the artwork.
  property color fillColour: Colours.accent
  // Quiet part of the seek bar; tinted on a cover card.
  property color trackColour: Colours.bgSubtle
  // Elapsed and total time colour; follows the cover text on a cover card.
  property color labelColour: Colours.fgDim
  // Drives the wave on the seek bar: flat and still while paused.
  property bool playing: true
  // Squiggly by default so the seek bar reads as an audio wave.
  property string sliderStyle: "wavy"

  signal seekRequested(real progress)

  // Width of both fixed time columns, measured below.
  readonly property real timeLabelWidth: Math.ceil(timeSizer.implicitWidth)

  // Both time labels share one look and one fixed width, so the bar does not
  // resize as the digits change.
  component TimeLabel: Text {
    color: root.labelColour
    font.family: Session.sansFont
    font.pixelSize: Config.fontSizeSm
    Layout.minimumWidth: root.timeLabelWidth
    Layout.preferredWidth: root.timeLabelWidth
    Layout.maximumWidth: root.timeLabelWidth
  }

  TimeLabel {
    id: positionText
    text: Utils.formatTime(Math.round(root.position))
    horizontalAlignment: Text.AlignRight
  }

  SliderControl {
    visible: !root.live
    Layout.fillWidth: true
    value: root.progress
    fillColour: root.fillColour
    trackColour: root.trackColour
    style: root.sliderStyle
    animated: root.playing
    enabled: root.seekable
    onMoved: function(v) { root.seekRequested(v) }
  }

  TimeLabel {
    visible: !root.live
    text: Utils.formatTime(Math.round(root.length))
  }

  Text {
    visible: root.live
    text: "● LIVE"
    color: Colours.red
    font.family: Session.sansFont
    font.pixelSize: Config.fontSizeXs
    font.bold: true
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignRight
  }

  // Hidden twin: measures the widest time ("000:00" covers up to 999:59) with
  // the same font, so the seekbar keeps the same length as the minutes digits
  // change. Layouts skip invisible items, so it costs no space.
  Text {
    id: timeSizer
    visible: false
    text: "000:00"
    font: positionText.font
  }
}
