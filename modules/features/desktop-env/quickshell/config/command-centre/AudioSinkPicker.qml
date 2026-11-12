pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."

// Collapsible PipeWire output picker used by the Command Centre.
ColumnLayout {
  id: root

  property bool expanded: false

  readonly property bool available: Config.ccShowSinkSwitcher && AudioService.audioSinks.length > 0

  visible: root.available
  Layout.fillWidth: true
  spacing: 4

  // Audio Output Sink Selector Pill
  Pill {
    Layout.fillWidth: true
    pillHeight: 26
    radius: Config.itemRadiusSm
    baseColour: Colours.bgSubtle
    hoverColour: Colours.bgRaised
    hoverHighlight: true
    border.color: root.expanded ? Colours.accent : Colours.border
    clickable: true
    onClicked: root.expanded = !root.expanded

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 10
      anchors.rightMargin: 10
      spacing: 8

      Text {
        text: "󰓃"
        color: root.expanded ? Colours.accent : Colours.fgDim
        font.family: Config.monoFont
        font.pixelSize: Config.iconSizeSm
        Layout.alignment: Qt.AlignVCenter
      }

      Text {
        Layout.fillWidth: true
        text: AudioService.audioSink ? AudioService.sinkDisplayName(AudioService.audioSink) : "Default Output"
        color: Colours.fg
        font.family: Config.sansFont
        font.pixelSize: Config.fontSizeSm
        elide: Text.ElideRight
        Layout.alignment: Qt.AlignVCenter
      }

      Text {
        text: root.expanded ? "󰅃" : "󰅀"
        color: root.expanded ? Colours.accent : Colours.fgDim
        font.family: Config.monoFont
        font.pixelSize: Config.iconSizeSm
        Layout.alignment: Qt.AlignVCenter
      }
    }
  }

  // Expandable Audio Output Sink List
  ColumnLayout {
    visible: root.expanded
    Layout.fillWidth: true
    spacing: 4

    Repeater {
      model: AudioService.audioSinks

      delegate: Pill {
        id: outputPill
        required property var modelData
        readonly property bool isCurrent: AudioService.audioSink !== null && modelData.id === AudioService.audioSink.id

        Layout.fillWidth: true
        pillHeight: 28
        radius: Config.itemRadiusSm
        baseColour: outputPill.isCurrent ? Colours.bgSubtle : "transparent"
        hoverColour: Colours.bgSubtle
        hoverHighlight: true
        border.color: outputPill.isCurrent ? Colours.accent : "transparent"
        clickable: true
        onClicked: {
          AudioService.selectAudioSink(outputPill.modelData)
          root.expanded = false
        }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          spacing: 8

          Text {
            text: outputPill.isCurrent ? "󰄬" : "󰓃"
            color: outputPill.isCurrent ? Colours.accent : Colours.fgDim
            font.family: Config.monoFont
            font.pixelSize: Config.iconSizeSm
            Layout.alignment: Qt.AlignVCenter
          }

          Text {
            Layout.fillWidth: true
            text: AudioService.sinkDisplayName(outputPill.modelData)
            color: outputPill.isCurrent ? Colours.fg : Colours.fgMid
            font.family: Config.sansFont
            font.pixelSize: Config.fontSizeSm
            font.bold: outputPill.isCurrent
            elide: Text.ElideRight
            Layout.alignment: Qt.AlignVCenter
          }
        }
      }
    }

    Pill {
      id: outputMixerPill
      Layout.fillWidth: true
      pillHeight: 24
      radius: Config.itemRadiusSm
      baseColour: "transparent"
      hoverColour: Colours.bgSubtle
      hoverHighlight: true
      border.color: "transparent"
      clickable: true
      onClicked: {
        AudioService.openMixer()
        Config.commandCentreVisible = false
      }

      Row {
        anchors.centerIn: parent
        spacing: 6

        Text {
          text: "󰒓"
          color: outputMixerPill.hovered ? Colours.accent : Colours.fgDim
          font.family: Config.monoFont
          font.pixelSize: Config.iconSizeSm
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: "Open Audio Mixer"
          color: outputMixerPill.hovered ? Colours.fg : Colours.fgMid
          font.family: Config.sansFont
          font.pixelSize: Config.fontSizeXs
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }
}
