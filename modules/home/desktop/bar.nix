{
  config,
  pkgs,
  ...
}:
let
  c =
    (import ../../../lib/stylix/semantic-colors.nix { stylixColors = config.lib.stylix.colors; })
    .withHash;
  specialWorkspaceName = "work";

  # ── Shell helpers ─────────────────────────────────────────────────────────
  quickshellAudioStatus = pkgs.writeShellScript "quickshell-audio-status" ''
    set -u
    timeout_bin="${pkgs.coreutils}/bin/timeout"
    audio_raw="$($timeout_bin 0.25s ${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)"
    audio_muted=false
    audio_percent=0
    if [ -n "$audio_raw" ]; then
    volume_float="$(printf '%s' "$audio_raw" | ${pkgs.gawk}/bin/awk '{print $2}')"
    if [ -n "$volume_float" ]; then
    audio_percent="$(${pkgs.gawk}/bin/awk -v v="$volume_float" 'BEGIN { printf "%d", (v * 100) + 0.5 }')"
    fi
    printf '%s' "$audio_raw" | grep -q '\[MUTED\]' && audio_muted=true
    fi
    audio_icon="󰕾"
    if   [ "$audio_muted" = true ];         then audio_icon="󰖁"
    elif [ "$audio_percent" -le 0 ];        then audio_icon="󰕿"
    elif [ "$audio_percent" -le 35 ];       then audio_icon="󰖀"
    fi
    ${pkgs.jq}/bin/jq -cn \
    --arg icon "$audio_icon" \
    --arg text "$audio_percent%" \
    --argjson muted "$audio_muted" \
    '{ icon: $icon, text: $text, muted: $muted }'
  '';

  quickshellSlowStatus = pkgs.writeShellScript "quickshell-slow-status" ''
    set -u
    timeout_bin="${pkgs.coreutils}/bin/timeout"
    bt_visible=false
    bt_icon="󰂲"
    bt_text=""
    if [ -x "${pkgs.bluez}/bin/bluetoothctl" ]; then
    bt_connected="$($timeout_bin 0.25s ${pkgs.bluez}/bin/bluetoothctl devices Connected 2>/dev/null \
    | sed -n '1s/^Device [^ ]* //p')"
    if $timeout_bin 0.25s ${pkgs.bluez}/bin/bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then
    bt_visible=true
    bt_icon="󰂯"
    bt_text="Bluetooth"
    fi
    if [ -n "$bt_connected" ]; then
    bt_visible=true
    bt_icon="󰂱"
    bt_text="$bt_connected"
    fi
    fi
    bt_text="$(printf '%s' "$bt_text" | cut -c1-28)"

    net_connected=false
    net_icon="󰖪"
    net_text="Offline"
    if [ -x "${pkgs.networkmanager}/bin/nmcli" ]; then
    net_line="$($timeout_bin 0.6s ${pkgs.networkmanager}/bin/nmcli -t -f TYPE,STATE,CONNECTION dev status 2>/dev/null \
    | ${pkgs.gawk}/bin/awk -F: '$2 == "connected" { print; exit }')"
    if [ -n "$net_line" ]; then
    net_connected=true
    net_type="''${net_line%%:*}"
    net_tmp="''${net_line#*:}"
    net_name="''${net_tmp#*:}"
    case "$net_type" in
    wifi)     net_icon="󰖩" ; net_text="''${net_name:-Wi-Fi}"    ;;
    ethernet) net_icon="󰈀" ; net_text="''${net_name:-Ethernet}" ;;
    *)        net_icon="󰈀" ; net_text="''${net_name:-Connected}" ;;
    esac
    fi
    fi
    net_text="$(printf '%s' "$net_text" | cut -c1-28)"

    bat_available=false
    bat_icon="󰁹"
    bat_text=""
    bat_charging=false
    bat_warning=false
    bat_critical=false
    bat_dir="$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1 || true)"
    if [ -n "$bat_dir" ]; then
    bat_available=true
    bat_pct="$(cat "$bat_dir/capacity" 2>/dev/null || echo 0)"
    bat_status="$(cat "$bat_dir/status" 2>/dev/null || echo Unknown)"
    if   [ "$bat_pct" -le 15 ]; then bat_icon="󰂃"; bat_critical=true
    elif [ "$bat_pct" -le 30 ]; then bat_icon="󰂀"; bat_warning=true
    elif [ "$bat_pct" -le 50 ]; then bat_icon="󰁿"
    elif [ "$bat_pct" -le 70 ]; then bat_icon="󰁾"
    elif [ "$bat_pct" -le 90 ]; then bat_icon="󰂂"
    else                              bat_icon="󰁹"
    fi
    if [ "$bat_status" = Charging ] || [ "$bat_status" = Full ]; then
    bat_charging=true
    bat_icon="󰂄"
    fi
    bat_text="$bat_pct%"
    fi
    ${pkgs.jq}/bin/jq -cn \
    --arg btIcon "$bt_icon" \
    --arg btText "$bt_text" \
    --argjson btVisible "$bt_visible" \
    --arg netIcon "$net_icon" \
    --arg netText "$net_text" \
    --argjson netConnected "$net_connected" \
    --arg batIcon "$bat_icon" \
    --arg batText "$bat_text" \
    --argjson batAvailable "$bat_available" \
    --argjson batCharging "$bat_charging" \
    --argjson batWarning "$bat_warning" \
    --argjson batCritical "$bat_critical" \
    '{
    bluetooth: { icon: $btIcon, text: $btText, visible: $btVisible },
    network:   { icon: $netIcon, text: $netText, connected: $netConnected },
    battery:   {
    icon: $batIcon, text: $batText, available: $batAvailable,
    charging: $batCharging, warning: $batWarning, critical: $batCritical
    }
    }'
  '';

  # Helper to get current workspace ID reliably
  quickshellCurrentWorkspace = pkgs.writeShellScript "quickshell-current-ws" ''
    ${pkgs.hyprland}/bin/hyprctl activeworkspace -j | ${pkgs.jq}/bin/jq -r '.id'
  '';
