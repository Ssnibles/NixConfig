# =============================================================================
# Waybar Configuration
# =============================================================================
# Top status bar for Hyprland.
# =============================================================================
{ ... }:
{
  programs.waybar = {
    enable = true;
    settings.main = {
      layer = "top";
      position = "top";
      height = 32;
      margin-top = 8;
      margin-left = 16;
      margin-right = 16;
      spacing = 0;

      modules-left = [
        "hyprland/workspaces"
        "hyprland/window"
      ];
      modules-center = [ "clock" ];
      modules-right = [
        "mpris"
        "pulseaudio"
        "bluetooth"
        "network"
        "battery"
      ];

      "hyprland/workspaces" = {
        format = "{name}";
        on-click = "activate";
        all-outputs = false;
      };

      "hyprland/window" = {
        format = "{initialTitle}";
        rewrite = {
          "(.*) — Mozilla Firefox" = "Firefox";
          "(.*) — Zen Browser" = "Zen";
          "(.*) - Ghostty" = "Terminal";
          "(.*) - Neovim" = "Neovim";
          "(.*) - Nautilus" = "Files";
        };
        max-length = 35;
        separate-outputs = true;
      };

      "clock" = {
        format = "{:%H:%M}";
        format-alt = "{:%A, %d %B}";
        tooltip-format = "<tt><small>{calendar}</small></tt>";
      };

      "mpris" = {
        format = "{dynamic}";
        dynamic-len = 28;
        dynamic-order = [
          "title"
          "artist"
        ];
        player-icons = {
          default = "";
          spotify = "";
          "spotify-player" = "";
        };
        status-icons = {
          paused = "";
          playing = "";
        };
        on-click = "playerctl play-pause";
        on-scroll-up = "playerctl next";
        on-scroll-down = "playerctl previous";
      };

      "pulseaudio" = {
        format = "{icon} {volume}%";
        format-muted = "󰖁";
        format-icons = {
          headphone = "󰋋";
          headset = "󰋎";
          default = [
            "󰕿"
            "󰖀"
            "󰕾"
          ];
        };
        on-click = "pavucontrol";
        scroll-step = 2;
      };

      "bluetooth" = {
        format = "󰂯";
        format-connected = "󰂱 {device_alias}";
        format-disabled = "";
        format-off = "";
        on-click = "blueman-manager";
        tooltip-format = "{controller_alias} — {num_connections} connected";
      };

      "network" = {
        format-wifi = "󰖩 {essid}";
        format-ethernet = "󰈀";
        format-disconnected = "󰖪";
        tooltip-format-wifi = "{signalStrength}%  ·  {ipaddr}";
        max-length = 16;
      };

      "battery" = {
        states = {
          warning = 30;
          critical = 15;
        };
        format = "{icon} {capacity}%";
        format-icons = [
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
        format-charging = "󰂄 {capacity}%";
        format-plugged = "󰚥 {capacity}%";
        tooltip-format = "{timeTo}";
      };
    };

    style = ''
      /* =================================================================== */
      /* Waybar Vague Theme                                                  */
      /* Consistent color palette matching neovim, swaync, and hyprland     */
      /* =================================================================== */

      @define-color bg          #141415;
      @define-color bg-raised   #1c1c24;
      @define-color bg-subtle   #252530;
      @define-color border      #252530;
      @define-color fg          #cdcdcd;
      @define-color fg-dim      #606079;
      @define-color fg-mid      #878787;
      @define-color accent      #6e94b2;
      @define-color teal        #b4d4cf;
      @define-color purple      #bb9dbd;
      @define-color green       #7fa563;
      @define-color yellow      #f3be7c;
      @define-color red         #d8647e;
      @define-color orange      #e8b589;

      /* ── Base ──────────────────────────────────────────────────────── */
      * {
        all: unset;
        font-family: "JetBrains Mono", monospace;
        font-size: 11px;
        font-weight: 400;
        min-height: 0;
      }

      /* ── Window ────────────────────────────────────────────────────── */
      window#waybar {
        background: transparent;
        color: @fg;
      }

      window#waybar > box {
        background: @bg;
        border-radius: 8px;
        border: 1px solid @border;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
      }

      /* ── Common module styles ──────────────────────────────────────── */
      #workspaces,
      #window,
      #clock,
      #mpris,
      #pulseaudio,
      #bluetooth,
      #network,
      #battery {
        background: transparent;
        color: @fg;
        padding: 0 12px;
      }

      /* ── Workspaces ────────────────────────────────────────────────── */
      #workspaces {
        padding: 0 4px;
        border-right: 1px solid @border;
        margin-right: 4px;
      }

      #workspaces button {
        font-size: 10px;
        color: @fg-dim;
        padding: 0 10px;
        margin: 0 2px;
        background: transparent;
        border-radius: 4px;
        border-bottom: 2px solid transparent;
        min-width: 24px;
        min-height: 0;
        transition: all 200ms cubic-bezier(0.4, 0, 0.2, 1);
      }

      #workspaces button.active {
        color: @accent;
        border-bottom: 2px solid @accent;
      }

      #workspaces button.urgent {
        color: @red;
        border-bottom: 2px solid @red;
      }

      #workspaces button:hover {
        color: @fg;
        background: @bg-subtle;
      }

      /* ── Window Title ──────────────────────────────────────────────── */
      #window {
        font-style: italic;
        color: @fg-dim;
        padding: 0 12px;
        margin-left: 4px;
      }

      /* ── Clock ─────────────────────────────────────────────────────── */
      #clock {
        font-weight: 600;
        letter-spacing: 1px;
        color: @teal;
        padding: 0 16px;
      }

      /* ── Media (MPRIS) ─────────────────────────────────────────────── */
      #mpris {
        font-style: italic;
        color: @purple;
        padding: 0 12px;
        margin-right: 4px;
        border-right: 1px solid @border;
      }

      /* ── Audio ─────────────────────────────────────────────────────── */
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

      /* ── Bluetooth ─────────────────────────────────────────────────── */
      #bluetooth {
        color: @fg-mid;
        padding: 0 10px;
        transition: all 200ms ease;
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

      /* ── Network ───────────────────────────────────────────────────── */
      #network {
        color: @fg-mid;
        padding: 0 10px;
        transition: color 200ms ease;
      }

      #network:hover {
        color: @fg;
      }

      #network.disconnected {
        color: @red;
      }

      /* ── Battery ───────────────────────────────────────────────────── */
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

      /* ── Tooltips ──────────────────────────────────────────────────── */
      tooltip {
        background: @bg-raised;
        border: 1px solid @border;
        border-radius: 6px;
        padding: 8px 12px;
      }

      tooltip label {
        color: @fg;
      }
    '';
  };
}
