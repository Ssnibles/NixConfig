pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."

// Output volume, sink switcher, microphone and brightness controls. Shared by
// the sidebar and bento layouts so their sliders cannot drift apart.
ColumnLayout {
  id: root

  readonly property bool showMicSlider: Config.ccMicSliderMode !== "hidden"
    && AudioService.hasMic
    && (Config.ccMicSliderMode === "always" || AudioService.micInUse)
  readonly property bool showBrightness: Config.ccShowBrightnessSlider && BrightnessService.brightnessAvailable

  spacing: Config.spaceMd

  // The output chips sit above or below the volume slider, whichever the config
  // asks for. Both Loaders share one definition; only one is ever active, and
  // an inactive Loader takes no space in the layout.
  Loader {
    Layout.fillWidth: true
    visible: Config.ccSinkSwitcherAboveVolume
    active: visible
    sourceComponent: sinkPickerComponent
  }

  ControlSliderRow {
    Layout.fillWidth: true
    icon: AudioService.volumeIcon
    alert: AudioService.muted
    iconClickable: true
    onIconClicked: AudioService.toggleMute()
    sliderValue: AudioService.volume
    onSliderMoved: function(v) {
      AudioService.setVolumeDebounced(v)
    }
    percentText: AudioService.volumePercent + "%"
  }

  Loader {
    Layout.fillWidth: true
    visible: !Config.ccSinkSwitcherAboveVolume
    active: visible
    sourceComponent: sinkPickerComponent
  }

  Divider {
    visible: root.showMicSlider
    Layout.fillWidth: true
  }

  ControlSliderRow {
    Layout.fillWidth: true
    visible: root.showMicSlider
    icon: AudioService.micIcon
    alert: AudioService.micMuted
    iconClickable: true
    onIconClicked: AudioService.toggleMicMute()
    sliderValue: AudioService.micVolume
    onSliderMoved: function(v) {
      AudioService.setMicVolumeDebounced(v)
    }
    percentText: AudioService.micVolumePercent + "%"
  }

  Divider {
    visible: root.showBrightness
    Layout.fillWidth: true
  }

  ControlSliderRow {
    Layout.fillWidth: true
    visible: root.showBrightness
    icon: "󰃠"
    iconColour: Colours.yellow
    accent: Colours.yellow
    sliderValue: BrightnessService.brightness
    onSliderMoved: function(v) {
      BrightnessService.setBrightness(v)
    }
    percentText: BrightnessService.brightnessPercent + "%"
  }

  Component {
    id: sinkPickerComponent

    AudioSinkPicker { }
  }
}
