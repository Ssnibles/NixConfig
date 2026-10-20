pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import Quickshell.Networking
import Quickshell.Bluetooth
import QtQuick
import "Utils.js" as Utils

// Central event-driven hardware & system state singleton:
//   - Audio Output Sinks & Microphone Input (PipeWire)
//   - Screen Backlight (sysfs FileView + brightnessctl)
//   - On-Screen Display (OSD) state
//   - Network (Quickshell.Networking)
//   - Battery / Power (Quickshell.Services.UPower)
//   - Bluetooth (Quickshell.Bluetooth)
//   - System Tray (Quickshell.Services.SystemTray)
// Ingested by VolumeWidget, NetworkWidget, BatteryWidget, BluetoothWidget,
// SystemTrayWidget, CommandCentre, LockScreen, and OsdOverlay.
Singleton {
  id: root

  // =========================================================================
  // On-Screen Display (OSD) State
  // =========================================================================
  property bool osdVisible: false
  property string osdKind: "volume" // "volume" | "mic" | "brightness"

  readonly property bool osdMuted: {
    if (root.osdKind === "volume") return root.muted
    if (root.osdKind === "mic") return root.micMuted
    return false
  }

  readonly property string osdIcon: {
    if (root.osdKind === "mic") return root.micIcon
    if (root.osdKind === "brightness") return "󰃠"
    return root.volumeIcon
  }

  readonly property string osdLabel: {
    if (root.osdKind === "mic") return root.micMuted ? "Mic Muted" : (root.micVolumePercent + "%")
    if (root.osdKind === "brightness") return root.brightnessPercent + "%"
    return root.muted ? "Muted" : (root.volumePercent + "%")
  }

  readonly property real osdValue: {
    if (root.osdKind === "mic") return root.micMuted ? 0 : Math.max(0, Math.min(1.0, root.micVolume))
    if (root.osdKind === "brightness") return Math.max(0, Math.min(1.0, root.brightness))
    return root.muted ? 0 : Math.max(0, Math.min(1.0, root.volume))
  }

  function showOsd(kind) {
    if (!Config.osdEnabled || Config.commandCentreVisible) return
    root.osdKind = kind || "volume"
    root.osdVisible = true
    osdHideTimer.restart()
  }

  Timer {
    id: osdHideTimer
    interval: Config.osdTimeoutMs
    repeat: false
    onTriggered: root.osdVisible = false
  }

  Connections {
    target: Config
    function onCommandCentreVisibleChanged() {
      if (Config.commandCentreVisible) {
        root.osdVisible = false
        osdHideTimer.stop()
      }
    }
  }

  // =========================================================================
  // Audio Output (PipeWire Default Sink & Sink Switcher)
  // =========================================================================
  readonly property var audioSink: (Pipewire.ready && Pipewire.defaultAudioSink) ? Pipewire.defaultAudioSink : null
  readonly property var audioSource: (Pipewire.ready && Pipewire.defaultAudioSource) ? Pipewire.defaultAudioSource : null

  readonly property var audioSinks: {
    if (!Pipewire.ready || !Pipewire.nodes) return []
    var list = Pipewire.nodes.values || []
    var out = []
    for (var i = 0; i < list.length; i++) {
      var n = list[i]
      if (n && !n.isStream && n.isSink && n.audio) {
        out.push(n)
      }
    }
    return out
  }

  PwObjectTracker {
    objects: {
      var tracked = []
      if (root.audioSink) tracked.push(root.audioSink)
      if (root.audioSource) tracked.push(root.audioSource)
      for (var i = 0; i < root.audioSinks.length; i++) {
        if (tracked.indexOf(root.audioSinks[i]) === -1) {
          tracked.push(root.audioSinks[i])
        }
      }
      return tracked
    }
  }

  readonly property var audioInfo: root.audioSink ? root.audioSink.audio : null
  readonly property real volume: root.audioInfo ? root.audioInfo.volume : 0
  readonly property bool muted: root.audioInfo ? root.audioInfo.muted : false
  readonly property int volumePercent: Math.round(root.volume * 100)
  readonly property string volumeIcon: Utils.volumeIcon(root.volume, root.muted)

  function sinkDisplayName(node) {
    if (!node) return "Audio Output"
    return node.description || node.nickname || node.name || ("Output " + node.id)
  }

  function selectAudioSink(node) {
    if (node) {
      Pipewire.preferredDefaultAudioSink = node
    }
  }

  function toggleMute() {
    if (root.audioInfo) {
      root.audioInfo.muted = !root.muted
    }
  }

  function setVolume(val) {
    if (!root.audioInfo) return
    root.audioInfo.volume = Math.max(0, Math.min(Config.volMax, val))
  }

  function setVolumeDebounced(val) {
    volSetTimer.targetVal = Math.max(0, Math.min(Config.volMax, val))
    volSetTimer.restart()
  }

  function stepVolume(direction) {
    var dir = direction > 0 ? 1 : -1
    root.setVolume(root.volume + dir * Config.volStep)
  }

  function openMixer() {
    Quickshell.execDetached(Config.cmdMixer)
  }

  Timer {
    id: volSetTimer
    interval: 50
    repeat: false
    property real targetVal: 0
    onTriggered: root.setVolume(volSetTimer.targetVal)
  }

  // =========================================================================
  // Microphone Input (PipeWire Default Source)
  // =========================================================================
  readonly property var audioSourceInfo: root.audioSource ? root.audioSource.audio : null
  readonly property bool hasMic: root.audioSource !== null && root.audioSourceInfo !== null
  readonly property real micVolume: root.audioSourceInfo ? root.audioSourceInfo.volume : 0
  readonly property bool micMuted: root.audioSourceInfo ? root.audioSourceInfo.muted : false
  readonly property int micVolumePercent: Math.round(root.micVolume * 100)
  readonly property string micIcon: Utils.micIcon(root.micVolume, root.micMuted)

  function toggleMicMute() {
    if (root.audioSourceInfo) {
      root.audioSourceInfo.muted = !root.micMuted
    }
  }

  function setMicVolume(val) {
    if (!root.audioSourceInfo) return
    root.audioSourceInfo.volume = Math.max(0, Math.min(1.0, val))
  }

  function setMicVolumeDebounced(val) {
    micSetTimer.targetVal = Math.max(0, Math.min(1.0, val))
    micSetTimer.restart()
  }

  function stepMicVolume(direction) {
    var dir = direction > 0 ? 1 : -1
    root.setMicVolume(root.micVolume + dir * Config.micStep)
  }

  Timer {
    id: micSetTimer
    interval: 50
    repeat: false
    property real targetVal: 0
    onTriggered: root.setMicVolume(micSetTimer.targetVal)
  }

  // =========================================================================
  // Unified Audio & Mic OSD Settle Tracking
  // =========================================================================
  property bool _audioReady: false
  property int _lastVolPct: -1
  property bool _lastMuted: false
  property int _lastMicPct: -1
  property bool _lastMicMuted: false

  function _armAudioSettle() {
    root._audioReady = false
    audioSettleTimer.restart()
  }

  onAudioSinkChanged: root._armAudioSettle()
  onAudioSourceChanged: root._armAudioSettle()

  Timer {
    id: audioSettleTimer
    interval: 300
    repeat: false
    onTriggered: {
      root._lastVolPct = root.volumePercent
      root._lastMuted = root.muted
      root._lastMicPct = root.micVolumePercent
      root._lastMicMuted = root.micMuted
      root._audioReady = true
    }
  }

  function _checkSinkOsd() {
    if (!root._audioReady || !root.audioSink) return
    if (root.volumePercent !== root._lastVolPct || root.muted !== root._lastMuted) {
      root._lastVolPct = root.volumePercent
      root._lastMuted = root.muted
      root.showOsd("volume")
    }
  }

  function _checkMicOsd() {
    if (!root._audioReady || !root.audioSource) return
    if (root.micVolumePercent !== root._lastMicPct || root.micMuted !== root._lastMicMuted) {
      root._lastMicPct = root.micVolumePercent
      root._lastMicMuted = root.micMuted
      root.showOsd("mic")
    }
  }

  onVolumePercentChanged: root._checkSinkOsd()
  onMutedChanged: root._checkSinkOsd()
  onMicVolumePercentChanged: root._checkMicOsd()
  onMicMutedChanged: root._checkMicOsd()

  // =========================================================================
  // Screen Brightness (brightnessctl + sysfs watcher)
  // =========================================================================
  property real brightness: 0.5
  property bool brightnessAvailable: false
  property string backlightDevice: ""
  property bool _notifyBrightnessOnNextRead: false
  property bool _brightnessRefreshPending: false
  readonly property int brightnessPercent: Math.round(root.brightness * 100)

  function refreshBrightness(notifyOsd) {
    if (notifyOsd) root._notifyBrightnessOnNextRead = true
    if (!brightnessGetProc.running) {
      brightnessGetProc.exec(["brightnessctl", "-m"])
    } else {
      root._brightnessRefreshPending = true
    }
  }

  function setBrightness(val) {
    var clamped = Math.max(0, Math.min(1.0, val))
    root.brightness = clamped
    brightnessSetTimer.targetVal = clamped
    brightnessSetTimer.restart()
  }

  function stepBrightness(direction) {
    if (!root.brightnessAvailable) return
    var dir = direction > 0 ? 1 : -1
    root.setBrightness(root.brightness + dir * Config.brightnessStep)
    root.showOsd("brightness")
  }

  FileView {
    id: backlightWatcher
    path: root.backlightDevice !== "" ? ("/sys/class/backlight/" + root.backlightDevice + "/brightness") : ""
    watchChanges: root.backlightDevice !== ""
    onFileChanged: {
      if (!brightnessSetTimer.running) {
        root.refreshBrightness(true)
      }
    }
  }

  Process {
    id: brightnessGetProc
    command: ["brightnessctl", "-m"]
    stdout: StdioCollector {
      onStreamFinished: {
        var shouldNotify = root._notifyBrightnessOnNextRead
        root._notifyBrightnessOnNextRead = false
        var lines = this.text.trim().split("\n")
        for (var i = 0; i < lines.length; i++) {
          var parts = lines[i].split(",")
          if (parts.length >= 4 && parts[1] === "backlight") {
            var pct = parseInt(parts[3].replace("%", "")) / 100.0
            if (!isNaN(pct)) {
              var prevPct = root.brightnessPercent
              root.backlightDevice = parts[0] || ""
              root.brightness = pct
              root.brightnessAvailable = true
              if (shouldNotify && root.brightnessPercent !== prevPct) {
                root.showOsd("brightness")
              }
              if (root._brightnessRefreshPending) {
                root._brightnessRefreshPending = false
                brightnessGetProc.exec(["brightnessctl", "-m"])
              }
              return
            }
          }
        }
        root.brightnessAvailable = false
        if (root._brightnessRefreshPending) {
          root._brightnessRefreshPending = false
          brightnessGetProc.exec(["brightnessctl", "-m"])
        }
      }
    }
  }

  Timer {
    id: brightnessSetTimer
    interval: 50
    repeat: false
    property real targetVal: 0
    onTriggered: {
      Quickshell.execDetached(["brightnessctl", "set", Math.round(brightnessSetTimer.targetVal * 100) + "%"])
    }
  }

  // =========================================================================
  // Network State (Quickshell.Networking)
  // =========================================================================
  readonly property var netDevices: (Networking.devices && Networking.devices.values) ? Networking.devices.values : []
  readonly property var wiredDev: Utils.findFirst(root.netDevices, function(d) { return d && d.type === DeviceType.Wired })
  readonly property var wifiDev: Utils.findFirst(root.netDevices, function(d) { return d && d.type === DeviceType.Wifi && d.connected })
    || Utils.findFirst(root.netDevices, function(d) { return d && d.type === DeviceType.Wifi })

  readonly property bool isWired: !!(root.wiredDev && root.wiredDev.connected)
  readonly property bool isWifi: !!(root.wifiDev && root.wifiDev.connected)
  readonly property var wifiNet: Utils.findFirst(root.wifiDev && root.wifiDev.networks ? root.wifiDev.networks.values : [], function(n) { return n && n.connected })
  readonly property string wifiSsid: root.wifiNet ? (root.wifiNet.name || "") : ""

  readonly property string netIcon: {
    if (root.isWired) return "󰈀"
    if (root.isWifi) return "󰤨"
    return "󰤮"
  }

  readonly property string netText: {
    if (root.isWired) return "Ethernet"
    if (root.isWifi) return root.wifiSsid !== "" ? root.wifiSsid : "Wi-Fi"
    return "Offline"
  }

  readonly property color netColour: (root.isWired || root.isWifi) ? Colours.accent : Colours.fgDim

  readonly property string netTitle: {
    if (root.isWired) return "Wired (" + root.wiredDev.name + ")"
    if (root.isWifi) return root.wifiSsid !== "" ? root.wifiSsid : "Connected"
    return "Disconnected"
  }

  readonly property var netDetails: {
    var d = []
    if (root.isWifi && root.wifiNet) {
      d.push("Signal · " + Math.round(root.wifiNet.signalStrength * 100) + "%")
    }
    d.push("Click · nmtui")
    return d
  }

  function openNetworkManager() {
    Quickshell.execDetached(Config.cmdNetworkManager)
  }

  // =========================================================================
  // Battery State (Quickshell.Services.UPower)
  // =========================================================================
  readonly property var batDevice: Utils.findBatteryDevice(UPower.devices, UPower.displayDevice)
  readonly property bool batPresent: root.batDevice !== null && root.batDevice.isLaptopBattery
  readonly property int batPct: root.batDevice ? Math.round(root.batDevice.percentage * 100) : 0
  readonly property bool batCharging: !!(root.batDevice && root.batDevice.state === UPowerDeviceState.Charging)
  readonly property bool batPlugged: !!(root.batDevice && root.batDevice.state === UPowerDeviceState.FullyCharged)
  readonly property int batState: root.batDevice ? root.batDevice.state : UPowerDeviceState.Unknown
  readonly property string batIcon: Utils.batteryIcon(root.batPct, root.batCharging, root.batPlugged, root.batPresent)

  readonly property color batColour: {
    if (!root.batPresent) return Colours.fg
    if (root.batCharging || root.batPlugged) return Colours.green
    if (root.batPct <= 15) return Colours.red
    if (root.batPct <= 30) return Colours.yellow
    return Colours.fg
  }

  readonly property string batTitle: {
    var state
    switch (root.batState) {
      case UPowerDeviceState.Charging:         state = "Charging"; break
      case UPowerDeviceState.FullyCharged:     state = "Plugged in"; break
      case UPowerDeviceState.PendingCharge:    state = "Pending charge"; break
      case UPowerDeviceState.PendingDischarge: state = "Pending discharge"; break
      case UPowerDeviceState.Empty:            state = "Empty"; break
      default:                                 state = "Discharging"; break
    }
    return root.batPct + "% · " + state
  }

  readonly property var batDetails: {
    var d = []
    if (root.batDevice) {
      if (root.batCharging && root.batDevice.timeToFull > 0) {
        var mins = Math.round(root.batDevice.timeToFull / 60)
        var h = Math.floor(mins / 60)
        var m = mins % 60
        d.push((h > 0 ? h + "h " : "") + m + "m until full")
      } else if (!root.batCharging && !root.batPlugged && root.batDevice.timeToEmpty > 0) {
        var mins2 = Math.round(root.batDevice.timeToEmpty / 60)
        var h2 = Math.floor(mins2 / 60)
        var m2 = mins2 % 60
        d.push((h2 > 0 ? h2 + "h " : "") + m2 + "m remaining")
      }
    }
    return d
  }

  // =========================================================================
  // Bluetooth State (Quickshell.Bluetooth)
  // =========================================================================
  readonly property var btAdapter: Bluetooth.defaultAdapter
  readonly property bool btPowered: !!(root.btAdapter && root.btAdapter.enabled)

  readonly property var btConnectedDevices: {
    var list = []
    var devs = (Bluetooth.devices && Bluetooth.devices.values) ? Bluetooth.devices.values : []
    for (var i = 0; i < devs.length; i++) {
      if (devs[i] && devs[i].connected) {
        var n = devs[i].deviceName || devs[i].name || devs[i].address || ""
        if (n && list.indexOf(n) === -1) list.push(n)
      }
    }
    return list
  }

  readonly property bool btConnected: root.btConnectedDevices.length > 0
  readonly property string btConnectedDevice: root.btConnected ? root.btConnectedDevices[0] : ""

  readonly property string btIcon: {
    if (root.btConnected) return "󰂱"
    if (root.btPowered) return "󰂯"
    return "󰂲"
  }

  readonly property color btColour: (root.btConnected || root.btPowered) ? Colours.accent : Colours.fgDim

  readonly property string btStatusText: {
    if (root.btConnected) {
      if (root.btConnectedDevices.length > 1) {
        var firstDev = root.btConnectedDevice !== "" ? root.btConnectedDevice : "Connected"
        if (firstDev.length > 10) firstDev = firstDev.substring(0, 9) + "…"
        return firstDev + " (+" + (root.btConnectedDevices.length - 1) + ")"
      }
      var dev = root.btConnectedDevice !== "" ? root.btConnectedDevice : "Connected"
      if (dev.length > 14) return dev.substring(0, 13) + "…"
      return dev
    }
    if (root.btPowered) return "On"
    return "Off"
  }

  readonly property string btTitle: {
    if (root.btConnected) {
      if (root.btConnectedDevices.length > 1) {
        return root.btConnectedDevices.length + " Bluetooth Devices Connected"
      }
      return root.btConnectedDevice !== "" ? root.btConnectedDevice : "Bluetooth Connected"
    }
    if (root.btPowered) return "Bluetooth On"
    return "Bluetooth Off"
  }

  readonly property var btDetails: {
    var d = []
    if (root.btConnected && root.btConnectedDevices.length > 0) {
      d.push("Connected · " + root.btConnectedDevices.join(", "))
    }
    d.push("Left click · Toggle Power")
    d.push("Right click · Blueman Manager")
    return d
  }

  function toggleBluetooth() {
    if (root.btAdapter) {
      root.btAdapter.enabled = !root.btAdapter.enabled
    } else {
      Quickshell.execDetached(["bluetoothctl", "power", root.btPowered ? "off" : "on"])
    }
  }

  function openBluetoothManager() {
    Quickshell.execDetached(Config.cmdBluetoothManager)
  }

  // =========================================================================
  // System Tray State (Quickshell.Services.SystemTray)
  // =========================================================================
  readonly property var trayAllItems: (Config.trayEnabled && SystemTray.items && SystemTray.items.values)
    ? SystemTray.items.values
    : []

  function trayItemKey(item) {
    if (!item) return ""
    return String(item.id || item.title || item.tooltipTitle || "")
  }

  function isTrayItemHidden(item) {
    if (!item) return false
    var key = root.trayItemKey(item)
    var sessionHidden = Config.runtimeHiddenTrayApps || []
    var sessionUnhidden = Config.runtimeUnhiddenTrayApps || []
    if (key && sessionHidden.indexOf(key) !== -1) return true
    if (key && sessionUnhidden.indexOf(key) !== -1) return false
    return Utils.isTrayItemHidden(item, Config.trayHiddenApps)
  }

  function toggleTrayItemHidden(item) {
    if (!item) return
    var key = root.trayItemKey(item)
    if (!key) return
    var currentlyHidden = root.isTrayItemHidden(item)
    var nextHidden = (Config.runtimeHiddenTrayApps || []).slice()
    var nextUnhidden = (Config.runtimeUnhiddenTrayApps || []).slice()
    var hIdx = nextHidden.indexOf(key)
    var uIdx = nextUnhidden.indexOf(key)

    if (currentlyHidden) {
      if (hIdx !== -1) nextHidden.splice(hIdx, 1)
      if (Utils.isTrayItemHidden(item, Config.trayHiddenApps) && uIdx === -1) {
        nextUnhidden.push(key)
      }
    } else {
      if (uIdx !== -1) nextUnhidden.splice(uIdx, 1)
      if (hIdx === -1) nextHidden.push(key)
    }

    Config.runtimeHiddenTrayApps = nextHidden
    Config.runtimeUnhiddenTrayApps = nextUnhidden
    if (root.trayHiddenCount === 0) Config.trayExpanded = false
  }

  readonly property int trayHiddenCount: {
    var count = 0
    for (var i = 0; i < root.trayAllItems.length; i++) {
      if (root.isTrayItemHidden(root.trayAllItems[i])) count++
    }
    return count
  }

  readonly property bool trayShowHiddenItems: Config.trayShowExpandButton && Config.trayExpanded

  readonly property var trayVisibleItems: {
    var out = []
    for (var i = 0; i < root.trayAllItems.length; i++) {
      var item = root.trayAllItems[i]
      if (!item) continue
      if (!root.isTrayItemHidden(item) || root.trayShowHiddenItems) {
        out.push(item)
      }
    }
    return out
  }

  readonly property bool trayHasContent: Config.trayEnabled
    && (root.trayVisibleItems.length > 0 || (Config.trayShowExpandButton && root.trayHiddenCount > 0))

  // =========================================================================
  // IPC Handlers (`quickshell ipc call system|tray <action>`)
  // =========================================================================
  IpcHandler {
    target: "system"

    function volumeUp(): void {
      root.stepVolume(1)
    }

    function volumeDown(): void {
      root.stepVolume(-1)
    }

    function toggleMute(): void {
      root.toggleMute()
    }

    function micUp(): void {
      root.stepMicVolume(1)
    }

    function micDown(): void {
      root.stepMicVolume(-1)
    }

    function toggleMicMute(): void {
      root.toggleMicMute()
    }

    function brightnessUp(): void {
      root.stepBrightness(1)
    }

    function brightnessDown(): void {
      root.stepBrightness(-1)
    }
  }

  IpcHandler {
    target: "tray"

    function toggle(): void {
      Config.trayEnabled = !Config.trayEnabled
    }

    function toggleExpanded(): void {
      Config.trayExpanded = !Config.trayExpanded
    }

    function toggleExpandButton(): void {
      Config.trayShowExpandButton = !Config.trayShowExpandButton
    }
  }

  Component.onCompleted: {
    root.refreshBrightness(false)
    root._armAudioSettle()
  }
}
