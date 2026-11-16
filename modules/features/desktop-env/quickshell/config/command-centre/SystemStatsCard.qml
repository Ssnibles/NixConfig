pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."
// CPU and memory load for the bento side column. The card lives only while the
// command centre is open, so its sampling stops with the panel.
Card {
  id: root

  property real cpuPercent: 0
  property real memPercent: 0

  // Previous /proc/stat sample, kept to turn the counters into a share of the
  // time since the last read.
  property real _prevTotal: -1
  property real _prevBusy: -1

  cardColour: Colours.bg
  cardRadius: Config.commandCentreRadius
  // The side column reserves this much for the card when it sizes the calendar.
  implicitHeight: Config.space3xl * 2
  function sampleCpu(text) {
    var fields = text.split("\n")[0].trim().split(/\s+/)
    if (fields.length < 9) return
    var total = 0
    // guest and guest_nice repeat time already counted in user and nice.
    for (var i = 1; i <= 8; i++) total += Number(fields[i])
    var idle = Number(fields[4]) + Number(fields[5])
    var busy = total - idle
    if (root._prevTotal >= 0 && total > root._prevTotal) {
      root.cpuPercent = Math.round(100 * (busy - root._prevBusy) / (total - root._prevTotal))
    }
    root._prevTotal = total
    root._prevBusy = busy
  }

  function sampleMemory(text) {
    var total = 0
    var available = 0
    var lines = text.split("\n")
    for (var i = 0; i < lines.length; i++) {
      var fields = lines[i].split(/\s+/)
      if (fields[0] === "MemTotal:") total = Number(fields[1])
      else if (fields[0] === "MemAvailable:") available = Number(fields[1])
    }
    if (total > 0) root.memPercent = Math.round(100 * (total - available) / total)
  }

  Process {
    id: statProc
    command: ["cat", "/proc/stat"]
    stdout: StdioCollector {
      onStreamFinished: root.sampleCpu(this.text)
    }
  }

  Process {
    id: memProc
    command: ["cat", "/proc/meminfo"]
    stdout: StdioCollector {
      onStreamFinished: root.sampleMemory(this.text)
    }
  }

  Timer {
    interval: Config.systemStatsInterval
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      statProc.exec(["cat", "/proc/stat"])
      memProc.exec(["cat", "/proc/meminfo"])
    }
  }

  // A tick gauge and a value for each load. Kept local: this is the only user.
  component Meter: ColumnLayout {
    id: meter
    property string label: ""
    property real value: 0
    spacing: Config.space2xs

    RowLayout {
      Layout.fillWidth: true
      spacing: Config.spaceSm

      Text {
        Layout.fillWidth: true
        text: meter.label
        color: Colours.fgDim
        font.family: Session.monoFont
        font.pixelSize: Config.fontSizeSm
      }

      Text {
        text: Math.round(meter.value) + "%"
        color: Colours.fg
        font.family: Session.monoFont
        font.pixelSize: Config.fontSizeSm
      }
    }

    // Read-only, so it takes no clicks and shows no pointer cursor.
    SliderControl {
      Layout.fillWidth: true
      Layout.preferredHeight: Config.spaceMd
      trackAreaHeight: Config.spaceMd
      value: Math.max(0, Math.min(1, meter.value / 100))
      style: "ticks"
      enabled: false
    }
  }

  ColumnLayout {
    anchors.centerIn: parent
    width: parent.width - Config.commandCentreCardPadding * 2
    spacing: Config.commandCentreCardSpacing

    Meter {
      Layout.fillWidth: true
      label: "CPU"
      value: root.cpuPercent
    }

    Meter {
      Layout.fillWidth: true
      label: "Memory"
      value: root.memPercent
    }
  }
}
