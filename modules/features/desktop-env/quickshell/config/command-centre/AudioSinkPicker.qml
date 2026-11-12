pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."

// Command Centre output switcher: one chip per PipeWire sink with the current
// output marked, plus a mixer shortcut. Chips switch with a single click and
// wrap onto another line when there are many outputs, so the section never
// reflows the way the old collapsible list did.
Flow {
  id: root

  // Long sink names elide here rather than stretching the chip.
  property int labelMaxWidth: 150

  visible: Config.ccShowSinkSwitcher && AudioService.audioSinks.length > 0
  Layout.fillWidth: true
  spacing: 6

  Repeater {
    model: AudioService.audioSinks

    delegate: Pill {
      id: sinkChip
      required property var modelData

      readonly property bool isCurrent: AudioService.audioSink !== null && modelData.id === AudioService.audioSink.id

      pillHeight: 26
      baseColour: sinkChip.isCurrent ? Colours.bgSubtle : "transparent"
      hoverColour: Colours.bgSubtle
      // The current output is a status indicator, so it does not react to the
      // pointer and cannot be re-selected.
      hoverHighlight: !sinkChip.isCurrent
      border.color: (sinkChip.isCurrent || sinkChip.hovered) ? Colours.accent : Colours.border
      clickable: !sinkChip.isCurrent
      onClicked: AudioService.selectAudioSink(sinkChip.modelData)

      Row {
        anchors.centerIn: parent
        spacing: 5

        Text {
          text: sinkChip.isCurrent ? "󰄬" : "󰓃"
          color: sinkChip.isCurrent ? Colours.accent : Colours.fgDim
          font.family: Session.monoFont
          font.pixelSize: Config.iconSizeSm
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: AudioService.sinkLabel(sinkChip.modelData)
          color: sinkChip.isCurrent ? Colours.fg : Colours.fgMid
          font.family: Session.sansFont
          font.pixelSize: Config.fontSizeSm
          font.bold: sinkChip.isCurrent
          elide: Text.ElideRight
          maximumLineCount: 1
          width: Math.min(implicitWidth, root.labelMaxWidth)
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }

  Pill {
    id: mixerChip

    pillHeight: 26
    baseColour: "transparent"
    hoverColour: Colours.bgSubtle
    hoverHighlight: true
    border.color: mixerChip.hovered ? Colours.accent : Colours.border
    clickable: true
    onClicked: {
      // The panel would cover the mixer window.
      UiState.commandCentreVisible = false
      AudioService.openMixer()
    }

    Row {
      anchors.centerIn: parent
      spacing: 5

      Text {
        text: "󰒓"
        color: mixerChip.hovered ? Colours.accent : Colours.fgDim
        font.family: Session.monoFont
        font.pixelSize: Config.iconSizeSm
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: "Mixer"
        color: mixerChip.hovered ? Colours.fg : Colours.fgMid
        font.family: Session.sansFont
        font.pixelSize: Config.fontSizeSm
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }
}
