# =============================================================================
# Quickshell Shell UI (Bar + Notifications + Control Panel)
# =============================================================================
# This module is the single source of truth for Quickshell in this repo.
# It owns:
#   1) Quickshell package enablement
#   2) Top bar UI (Waybar replacement)
#   3) Notification daemon + popup stack + control panel
# =============================================================================
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
  specialWorkspaceFullName = "special:${specialWorkspaceName}";

  # Fast workspace/window poller.
  # This is intentionally lightweight so workspace indicators update quickly.
  quickshellWorkspaceStatus = pkgs.writeShellScript "quickshell-workspace-status" ''
    set -u

    workspaces_json="$(${pkgs.hyprland}/bin/hyprctl -j workspaces 2>/dev/null || echo '[]')"
    active_workspace_json="$(${pkgs.hyprland}/bin/hyprctl -j activeworkspace 2>/dev/null || echo '{}')"
    active_window_json="$(${pkgs.hyprland}/bin/hyprctl -j activewindow 2>/dev/null || echo '{}')"

    active_workspace_id="$(printf '%s' "$active_workspace_json" | ${pkgs.jq}/bin/jq -r '.id // 0' 2>/dev/null || echo 0)"
    active_window_title="$(printf '%s' "$active_window_json" | ${pkgs.jq}/bin/jq -r '.initialTitle // .title // ""' 2>/dev/null || echo "")"
    active_window_title="$(printf '%s' "$active_window_title" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"

    case "$active_window_title" in
      *" — Mozilla Firefox") active_window_title="Firefox" ;;
      *" — Zen Browser") active_window_title="Zen" ;;
      *" - Ghostty" | *" - foot") active_window_title="Terminal" ;;
      *" - Neovim") active_window_title="Neovim" ;;
      *" - Nautilus") active_window_title="Files" ;;
    esac
    if [ -z "$active_window_title" ]; then
      active_window_title="Desktop"
    fi

    # Only include workspaces that currently exist (except special workspaces).
    # If Hyprland reports an active workspace that is not present in the list,
    # append it so active highlighting is always correct.
    workspaces_compact="$(
      printf '%s' "$workspaces_json" \
        | ${pkgs.jq}/bin/jq -c --argjson active "$active_workspace_id" '
            [
              map(select(.id > 0 and (((.name // "") | startswith("special:")) | not)) | {
                id: .id,
                windows: (.windows // 0)
              })
              | sort_by(.id)
              | unique_by(.id)
              | .[]
              | {
                id: .id,
                active: (.id == $active),
                occupied: (.windows > 0)
              }
            ] as $workspaces
            | if (($workspaces | map(.id) | index($active)) == null and $active > 0)
              then ($workspaces + [{ id: $active, active: true, occupied: false }] | sort_by(.id))
              else $workspaces
              end
          ' 2>/dev/null \
        || echo '[]'
    )"

    special_workspace="$(
      printf '%s' "$workspaces_json" \
        | ${pkgs.jq}/bin/jq -c --arg ws "${specialWorkspaceFullName}" '
            (map(select(.name == $ws)) | .[0]) as $special |
            {
              visible: ($special.visible // false),
              windows: ($special.windows // 0)
            }
          ' 2>/dev/null \
        || echo '{"visible":false,"windows":0}'
    )"

    ${pkgs.jq}/bin/jq -cn \
      --argjson workspaces "$workspaces_compact" \
      --argjson special "$special_workspace" \
      --arg windowTitle "$active_window_title" \
      '{
        workspaces: $workspaces,
        special: $special,
        windowTitle: $windowTitle
      }'
  '';

  # Slower metrics poller for modules that do not need instant updates.
  quickshellBarStatus = pkgs.writeShellScript "quickshell-bar-status" ''
    set -u
    timeout_bin="${pkgs.coreutils}/bin/timeout"
    fast_timeout="0.25s"
    medium_timeout="0.6s"

    clock_text="$(date '+%H:%M')"
    clock_tooltip="$(date '+%a, %d %b  %H:%M')"

    mpris_raw="$($timeout_bin "$fast_timeout" ${pkgs.playerctl}/bin/playerctl metadata --format '{{status}}|{{title}}|{{artist}}' 2>/dev/null || true)"
    mpris_status="Stopped"
    mpris_icon="󰓛"
    mpris_text="No media"
    if [ -n "$mpris_raw" ]; then
      IFS='|' read -r parsed_status parsed_title parsed_artist <<EOF
$mpris_raw
EOF
      if [ -n "''${parsed_status:-}" ]; then
        mpris_status="$parsed_status"
      fi

      case "$mpris_status" in
        Playing) mpris_icon="󰐊" ;;
        Paused) mpris_icon="󰏤" ;;
        *) mpris_icon="󰓛" ;;
      esac

      if [ -n "''${parsed_title:-}" ] && [ -n "''${parsed_artist:-}" ]; then
        mpris_text="$parsed_title · $parsed_artist"
      elif [ -n "''${parsed_title:-}" ]; then
        mpris_text="$parsed_title"
      fi
    fi
    mpris_text="$(printf '%s' "$mpris_text" | cut -c1-44)"

    audio_raw="$($timeout_bin "$fast_timeout" ${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)"
    audio_muted=false
    audio_percent=0
    if [ -n "$audio_raw" ]; then
      volume_float="$(printf '%s' "$audio_raw" | ${pkgs.gawk}/bin/awk '{print $2}')"
      if [ -n "$volume_float" ]; then
        audio_percent="$(${pkgs.gawk}/bin/awk -v v="$volume_float" 'BEGIN { printf "%d", (v * 100) + 0.5 }')"
      fi
      if printf '%s' "$audio_raw" | grep -q '\[MUTED\]'; then
        audio_muted=true
      fi
    fi

    audio_icon="󰕾"
    if [ "$audio_muted" = true ]; then
      audio_icon="󰖁"
    elif [ "$audio_percent" -le 0 ]; then
      audio_icon="󰕿"
    elif [ "$audio_percent" -le 35 ]; then
      audio_icon="󰖀"
    fi
    audio_text="$audio_percent%"

    bt_visible=false
    bt_icon="󰂲"
    bt_text=""
    if [ -x "${pkgs.bluez}/bin/bluetoothctl" ]; then
      bt_connected="$($timeout_bin "$fast_timeout" ${pkgs.bluez}/bin/bluetoothctl devices Connected 2>/dev/null | sed -n '1s/^Device [^ ]* //p')"
      if $timeout_bin "$fast_timeout" ${pkgs.bluez}/bin/bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then
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
      net_line="$($timeout_bin "$medium_timeout" ${pkgs.networkmanager}/bin/nmcli -t -f TYPE,STATE,CONNECTION dev status 2>/dev/null | ${pkgs.gawk}/bin/awk -F: '$2 == "connected" { print; exit }')"
      if [ -n "$net_line" ]; then
        net_connected=true
        net_type="''${net_line%%:*}"
        net_tmp="''${net_line#*:}"
        net_name="''${net_tmp#*:}"

        case "$net_type" in
          wifi)
            net_icon="󰖩"
            net_text="''${net_name:-Wi-Fi}"
            ;;
          ethernet)
            net_icon="󰈀"
            net_text="''${net_name:-Ethernet}"
            ;;
          *)
            net_icon="󰈀"
            net_text="''${net_name:-Connected}"
            ;;
        esac
      fi
    fi
    net_text="$(printf '%s' "$net_text" | cut -c1-28)"

    battery_available=false
    battery_icon="󰁹"
    battery_text=""
    battery_charging=false
    battery_warning=false
    battery_critical=false
    battery_percent=0

    battery_dir="$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1 || true)"
    if [ -n "$battery_dir" ]; then
      battery_available=true
      if [ -f "$battery_dir/capacity" ]; then
        battery_percent="$(cat "$battery_dir/capacity" 2>/dev/null || echo 0)"
      fi
      battery_status="$(cat "$battery_dir/status" 2>/dev/null || echo Unknown)"

      if [ "$battery_percent" -le 15 ]; then
        battery_icon="󰂃"
        battery_critical=true
      elif [ "$battery_percent" -le 30 ]; then
        battery_icon="󰂀"
        battery_warning=true
      elif [ "$battery_percent" -le 50 ]; then
        battery_icon="󰁿"
      elif [ "$battery_percent" -le 70 ]; then
        battery_icon="󰁾"
      elif [ "$battery_percent" -le 90 ]; then
        battery_icon="󰂂"
      else
        battery_icon="󰁹"
      fi

      if [ "$battery_status" = Charging ] || [ "$battery_status" = Full ]; then
        battery_charging=true
        battery_icon="󰂄"
      fi

      battery_text="$battery_percent%"
    fi

    ${pkgs.jq}/bin/jq -cn \
      --arg clock "$clock_text" \
      --arg clockTooltip "$clock_tooltip" \
      --arg mprisStatus "$mpris_status" \
      --arg mprisIcon "$mpris_icon" \
      --arg mprisText "$mpris_text" \
      --arg audioIcon "$audio_icon" \
      --arg audioText "$audio_text" \
      --argjson audioMuted "$audio_muted" \
      --arg btIcon "$bt_icon" \
      --arg btText "$bt_text" \
      --argjson btVisible "$bt_visible" \
      --arg netIcon "$net_icon" \
      --arg netText "$net_text" \
      --argjson netConnected "$net_connected" \
      --arg batteryIcon "$battery_icon" \
      --arg batteryText "$battery_text" \
      --argjson batteryAvailable "$battery_available" \
      --argjson batteryCharging "$battery_charging" \
      --argjson batteryWarning "$battery_warning" \
      --argjson batteryCritical "$battery_critical" \
      '{
        clock: $clock,
        clockTooltip: $clockTooltip,
        mpris: {
          status: $mprisStatus,
          icon: $mprisIcon,
          text: $mprisText
        },
        audio: {
          icon: $audioIcon,
          text: $audioText,
          muted: $audioMuted
        },
        bluetooth: {
          icon: $btIcon,
          text: $btText,
          visible: $btVisible
        },
        network: {
          icon: $netIcon,
          text: $netText,
          connected: $netConnected
        },
        battery: {
          icon: $batteryIcon,
          text: $batteryText,
          available: $batteryAvailable,
          charging: $batteryCharging,
          warning: $batteryWarning,
          critical: $batteryCritical
        }
      }'
  '';
