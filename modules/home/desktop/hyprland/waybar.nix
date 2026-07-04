{
  config,
  semanticColors,
  ...
}:
let
  c = semanticColors { colors = config.lib.stylix.colors; };
  h = semanticColors { colors = config.lib.stylix.colors; };
  hc = h.withHash;
  hyprDir = "${config.home.homeDirectory}/NixConfig/modules/home/desktop/hyprland";

  generatedCss = ''
    @define-color bg          ${hc.bg};
    @define-color bg-raised   ${hc.raisedBackground};
    @define-color bg-subtle   ${hc.bgSubtle};
    @define-color border      ${hc.border};
    @define-color fg          ${hc.fg};
    @define-color fg-dim      ${hc.fgDim};
    @define-color fg-mid      ${hc.fgMid};
    @define-color accent      ${hc.accent};
    @define-color teal        ${hc.teal};
    @define-color purple      ${hc.purple};
    @define-color green       ${hc.green};
    @define-color yellow      ${hc.yellow};
    @define-color red         ${hc.red};
    @define-color orange      ${hc.orange};

    * {
      all: unset;
      font-family: "JetBrains Mono", monospace;
      font-size: 11px;
      font-weight: 400;
      min-height: 0;
    }

    window#waybar {
      background: transparent;
      color: @fg;
    }

    window#waybar > box {
      background: @bg;
      border: 1px solid @border;
    }

    #workspaces,
    #window,
    #custom-special-workspace,
    #clock,
    #cpu,
    #memory,
    #disk,
    #mpris,
    #pulseaudio,
    #bluetooth,
    #network,
    #battery {
      background: transparent;
      color: @fg;
      padding: 0 12px;
    }

    #workspaces {
      padding: 0 2px;
      border-right: 1px solid @border;
      margin-right: 4px;
    }

    #custom-special-workspace {
      color: @fg-dim;
      padding: 0 10px;
      margin-right: 4px;
      transition: color 200ms ease, opacity 200ms ease;
    }

    #custom-special-workspace.empty {
      opacity: 0.65;
    }

    #custom-special-workspace.occupied {
      color: @yellow;
      opacity: 1;
    }

    #custom-special-workspace.active {
      color: @accent;
      opacity: 1;
    }

    #workspaces button {
      font-size: 8px;
      color: @fg-dim;
      padding: 0;
      margin: 0 3px;
      background: transparent;
      min-width: 0;
      min-height: 0;
      border-radius: 999px;
      transition: color 200ms ease;
    }

    #workspaces button.active,
    #workspaces button.urgent {
      transition: color 200ms ease;
    }

    #workspaces button.active {
      font-size: 0;
      background: @accent;
      min-width: 22px;
      min-height: 6px;
      margin: 13px 3px;
    }

    #workspaces button.urgent {
      font-size: 0;
      background: @red;
      min-width: 22px;
      min-height: 6px;
      margin: 13px 3px;
    }

    #workspaces button:hover {
      color: @fg;
    }

    #window {
      font-style: italic;
      color: @fg-dim;
      padding: 0 12px;
      margin-left: 4px;
    }

    #clock {
      font-weight: 600;
      letter-spacing: 1px;
      color: @teal;
      padding: 0 16px;
    }

    #cpu,
    #memory,
    #disk {
      color: @fg-mid;
      padding: 0 8px;
      font-feature-settings: "tnum";
      transition: color 200ms ease;
    }

    #cpu:hover,
    #memory:hover,
    #disk:hover {
      color: @fg;
    }

    #cpu.warning,
    #memory.warning,
    #disk.warning {
      color: @yellow;
    }

    #cpu.critical,
    #memory.critical,
    #disk.critical {
      color: @red;
    }

    #mpris {
      font-style: italic;
      color: @purple;
      padding: 0 12px;
      margin-right: 4px;
      border-right: 1px solid @border;
      margin-left: 4px;
      transition: color 200ms ease;
    }

    #mpris:hover {
      color: @fg;
    }

    #pulseaudio {
      color: @fg-mid;
      padding: 0 10px;
      transition: color 200ms ease;
    }

    #pulseaudio:hover {
      color: @fg;
    }

    #pulseaudio.muted {
      color: @red;
      opacity: 0.6;
    }

    #bluetooth {
      color: @fg-mid;
      padding: 0 10px;
      transition: color 200ms ease, opacity 200ms ease;
    }

    #bluetooth:hover {
      color: @fg;
    }

    #bluetooth.disabled,
    #bluetooth.off {
      opacity: 0;
      padding: 0;
      min-width: 0;
    }

    #network {
      color: @fg-mid;
      padding: 0 10px;
      transition: color 200ms ease;
      font-feature-settings: "tnum";
    }

    #network:hover {
      color: @fg;
    }

    #network.disconnected {
      color: @red;
    }

    #battery {
      color: @fg-mid;
      padding: 0 12px;
      margin-left: 4px;
      border-left: 1px solid @border;
      transition: color 200ms ease;
    }

    #battery.charging,
    #battery.plugged {
      color: @green;
    }

    #battery.warning {
      color: @yellow;
    }

    #battery.critical {
      color: @red;
    }

    #custom-idle-inhibitor {
      color: @fg-mid;
      padding: 0 10px;
      transition: color 200ms ease;
    }

    #custom-idle-inhibitor:hover {
      color: @fg;
    }

    #custom-idle-inhibitor.activated {
      color: @yellow;
    }

    #tray {
      padding: 0 8px;
      margin-left: 4px;
      border-left: 1px solid @border;
    }

    tooltip {
      background: @bg-raised;
      border: 1px solid @border;
      border-radius: 8px;
      padding: 10px 14px;
    }

    tooltip label {
      color: @fg;
    }
  '';

  generatedJsonc = builtins.toJSON {
    layer = "top";
    position = "top";
    height = 32;
    margin-top = 0;
    margin-left = 0;
    margin-right = 0;
    spacing = 0;

    "modules-left" = [
      "hyprland/workspaces"
      "custom/special-workspace"
      "hyprland/window"
    ];
    "modules-center" = [ "clock" ];
    "modules-right" = [
      "mpris"
      "cpu"
      "memory"
      "disk"
      "pulseaudio"
      "bluetooth"
      "network"
      "battery"
      "custom/idle-inhibitor"
      "tray"
    ];

    "hyprland/workspaces" = {
      format = "{icon}";
      "format-icons" = {
        active = "";
        urgent = "■";
        default = "●";
      };
      "on-click" = "activate";
      "all-outputs" = false;
      "active-first" = false;
      "sort-by-number" = true;
      persistent_workspaces = {
        "1" = [ ];
        "2" = [ ];
        "3" = [ ];
        "4" = [ ];
        "5" = [ ];
      };
    };

    "custom/special-workspace" = {
      "return-type" = "json";
      exec = "special-workspace-indicator.sh";
      interval = 2;
      format = "{}";
      "on-click" = "hyprctl dispatch 'hl.dsp.workspace.toggle_special(\"work\")'";
      tooltip = true;
    };

    "hyprland/window" = {
      format = "{initialTitle}";
      rewrite = {
        "(.*) — Mozilla Firefox" = "Firefox";
        "(.*) — Zen Browser" = "Zen";
        "(.*) - Ghostty" = "Terminal";
        "(.*) - foot" = "Terminal";
        "(.*) - Neovim" = "Neovim";
        "(.*) - Nautilus" = "Files";
      };
      "max-length" = 35;
      "separate-outputs" = true;
    };

    clock = {
      interval = 30;
      format = "{:%H:%M}";
      "format-alt" = "{:%a, %d %b  %H:%M}";
      "tooltip-format" = "<tt><small>{calendar}</small></tt>";
      calendar = {
        mode = "month";
        "mode-mon-col" = 3;
        "weeks-pos" = "right";
        "on-scroll" = 1;
        format = {
          months = "<span color='${hc.accent}'><b>{}</b></span>";
          weekdays = "<span color='${hc.teal}'><b>{}</b></span>";
          weeks = "<span color='${hc.fgDim}'><b>W{}</b></span>";
          today = "<span color='${hc.yellow}'><b>{}</b></span>";
        };
      };
    };

    cpu = {
      format = " {usage}%";
      interval = 5;
      tooltip = true;
      states = {
        warning = 70;
        critical = 90;
      };
    };

    memory = {
      format = " {}%";
      interval = 5;
      tooltip = true;
      states = {
        warning = 80;
        critical = 95;
      };
    };

    disk = {
      format = " {percentage_used}%";
      interval = 60;
      tooltip = true;
      path = "/";
      states = {
        warning = 80;
        critical = 95;
      };
    };

    mpris = {
      format = "{status_icon} {title} · {artist}";
      "format-paused" = "{status_icon} {title} · {artist}";
      "status-icons" = {
        paused = "󰏤";
        playing = "󰐊";
      };
      "tooltip-format" = "{player} - {title} · {artist}";
      "max-length" = 30;
      "on-click" = "playerctl play-pause";
      "on-scroll-up" = "playerctl next";
      "on-scroll-down" = "playerctl previous";
    };

    pulseaudio = {
      format = "{icon} {volume}%";
      "format-bluetooth" = "󰂯 {icon} {volume}%";
      "format-muted" = "󰖁";
      "tooltip-format" = "{desc} — {volume}%";
      "format-icons" = {
        headphone = "󰋋";
        headset = "󰋎";
        default = [ "󰕿" "󰖀" "󰕾" ];
      };
      "on-click" = "pavucontrol";
      "on-click-right" = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      "on-scroll-up" = "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 2%+";
      "on-scroll-down" = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-";
      "scroll-step" = 2;
    };

    bluetooth = {
      format = "󰂯";
      "format-connected" = "󰂱 {device_alias}";
      "format-disabled" = "";
      "format-off" = "";
      "on-click" = "blueman-manager";
      "tooltip-format" = "{controller_alias} — {num_connections} connected";
    };

    network = {
      interval = 1;
      "format-wifi" = "󰖩 {essid}";
      "format-ethernet" = "󰈀 {ifname} {bandwidthDownBytes}⇣ {bandwidthUpBytes}⇡";
      "format-linked" = "󰈀 {ifname} (no IP)";
      "format-disconnected" = "󰖪 Offline";
      "format-alt" = "{ifname}: {ipaddr}/{cidr}";
      "tooltip-format-wifi" = "{essid} ({signalStrength}%)\nIP: {ipaddr}  GW: {gwaddr}\n↓ {bandwidthDownBytes}  ↑ {bandwidthUpBytes}";
      "tooltip-format-ethernet" = "{ifname}\nIP: {ipaddr}  GW: {gwaddr}\n↓ {bandwidthDownBytes}  ↑ {bandwidthUpBytes}";
      "tooltip-format-disconnected" = "Network disconnected";
      "max-length" = 38;
    };

    battery = {
      interval = 10;
      states = {
        warning = 30;
        critical = 15;
      };
      format = "{icon} {capacity}%";
      "format-alt" = "{capacity}% · {timeTo}";
      "format-icons" = [
        "󰁺"
        "󰁻"
        "󰁼"
        "󰁽"
        "󰁾"
        "󰁿"
        "󰂀"
        "󰂁"
        "󰂂"
        "󰁹"
      ];
      "format-charging" = "󰂄 {capacity}%";
      "format-plugged" = "󰚥 {capacity}%";
      "tooltip-format" = "{capacity}% · {timeTo}";
    };

    "custom/idle-inhibitor" = {
      format = "{icon}";
      "format-icons" = {
        activated = "󰅶";
        deactivated = "󰾫";
      };
      "return-type" = "json";
      exec = "if systemctl --user is-active hypridle > /dev/null 2>&1; then echo '{\"text\": \"\", \"class\": \"deactivated\"}'; else echo '{\"text\": \"\", \"class\": \"activated\"}'; fi";
      "on-click" = "if systemctl --user is-active hypridle > /dev/null 2>&1; then systemctl --user stop hypridle && notify-send 'Idle' 'Inhibited'; else systemctl --user start hypridle && notify-send 'Idle' 'Re-enabled'; fi";
      interval = 5;
      tooltip = false;
    };

    tray = {
      "icon-size" = 16;
      spacing = 8;
    };
  };
in
{
  home.file."NixConfig/modules/home/desktop/hyprland/waybar/generated-style.css" = {
    text = generatedCss;
    force = true;
  };

  home.file."NixConfig/modules/home/desktop/hyprland/waybar/generated-config.jsonc" = {
    text = generatedJsonc;
    force = true;
  };

  xdg.configFile."waybar/config".source =
    config.lib.file.mkOutOfStoreSymlink "${hyprDir}/waybar/generated-config.jsonc";
  xdg.configFile."waybar/style.css".source =
    config.lib.file.mkOutOfStoreSymlink "${hyprDir}/waybar/generated-style.css";
  xdg.configFile."waybar/special-workspace-indicator.sh".source =
    config.lib.file.mkOutOfStoreSymlink "${hyprDir}/waybar/special-workspace-indicator.sh";
}