in
{
  programs.quickshell = {
    enable = true;
    package = pkgs.unstable.quickshell;
  };
  home.sessionVariables.QML2_IMPORT_PATH = "${pkgs.unstable.quickshell}/lib/qt-6/qml";
  xdg.configFile."quickshell/shell.qml".text = ''
    import Quickshell
    import Quickshell.Io
    import Quickshell.Hyprland
    import Quickshell.Services.Mpris
    import QtQuick
    import QtQuick.Layouts
    import QtQml

    // =========================================================================
    // ShellRoot — top-level singleton
    // =========================================================================
    ShellRoot {
    id: root
    property bool barVisible: true

    readonly property string uiFont: "JetBrains Mono"
    readonly property color bg:       "${c.bg}"
    readonly property color bgRaised: "${c.bgRaised}"
    readonly property color bgSubtle: "${c.bgSubtle}"
    readonly property color border:   "${c.border}"
    readonly property color fg:       "${c.fg}"
    readonly property color fgMid:    "${c.fgMid}"
    readonly property color fgDim:    "${c.fgDim}"
    readonly property color accent:   "${c.accent}"
    readonly property color teal:     "${c.teal}"
    readonly property color purple:   "${c.purple}"
    readonly property color green:    "${c.green}"
    readonly property color yellow:   "${c.yellow}"
    readonly property color red:      "${c.red}"

    property var audioState:     ({ icon: "󰕾",  text: "0%",      muted: false })
    property var bluetoothState: ({ icon: "󰂲",  text: "",        visible: false })
    property var networkState:   ({ icon: "󰖪",  text: "Offline", connected: false })
    property var batteryState:   ({
    icon: "󰁹", text: "", available: false,
    charging: false, warning: false, critical: false
    })

    // Reliable workspace ID via shell script
    property int currentWorkspaceId: 1
    Process {
    id: wsPoll
    command: ["${quickshellCurrentWorkspace}"]
    running: false
    stdout: StdioCollector {
    onStreamFinished: {
    var id = parseInt(this.text.trim());
    if (!isNaN(id)) root.currentWorkspaceId = id;
    }
    }
    }
    Timer {
    interval: 500
    repeat: true
    running: root.barVisible
    triggeredOnStart: true
    onTriggered: { if (!wsPoll.running) wsPoll.running = true; }
    }

    readonly property var hyprWorkspaces: HyprlandInfo.workspaces
    readonly property var hyprActiveWs:   HyprlandInfo.focusedWorkspace
    readonly property var hyprActiveWin:  HyprlandInfo.focusedClient

    readonly property string windowTitle: {
    var raw = (hyprActiveWin && hyprActiveWin.title) ? hyprActiveWin.title : "";
    if (!raw || raw.length === 0) return "Desktop";
    raw = raw.replace(/ — Mozilla Firefox$/, "Firefox");
    raw = raw.replace(/ — Zen Browser$/,     "Zen");
    raw = raw.replace(/ - Ghostty$/,         "Terminal");
    raw = raw.replace(/ - foot$/,            "Terminal");
    raw = raw.replace(/ - Neovim$/,          "Neovim");
    raw = raw.replace(/ - Nautilus$/,        "Files");
    return raw.length > 44 ? raw.substring(0, 44) + "…" : raw;
    }

    readonly property var regularWorkspaces: {
    if (!hyprWorkspaces) return [];
    return hyprWorkspaces.values.filter(ws => ws.id > 0 && !ws.name.startsWith("special:")).sort((a, b) => a.id - b.id);
    }

    readonly property var specialWs: {
    if (!hyprWorkspaces) return null;
    return hyprWorkspaces.values.find(ws => ws.name === "special:${specialWorkspaceName}") || null;
    }
    readonly property bool specialVisible: specialWs && specialWs.lastIpcObject && specialWs.lastIpcObject.visible === true
    readonly property int  specialWindows: specialWs ? specialWs.clientCount : 0

    readonly property var mprisPlayer: {
    var players = MprisController.players.values;
    if (!players || players.length === 0) return null;
    var playing = players.find(p => p.playbackStatus === MprisPlaybackStatus.Playing);
    return playing || players[0];
    }
    readonly property string mprisIcon: {
    if (!mprisPlayer) return "󰓛";
    switch (mprisPlayer.playbackStatus) {
    case MprisPlaybackStatus.Playing: return "󰐊";
    case MprisPlaybackStatus.Paused:  return "󰏤";
    default:                          return "󰓛";
    }
    }
    readonly property string mprisText: {
    if (!mprisPlayer) return "No media";
    var title  = mprisPlayer.trackTitle  || "";
    var artist = mprisPlayer.trackArtist || "";
    var raw = (title && artist) ? (title + " · " + artist) : (title || "No media");
    return raw.length > 44 ? raw.substring(0, 44) + "…" : raw;
    }

    readonly property string clockTime: Qt.formatDateTime(clockDate.now, "hh:mm")
    readonly property string clockDate_: Qt.formatDateTime(clockDate.now, "ddd, dd MMM")
    QtObject { id: clockDate; property date now: new Date() }
    Timer { interval: 1000; repeat: true; running: true; triggeredOnStart: true; onTriggered: clockDate.now = new Date() }

    Process { id: commandRunner; command: ["${pkgs.bash}/bin/bash", "-lc", "true"]; running: false }
    function runCommand(cmd) { commandRunner.command = ["${pkgs.bash}/bin/bash", "-lc", cmd]; commandRunner.running = false; commandRunner.running = true; }
    function switchWorkspace(id) { root.runCommand("${pkgs.hyprland}/bin/hyprctl dispatch workspace " + id); }
    function toggleSpecialWorkspace() { root.runCommand("${pkgs.hyprland}/bin/hyprctl dispatch togglespecialworkspace ${specialWorkspaceName}"); }
    function mediaPlayPause() { if (mprisPlayer) mprisPlayer.togglePlaying(); }
    function mediaNext() { if (mprisPlayer) mprisPlayer.next(); }
    function mediaPrevious() { if (mprisPlayer) mprisPlayer.previous(); }
    function openAudioControl() { root.runCommand("${pkgs.pavucontrol}/bin/pavucontrol"); }
    function toggleAudioMute() { root.runCommand("${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"); Qt.callLater(function() { if (!audioPoll.running) audioPoll.running = true; }); }
    function changeAudioVolume(step) { if (step >= 0) root.runCommand("${pkgs.wireplumber}/bin/wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ " + step + "%+"); else root.runCommand("${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ " + Math.abs(step) + "%-"); Qt.callLater(function() { if (!audioPoll.running) audioPoll.running = true; }); }
    function openBluetoothManager() { root.runCommand("${pkgs.blueman}/bin/blueman-manager"); }
    function tryParseJson(text, label) { if (!text || text.length === 0) return null; try { return JSON.parse(text); } catch (e) { console.warn("quickshell: failed to parse " + label + " payload:", e); return null; } }

    Process { id: audioPoll; command: ["${quickshellAudioStatus}"]; running: false; stdout: StdioCollector { onStreamFinished: { var p = root.tryParseJson(this.text.trim(), "audio"); if (p) root.audioState = p; } } }
    Timer { interval: 1000; repeat: true; running: root.barVisible; triggeredOnStart: true; onTriggered: { if (!audioPoll.running) audioPoll.running = true; } }

    Process { id: slowPoll; command: ["${quickshellSlowStatus}"]; running: false; stdout: StdioCollector { onStreamFinished: { var p = root.tryParseJson(this.text.trim(), "slow"); if (!p) return; if (p.bluetooth) root.bluetoothState = p.bluetooth; if (p.network) root.networkState = p.network; if (p.battery) root.batteryState = p.battery; } } }
    Timer { interval: 5000; repeat: true; running: root.barVisible; triggeredOnStart: true; onTriggered: { if (!slowPoll.running) slowPoll.running = true; } }

    IpcHandler { target: "bar"; function toggle(): void { root.barVisible = !root.barVisible; } function show(): void { root.barVisible = true; } function hide(): void { root.barVisible = false; } }

    // ======================================================================
    // Top Bar - SLIM & CLEAN
    // ======================================================================
    PanelWindow {
    id: topBar
    visible: root.barVisible
    focusable: false
    aboveWindows: true
    exclusionMode: ExclusionMode.Auto
    color: "transparent"
    implicitHeight: 32
    anchors { top: true; left: true; right: true }
    margins { top: 8; left: 16; right: 16 }

    // SINGLE CONTAINER PILL
    Rectangle {
    anchors.fill: parent
    radius: 8
    color: root.bg
    border.width: 1
    border.color: root.border

    // Inner Layout
    RowLayout {
    anchors.fill: parent
    anchors.margins: 4
    spacing: 8

    // ── LEFT SLOT: Workspace Indicator + Window Title ────────────────────────
    Rectangle {
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
    implicitHeight: 24
    radius: 6
    color: "transparent"

    RowLayout {
    anchors.fill: parent
    spacing: 8

    // Workspace Indicator (Current WS Number)
    Rectangle {
    width: 24
    height: 24
    radius: 6
    color: root.accent
    Text {
    anchors.centerIn: parent
    text: root.currentWorkspaceId
    color: root.bg
    font.family: root.uiFont
    font.pixelSize: 11
    font.bold: true
    }
    }

    // Divider
    Rectangle { width: 1; height: 12; color: root.border; opacity: 0.5 }

    // Window Title
    Text {
    Layout.fillWidth: true
    text: root.windowTitle
    color: root.fg
    font.family: root.uiFont
    font.pixelSize: 11
    elide: Text.ElideRight
    horizontalAlignment: Text.AlignLeft
    verticalAlignment: Text.AlignVCenter
    }
    }
    }

    // ── CENTER SLOT: Clock ──────────────────────────────────────────
    Rectangle {
    Layout.preferredWidth: clockRow.implicitWidth + 16
    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    implicitHeight: 24
    radius: 6
    color: "transparent"

    Row {
    id: clockRow
    anchors.centerIn: parent
    spacing: 4
    Text { anchors.verticalCenter: parent.verticalCenter; text: "󱑆"; color: root.teal; font.family: root.uiFont; font.pixelSize: 10 }
    Text { anchors.verticalCenter: parent.verticalCenter; text: root.clockTime; color: root.teal; font.family: root.uiFont; font.pixelSize: 11; font.bold: true }
    }
    MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onEntered: clockTooltipDelay.restart()
    onExited: { clockTooltipDelay.stop(); clockTipVisible.value = false }
    }
    Timer { id: clockTooltipDelay; interval: 200; repeat: false; onTriggered: clockTipVisible.value = true }
    QtObject { id: clockTipVisible; property bool value: false }
    Rectangle {
    visible: clockTipVisible.value
    z: 10
    anchors.top: parent.bottom
    anchors.topMargin: 4
    anchors.horizontalCenter: parent.horizontalCenter
    width: clockTipText.implicitWidth + 12
    height: clockTipText.implicitHeight + 8
    radius: 4
    color: root.bgRaised
    border.width: 1
    border.color: root.border
    Text { id: clockTipText; anchors.centerIn: parent; text: root.clockDate_; color: root.fgMid; font.family: root.uiFont; font.pixelSize: 10 }
    }
    }

    // ── RIGHT SLOT: Flat Icons with Small Labels ────────────
    Rectangle {
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
    implicitHeight: 24
    radius: 6
    color: "transparent"

    Row {
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    spacing: 12

    // Media
    Row {
    spacing: 4
    visible: MprisController.players.values.length > 0
    Text {
    text: root.mprisIcon
    color: root.purple
    font.family: root.uiFont
    font.pixelSize: 12
    }
    Text {
    text: root.mprisText
    color: root.purple
    font.family: root.uiFont
    font.pixelSize: 10
    elide: Text.ElideRight
    width: 100 // Fixed width instead of maximumWidth
    }
    MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    onClicked: (mouse) => { if (mouse.button === Qt.MiddleButton) root.runCommand("${pkgs.playerctl}/bin/playerctl stop"); else root.mediaPlayPause(); }
    onWheel: (wheel) => { if (wheel.angleDelta.y > 0) root.mediaNext(); else root.mediaPrevious(); }
    }
    }

    // Audio
    Row {
    spacing: 4
    Text {
    text: root.audioState.icon
    color: root.audioState.muted ? root.red : root.fgMid
    font.family: root.uiFont
    font.pixelSize: 12
    }
    Text {
    text: root.audioState.text
    color: root.audioState.muted ? root.red : root.fgMid
    font.family: root.uiFont
    font.pixelSize: 10
    }
    MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: (mouse) => { if (mouse.button === Qt.LeftButton) root.openAudioControl(); else root.toggleAudioMute(); }
    onWheel: (wheel) => { if (wheel.angleDelta.y > 0) root.changeAudioVolume(2); else root.changeAudioVolume(-2); }
    }
    }

    // Bluetooth
    Row {
    spacing: 4
    visible: root.bluetoothState.visible
    Text {
    text: root.bluetoothState.icon
    color: root.fgMid
    font.family: root.uiFont
    font.pixelSize: 12
    }
    Text {
    text: root.bluetoothState.text
    color: root.fgMid
    font.family: root.uiFont
    font.pixelSize: 10
    elide: Text.ElideRight
    width: 80 // Fixed width instead of maximumWidth
    }
    MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: root.openBluetoothManager()
    }
    }

    // Network
    Row {
    spacing: 4
    Text {
    text: root.networkState.icon
    color: root.networkState.connected ? root.fgMid : root.red
    font.family: root.uiFont
    font.pixelSize: 12
    }
    Text {
    text: root.networkState.text
    color: root.networkState.connected ? root.fgMid : root.red
    font.family: root.uiFont
    font.pixelSize: 10
    elide: Text.ElideRight
    width: 80 // Fixed width instead of maximumWidth
    }
    MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    }
    }

    // Battery
    Row {
    spacing: 4
    visible: root.batteryState.available
    Text {
    text: root.batteryState.icon
    color: root.batteryState.critical ? root.red : (root.batteryState.warning ? root.yellow : (root.batteryState.charging ? root.green : root.fgMid))
    font.family: root.uiFont
    font.pixelSize: 12
    }
    Text {
    text: root.batteryState.text
    color: root.batteryState.critical ? root.red : (root.batteryState.warning ? root.yellow : (root.batteryState.charging ? root.green : root.fgMid))
    font.family: root.uiFont
    font.pixelSize: 10
    }
    MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    }
    }

    // Notification Bell
    Text {
    text: "󰂚"
    color: root.fgMid
    font.family: root.uiFont
    font.pixelSize: 12
    MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: root.runCommand("qs ipc call controlpanel toggle")
    }
    }
    }
    }
    }
    }
    }
    }
  '';
}