in
{
  programs.quickshell = {
    enable = true;
    package = pkgs.unstable.quickshell;
  };

  # Ensure qmlls and other QML tooling can resolve Quickshell imports.
  home.sessionVariables.QML2_IMPORT_PATH = "${pkgs.unstable.quickshell}/lib/qt-6/qml";

  xdg.configFile."quickshell/shell.qml".text = ''
    import Quickshell
    import Quickshell.Io
    import Quickshell.Services.Notifications
    import QtQuick
    import QtQuick.Layouts
    import QtQml

    ShellRoot {
      id: root

      // ---------------------------------------------------------------------
      // Shared state
      // ---------------------------------------------------------------------
      // `barVisible` is toggled by the focus-mode script through IPC.
      property bool barVisible: true

      // Notification state
      property bool controlPanelVisible: false
      property bool doNotDisturb: false
      property int popupTimeoutMs: 6000
      property int maxPopups: 5
      property string uiFont: "JetBrains Mono"

      // Latest bar data snapshot (polled via the shell script).
      property var barState: ({
        workspaces: [],
        special: { visible: false, windows: 0 },
        windowTitle: "Desktop",
        clock: "--:--",
        clockTooltip: "",
        mpris: { status: "Stopped", icon: "󰓛", text: "No media" },
        audio: { icon: "󰕾", text: "0%", muted: false },
        bluetooth: { icon: "󰂲", text: "", visible: false },
        network: { icon: "󰖪", text: "Offline", connected: false },
        battery: {
          icon: "󰁹",
          text: "",
          available: false,
          charging: false,
          warning: false,
          critical: false
        }
      })

      // ---------------------------------------------------------------------
      // Theme palette from Stylix semantic colors
      // ---------------------------------------------------------------------
      readonly property color bg: "${c.bg}"
      readonly property color bgRaised: "${c.bgRaised}"
      readonly property color bgSubtle: "${c.bgSubtle}"
      readonly property color border: "${c.border}"
      readonly property color fg: "${c.fg}"
      readonly property color fgMid: "${c.fgMid}"
      readonly property color fgDim: "${c.fgDim}"
      readonly property color accent: "${c.accent}"
      readonly property color yellow: "${c.yellow}"
      readonly property color teal: "${c.teal}"
      readonly property color purple: "${c.purple}"
      readonly property color red: "${c.red}"
      readonly property color green: "${c.green}"

      // ---------------------------------------------------------------------
      // Process helper
      // ---------------------------------------------------------------------
      // Used for click/scroll actions on bar widgets so we do not duplicate
      // one-off Process objects all over the UI.
      function runCommand(commandLine) {
        commandRunner.command = ["${pkgs.bash}/bin/bash", "-lc", commandLine];
        commandRunner.running = false;
        commandRunner.running = true;
      }

      function updateBarState(changes) {
        root.barState = Object.assign({}, root.barState, changes);
      }

      function setActiveWorkspaceLocally(workspaceId) {
        const currentWorkspaces = root.barState.workspaces || [];
        if (!currentWorkspaces || currentWorkspaces.length === 0) return;

        const updatedWorkspaces = currentWorkspaces.map((workspace) => ({
          id: workspace.id,
          active: workspace.id === workspaceId,
          occupied: workspace.occupied
        }));

        root.updateBarState({ workspaces: updatedWorkspaces });
      }

      function requestWorkspaceRefresh() {
        if (!workspacePoll.running) {
          workspacePoll.running = true;
        }
      }

      Process {
        id: commandRunner
        command: ["${pkgs.bash}/bin/bash", "-lc", "true"]
        running: false
      }

      // ---------------------------------------------------------------------
      // Bar polling
      // ---------------------------------------------------------------------
      Process {
        id: workspacePoll
        command: [ "${quickshellWorkspaceStatus}" ]
        running: false
        stdout: StdioCollector {
          onStreamFinished: {
            const payload = this.text.trim();
            if (!payload || payload.length === 0) return;

            try {
              const parsed = JSON.parse(payload);
              root.updateBarState({
                workspaces: Array.isArray(parsed.workspaces) ? parsed.workspaces : root.barState.workspaces,
                special: parsed.special || root.barState.special,
                windowTitle: parsed.windowTitle || root.barState.windowTitle
              });
            } catch (error) {
              console.log("Failed to parse quickshell workspace payload: " + error);
            }
          }
        }
      }

      Timer {
        id: workspacePollTimer
        interval: 120
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
          if (!workspacePoll.running) {
            workspacePoll.running = true;
          }
        }
      }

      Process {
        id: barPoll
        command: [ "${quickshellBarStatus}" ]
        running: false
        stdout: StdioCollector {
          onStreamFinished: {
            const payload = this.text.trim();
            if (!payload || payload.length === 0) return;

            try {
              const parsed = JSON.parse(payload);
              root.updateBarState({
                clock: parsed.clock || root.barState.clock,
                clockTooltip: parsed.clockTooltip || root.barState.clockTooltip,
                mpris: parsed.mpris || root.barState.mpris,
                audio: parsed.audio || root.barState.audio,
                bluetooth: parsed.bluetooth || root.barState.bluetooth,
                network: parsed.network || root.barState.network,
                battery: parsed.battery || root.barState.battery
              });
            } catch (error) {
              console.log("Failed to parse quickshell bar payload: " + error);
            }
          }
        }
      }

      Timer {
        id: barPollTimer
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
          if (!barPoll.running) {
            barPoll.running = true;
          }
        }
      }

      // ---------------------------------------------------------------------
      // IPC surface
      // ---------------------------------------------------------------------
      IpcHandler {
        target: "bar"

        function toggle(): void {
          root.barVisible = !root.barVisible;
        }

        function show(): void {
          root.barVisible = true;
        }

        function hide(): void {
          root.barVisible = false;
        }
      }

      IpcHandler {
        target: "controlpanel"

        function toggle(): void {
          root.controlPanelVisible = !root.controlPanelVisible;
        }

        function show(): void {
          root.controlPanelVisible = true;
        }

        function hide(): void {
          root.controlPanelVisible = false;
        }

        function toggleDnd(): void {
          root.doNotDisturb = !root.doNotDisturb;
        }
      }

      // ---------------------------------------------------------------------
      // Top bar (Waybar replacement)
      // ---------------------------------------------------------------------
      PanelWindow {
        id: topBar
        visible: root.barVisible
        focusable: false
        aboveWindows: true
        exclusionMode: ExclusionMode.Auto
        color: "transparent"
        implicitHeight: 32

        anchors {
          top: true
          left: true
          right: true
        }

        margins {
          top: 8
          left: 16
          right: 16
        }

        Rectangle {
          anchors.fill: parent
          radius: 8
          color: root.bg
          border.width: 1
          border.color: root.border

          // Subtle inner outline to match Waybar's framed look.
          Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 7
            color: "transparent"
            border.width: 1
            border.color: root.bgSubtle
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            // Left: workspaces + special workspace indicator + active window
            Item {
              id: leftSlot
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
              implicitHeight: 24
              clip: true

              Row {
                id: leftRow
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Row {
                  id: workspaceCluster
                  spacing: 6

                  Repeater {
                    model: root.barState.workspaces || []

                    Rectangle {
                      required property var modelData

                      width: 24
                      height: 22
                      radius: 4
                      color: modelData.active ? root.bgSubtle : "transparent"
                      border.width: modelData.active ? 1 : 0
                      border.color: root.border

                      Text {
                        anchors.centerIn: parent
                        text: modelData.id
                        color: modelData.active
                          ? root.accent
                          : (modelData.occupied ? root.fg : root.fgDim)
                        font.family: root.uiFont
                        font.pixelSize: 10
                        font.bold: modelData.active
                      }

                      MouseArea {
                        anchors.fill: parent
                        onClicked: {
                          root.setActiveWorkspaceLocally(modelData.id);
                          root.runCommand("${pkgs.hyprland}/bin/hyprctl dispatch workspace " + modelData.id);
                          root.requestWorkspaceRefresh();
                        }
                      }
                    }
                  }

                  Rectangle {
                    id: specialWorkspaceBadge
                    property bool specialVisible: root.barState.special && root.barState.special.visible
                    property int specialWindows: root.barState.special ? root.barState.special.windows : 0

                    width: 54
                    height: 22
                    radius: 4
                    color: "transparent"
                    border.width: specialVisible ? 1 : 0
                    border.color: root.border

                    Text {
                      anchors.centerIn: parent
                      text: specialWorkspaceBadge.specialVisible || specialWorkspaceBadge.specialWindows > 0
                        ? "󱂬 " + specialWorkspaceBadge.specialWindows
                        : "󱂬"
                      color: specialWorkspaceBadge.specialVisible
                        ? root.accent
                        : (specialWorkspaceBadge.specialWindows > 0 ? root.yellow : root.fgDim)
                      font.family: root.uiFont
                      font.pixelSize: 10
                      font.bold: specialWorkspaceBadge.specialVisible
                    }

                    MouseArea {
                      anchors.fill: parent
                      onClicked: {
                        root.runCommand("${pkgs.hyprland}/bin/hyprctl dispatch togglespecialworkspace ${specialWorkspaceName}");
                        root.requestWorkspaceRefresh();
                      }
                    }
                  }
                }

                Rectangle {
                  width: 1
                  height: 16
                  color: root.border
                }

                Text {
                  width: Math.max(120, leftSlot.width - workspaceCluster.width - 24)
                  height: 22
                  text: root.barState.windowTitle || "Desktop"
                  color: root.fgDim
                  font.family: root.uiFont
                  font.pixelSize: 11
                  font.italic: true
                  elide: Text.ElideRight
                  horizontalAlignment: Text.AlignLeft
                  verticalAlignment: Text.AlignVCenter
                }
              }
            }

            // Center: clock
            Item {
              Layout.preferredWidth: 96
              Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
              implicitHeight: 24

              Text {
                anchors.centerIn: parent
                text: root.barState.clock || "--:--"
                color: root.teal
                font.family: root.uiFont
                font.pixelSize: 12
                font.bold: true
              }
            }

            // Right: media + audio + bluetooth + network + battery
            Item {
              id: rightSlot
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
              implicitHeight: 24
              clip: true

              Row {
                id: rightRow
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Rectangle {
                  width: Math.max(100, Math.min(260, mprisLabel.implicitWidth + 4))
                  height: 22
                  color: "transparent"

                  Text {
                    id: mprisLabel
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: (root.barState.mpris ? root.barState.mpris.icon : "󰓛")
                      + " "
                      + (root.barState.mpris ? root.barState.mpris.text : "No media")
                    color: root.purple
                    font.family: root.uiFont
                    font.pixelSize: 11
                    font.italic: true
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                  }

                  MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: root.runCommand("${pkgs.playerctl}/bin/playerctl play-pause")
                    onWheel: (wheel) => {
                      if (wheel.angleDelta.y > 0)
                        root.runCommand("${pkgs.playerctl}/bin/playerctl next");
                      else
                        root.runCommand("${pkgs.playerctl}/bin/playerctl previous");
                    }
                  }
                }

                Rectangle {
                  width: 1
                  height: 16
                  color: root.border
                }

                Rectangle {
                  width: audioLabel.implicitWidth
                  height: 22
                  color: "transparent"

                  Text {
                    id: audioLabel
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: (root.barState.audio ? root.barState.audio.icon : "󰕾")
                      + " "
                      + (root.barState.audio ? root.barState.audio.text : "0%")
                    color: root.barState.audio && root.barState.audio.muted ? root.red : root.fgMid
                    font.family: root.uiFont
                    font.pixelSize: 11
                    verticalAlignment: Text.AlignVCenter
                  }

                  MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                      if (mouse.button === Qt.LeftButton)
                        root.runCommand("${pkgs.pavucontrol}/bin/pavucontrol");
                      else
                        root.runCommand("${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle");
                    }
                    onWheel: (wheel) => {
                      if (wheel.angleDelta.y > 0)
                        root.runCommand("${pkgs.wireplumber}/bin/wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 2%+");
                      else
                        root.runCommand("${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-");
                    }
                  }
                }

                Rectangle {
                  visible: root.barState.bluetooth && root.barState.bluetooth.visible
                  width: visible ? 1 : 0
                  height: 16
                  color: root.border
                }

                Rectangle {
                  visible: root.barState.bluetooth && root.barState.bluetooth.visible
                  width: visible ? Math.min(180, bluetoothLabel.implicitWidth + 2) : 0
                  height: 22
                  color: "transparent"

                  Text {
                    id: bluetoothLabel
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: (root.barState.bluetooth ? root.barState.bluetooth.icon : "󰂲")
                      + " "
                      + (root.barState.bluetooth ? root.barState.bluetooth.text : "")
                    color: root.fgMid
                    font.family: root.uiFont
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                  }

                  MouseArea {
                    anchors.fill: parent
                    onClicked: root.runCommand("${pkgs.blueman}/bin/blueman-manager")
                  }
                }

                Rectangle {
                  width: 1
                  height: 16
                  color: root.border
                }

                Rectangle {
                  width: Math.min(190, networkLabel.implicitWidth + 2)
                  height: 22
                  color: "transparent"

                  Text {
                    id: networkLabel
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: (root.barState.network ? root.barState.network.icon : "󰖪")
                      + " "
                      + (root.barState.network ? root.barState.network.text : "Offline")
                    color: root.barState.network && root.barState.network.connected ? root.fgMid : root.red
                    font.family: root.uiFont
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                  }
                }

                Rectangle {
                  visible: root.barState.battery && root.barState.battery.available
                  width: visible ? 1 : 0
                  height: 16
                  color: root.border
                }

                Rectangle {
                  visible: root.barState.battery && root.barState.battery.available
                  width: visible ? batteryLabel.implicitWidth : 0
                  height: 22
                  color: "transparent"

                  Text {
                    id: batteryLabel
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: (root.barState.battery ? root.barState.battery.icon : "󰁹")
                      + " "
                      + (root.barState.battery ? root.barState.battery.text : "")
                    color: root.barState.battery && root.barState.battery.critical
                      ? root.red
                      : (root.barState.battery && root.barState.battery.warning
                        ? root.yellow
                        : (root.barState.battery && root.barState.battery.charging ? root.green : root.fgMid))
                    font.family: root.uiFont
                    font.pixelSize: 11
                    verticalAlignment: Text.AlignVCenter
                  }
                }
              }
            }
          }
        }
      }

      // ---------------------------------------------------------------------
      // Notification system (daemon + popups + control panel)
      // ---------------------------------------------------------------------
      function stripMarkup(text) {
        if (!text || text.length === 0) return "";
        return text.replace(/<[^>]*>/g, "");
      }

      function urgencyColor(notification) {
        if (!notification) return root.accent;
        if (notification.urgency === NotificationUrgency.Critical) return root.red;
        if (notification.urgency === NotificationUrgency.Low) return root.fgDim;
        if (notification.urgency === NotificationUrgency.Normal) return root.accent;
        return root.yellow;
      }

      function appIconSource(notification) {
        if (!notification) return "";
        if (notification.image && notification.image.length > 0) return notification.image;
        if (!notification.appIcon || notification.appIcon.length === 0) return "";
        if (notification.appIcon.startsWith("/")) return "file://" + notification.appIcon;
        return "image://icon/" + notification.appIcon;
      }

      function popupTimeoutFor(notification) {
        if (!notification) return root.popupTimeoutMs;
        if (notification.urgency === NotificationUrgency.Critical) return 0;

        if (notification.expireTimeout > 0) {
          const ms = Math.round(notification.expireTimeout * 1000);
          return Math.max(2500, Math.min(15000, ms));
        }

        if (notification.urgency === NotificationUrgency.Low) return 3500;
        return root.popupTimeoutMs;
      }

      function removePopup(notification) {
        popupModel.values = popupModel.values.filter((candidate) => candidate !== notification);
      }

      function addPopup(notification) {
        if (!notification) return;

        const deduped = popupModel.values.filter(
          (candidate) => candidate && candidate.id !== notification.id
        );

        deduped.unshift(notification);
        popupModel.values = deduped.slice(0, root.maxPopups);

        notification.closed.connect(() => {
          root.removePopup(notification);
        });
      }

      function clearNotifications() {
        const notifications = [...notificationServer.trackedNotifications.values];
        for (let i = 0; i < notifications.length; i++) {
          notifications[i].dismiss();
        }
      }

      onDoNotDisturbChanged: {
        if (doNotDisturb) popupModel.values = [];
      }

      ScriptModel {
        id: popupModel
        values: []
      }

      NotificationServer {
        id: notificationServer
        keepOnReload: true

        actionsSupported: true
        actionIconsSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        imageSupported: true
        bodyImagesSupported: false
        persistenceSupported: true

        onNotification: (notification) => {
          notification.tracked = true;
          if (notification.lastGeneration) return;

          if (root.doNotDisturb && notification.urgency !== NotificationUrgency.Critical) return;
          root.addPopup(notification);
        }
      }

      PanelWindow {
        visible: popupModel.values.length > 0
        focusable: false
        aboveWindows: true
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        anchors {
          top: true
          right: true
        }

        margins {
          top: 56
          right: 24
        }

        width: 520
        height: popupColumn.implicitHeight

        Rectangle {
          anchors.fill: parent
          color: "transparent"

          Column {
            id: popupColumn
            width: parent.width
            spacing: 10

            Repeater {
              model: popupModel

              Rectangle {
                property var notification: modelData

                width: popupColumn.width
                implicitHeight: popupContent.implicitHeight + 20
                height: implicitHeight
                radius: 8
                color: root.bgRaised
                border.width: 1
                border.color: root.border

                Rectangle {
                  anchors.left: parent.left
                  anchors.top: parent.top
                  anchors.bottom: parent.bottom
                  width: 4
                  radius: 4
                  color: root.urgencyColor(notification)
                }

                Column {
                  id: popupContent
                  x: 14
                  y: 10
                  width: parent.width - 28
                  spacing: 6

                  Row {
                    width: parent.width
                    spacing: 8

                    Item {
                      width: 24
                      height: 24

                      Image {
                        id: popupIcon
                        anchors.fill: parent
                        source: root.appIconSource(notification)
                        fillMode: Image.PreserveAspectFit
                        visible: status === Image.Ready
                      }

                      Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: root.bgSubtle
                        border.width: 1
                        border.color: root.border
                        visible: !popupIcon.visible

                        Text {
                          anchors.centerIn: parent
                          text: notification && notification.appName && notification.appName.length > 0
                            ? notification.appName[0].toUpperCase()
                            : "N"
                          color: root.teal
                          font.family: root.uiFont
                          font.pixelSize: 11
                          font.bold: true
                        }
                      }
                    }

                    Text {
                      text: notification && notification.appName && notification.appName.length > 0
                        ? notification.appName
                        : "Notification"
                      color: root.accent
                      font.family: root.uiFont
                      font.pixelSize: 11
                      font.bold: true
                      elide: Text.ElideRight
                      width: Math.max(0, parent.width - closePopup.width - parent.spacing - 24)
                    }

                    Rectangle {
                      id: closePopup
                      width: 22
                      height: 22
                      radius: 4
                      color: "transparent"
                      border.width: 1
                      border.color: root.border

                      Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: root.fgDim
                        font.family: root.uiFont
                        font.pixelSize: 13
                        font.bold: true
                      }

                      MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: closePopup.color = root.bgSubtle
                        onExited: closePopup.color = "transparent"
                        onClicked: root.removePopup(notification)
                      }
                    }
                  }

                  Text {
                    text: notification && notification.summary && notification.summary.length > 0
                      ? root.stripMarkup(notification.summary)
                      : (notification && notification.appName && notification.appName.length > 0 ? notification.appName : "Notification")
                    width: parent.width
                    color: root.fg
                    font.family: root.uiFont
                    font.pixelSize: 13
                    font.bold: true
                    wrapMode: Text.Wrap
                    textFormat: Text.PlainText
                    visible: text.length > 0
                  }

                  Text {
                    text: notification ? root.stripMarkup(notification.body || "") : ""
                    width: parent.width
                    color: root.fgMid
                    font.family: root.uiFont
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    textFormat: Text.PlainText
                    visible: text.length > 0
                  }

                  Row {
                    width: parent.width
                    spacing: 6
                    visible: notification && notification.actions && notification.actions.length > 0

                    Repeater {
                      model: notification && notification.actions ? notification.actions : []

                      Rectangle {
                        required property QtObject modelData

                        height: 26
                        radius: 6
                        color: "transparent"
                        border.width: 1
                        border.color: root.border
                        width: actionText.implicitWidth + 20

                        Text {
                          id: actionText
                          anchors.centerIn: parent
                          text: modelData.text
                          color: root.fgMid
                          font.family: root.uiFont
                          font.pixelSize: 11
                          textFormat: Text.PlainText
                        }

                        MouseArea {
                          anchors.fill: parent
                          hoverEnabled: true
                          onEntered: parent.color = root.bgSubtle
                          onExited: parent.color = "transparent"
                          onClicked: {
                            modelData.invoke();
                            root.removePopup(notification);
                          }
                        }
                      }
                    }
                  }
                }

                Timer {
                  id: popupTimer
                  interval: root.popupTimeoutFor(notification)
                  running: interval > 0 && !popupHover.hovered
                  repeat: false
                  onTriggered: {
                    if (notification) notification.expire();
                    root.removePopup(notification);
                  }
                }

                HoverHandler {
                  id: popupHover
                }

                Connections {
                  target: notification

                  function onClosed(reason) {
                    root.removePopup(notification);
                  }
                }
              }
            }
          }
        }
      }

      PanelWindow {
        visible: root.controlPanelVisible
        focusable: true
        aboveWindows: true

        anchors {
          top: true
          right: true
        }

        margins {
          top: 56
          right: 24
        }

        width: 520
        height: 640

        Rectangle {
          anchors.fill: parent
          radius: 8
          color: root.bgRaised
          border.width: 1
          border.color: root.border

          Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Row {
              width: parent.width
              spacing: 8

              Text {
                text: "Notifications"
                color: root.fg
                font.family: root.uiFont
                font.pixelSize: 14
                font.bold: true
                width: parent.width - closePanel.width - parent.spacing
                verticalAlignment: Text.AlignVCenter
              }

              Rectangle {
                id: closePanel
                width: 26
                height: 26
                radius: 6
                color: "transparent"
                border.width: 1
                border.color: root.border

                Text {
                  anchors.centerIn: parent
                  text: "×"
                  color: root.fgDim
                  font.family: root.uiFont
                  font.pixelSize: 14
                  font.bold: true
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  onEntered: closePanel.color = root.bgSubtle
                  onExited: closePanel.color = "transparent"
                  onClicked: root.controlPanelVisible = false
                }
              }
            }

            Row {
              width: parent.width
              spacing: 8

              Rectangle {
                id: dndToggle
                width: 210
                height: 30
                radius: 6
                color: root.doNotDisturb ? root.accent : root.bgSubtle
                border.width: 1
                border.color: root.doNotDisturb ? root.accent : root.border

                Text {
                  anchors.centerIn: parent
                  text: root.doNotDisturb ? "DND: ON" : "DND: OFF"
                  color: root.doNotDisturb ? root.bg : root.fg
                  font.family: root.uiFont
                  font.pixelSize: 11
                  font.bold: true
                }

                MouseArea {
                  anchors.fill: parent
                  onClicked: root.doNotDisturb = !root.doNotDisturb
                }
              }

              Rectangle {
                id: clearAll
                width: 138
                height: 30
                radius: 6
                color: "transparent"
                border.width: 1
                border.color: root.border

                Text {
                  anchors.centerIn: parent
                  text: "Clear All (" + notificationServer.trackedNotifications.count + ")"
                  color: root.fgMid
                  font.family: root.uiFont
                  font.pixelSize: 11
                  font.bold: true
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  onEntered: clearAll.color = root.bgSubtle
                  onExited: clearAll.color = "transparent"
                  onClicked: root.clearNotifications()
                }
              }
            }

            Text {
              width: parent.width
              text: root.doNotDisturb
                ? "Do Not Disturb is enabled. Critical alerts still appear."
                : "Popup timeout adapts to notification urgency and app timeout hints."
              color: root.fgDim
              font.family: root.uiFont
              font.pixelSize: 11
              wrapMode: Text.Wrap
            }

            Rectangle {
              width: parent.width
              height: 1
              color: root.border
            }

            ListView {
              id: notificationList
              width: parent.width
              height: parent.height - 110
              spacing: 10
              clip: true
              model: notificationServer.trackedNotifications

              delegate: Rectangle {
                required property QtObject modelData

                width: notificationList.width
                implicitHeight: notificationContent.implicitHeight + 24
                height: implicitHeight
                radius: 8
                color: root.bgSubtle
                border.width: 1
                border.color: modelData.urgency === NotificationUrgency.Critical ? root.red : root.border

                property QtObject notification: modelData

                Column {
                  id: notificationContent
                  x: 14
                  y: 10
                  width: parent.width - 28
                  spacing: 6

                  Row {
                    width: parent.width
                    spacing: 8

                    Item {
                      width: 24
                      height: 24

                      Image {
                        id: panelIcon
                        anchors.fill: parent
                        source: root.appIconSource(notification)
                        fillMode: Image.PreserveAspectFit
                        visible: status === Image.Ready
                      }

                      Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: root.bgRaised
                        border.width: 1
                        border.color: root.border
                        visible: !panelIcon.visible

                        Text {
                          anchors.centerIn: parent
                          text: notification && notification.appName && notification.appName.length > 0
                            ? notification.appName[0].toUpperCase()
                            : "N"
                          color: root.teal
                          font.family: root.uiFont
                          font.pixelSize: 11
                          font.bold: true
                        }
                      }
                    }

                    Text {
                      text: notification.appName && notification.appName.length > 0 ? notification.appName : "Notification"
                      color: root.accent
                      font.family: root.uiFont
                      font.pixelSize: 11
                      font.bold: true
                      elide: Text.ElideRight
                      width: Math.max(0, parent.width - dismissButton.width - parent.spacing - 24)
                    }

                    Rectangle {
                      id: dismissButton
                      width: 22
                      height: 22
                      radius: 4
                      color: "transparent"
                      border.width: 1
                      border.color: root.border

                      Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: root.fgDim
                        font.family: root.uiFont
                        font.pixelSize: 13
                        font.bold: true
                      }

                      MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: dismissButton.color = root.bgRaised
                        onExited: dismissButton.color = "transparent"
                        onClicked: notification.dismiss()
                      }
                    }
                  }

                  Text {
                    text: root.stripMarkup(notification.summary || "")
                    width: parent.width
                    color: root.fg
                    font.family: root.uiFont
                    font.pixelSize: 13
                    font.bold: true
                    wrapMode: Text.Wrap
                    textFormat: Text.PlainText
                    visible: text.length > 0
                  }

                  Text {
                    text: root.stripMarkup(notification.body || "")
                    width: parent.width
                    color: root.fgMid
                    font.family: root.uiFont
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    textFormat: Text.PlainText
                    visible: text.length > 0
                  }

                  Row {
                    width: parent.width
                    spacing: 6
                    visible: actionButtons.count > 0

                    Repeater {
                      id: actionButtons
                      model: notification.actions

                      Rectangle {
                        required property QtObject modelData

                        height: 26
                        radius: 6
                        color: "transparent"
                        border.width: 1
                        border.color: root.border
                        width: actionLabel.implicitWidth + 20

                        Text {
                          id: actionLabel
                          anchors.centerIn: parent
                          text: modelData.text
                          color: root.fgMid
                          font.family: root.uiFont
                          font.pixelSize: 11
                          textFormat: Text.PlainText
                        }

                        MouseArea {
                          anchors.fill: parent
                          hoverEnabled: true
                          onEntered: parent.color = root.bgRaised
                          onExited: parent.color = "transparent"
                          onClicked: modelData.invoke()
                        }
                      }
                    }
                  }
                }
              }

              Rectangle {
                anchors.centerIn: parent
                color: "transparent"
                visible: notificationList.count === 0

                Text {
                  text: "No notifications"
                  color: root.fgDim
                  font.family: root.uiFont
                  font.pixelSize: 12
                }
              }
            }
          }
        }
      }
    }
  '';
}
