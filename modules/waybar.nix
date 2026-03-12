{ config, pkgs, ... }: {
  programs.waybar = {
    enable = true;
    settings.main = {
      layer = "top";
      position = "top";
      margin-top = 8;
      margin-left = 16;
      margin-right = 16;
      height = 32;
      spacing = 0;

      modules-left = [ "hyprland/workspaces" "hyprland/window" ];
      modules-center = [ "clock" ];
      modules-right = [ "mpris" "pulseaudio" "bluetooth" "network" "battery" ];

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
        dynamic-order = [ "title" "artist" ];
        player-icons = {
          default = "";
          spotify = "";
          "spotify-player" = "";
        };
        status-icons = { paused = ""; playing = ""; };
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
          default = [ "󰕿" "󰖀" "󰕾" ];
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
        states = { warning = 30; critical = 15; };
        format = "{icon} {capacity}%";
        format-icons = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
        format-charging = "󰂄 {capacity}%";
        format-plugged = "󰚥 {capacity}%";
        tooltip-format = "{timeTo}";
      };
    };

    style = ''
      /* ── vague.nvim palette ────────────────────────────────────
         bg          #141415  — main background
         inactiveBg  #1c1c24  — raised surface
         line        #252530  — borders
         fg          #cdcdcd  — primary text
         comment     #606079  — dimmed text
         floatBorder #878787  — mid-tone text
         keyword     #6e94b2  — blue accent
         builtin     #b4d4cf  — teal accent
         parameter   #bb9dbd  — muted purple
         warning     #f3be7c  — amber
         error       #d8647e  — red
         plus        #7fa563  — green
      ──────────────────────────────────────────────────────────── */

      @define-color bg          #141415;
      @define-color bg-raised   #1c1c24;
      @define-color border      #252530;
      @define-color fg          #cdcdcd;
      @define-color fg-dim      #606079;
      @define-color fg-mid      #878787;
      @define-color accent      #6e94b2;
      @define-color teal        #b4d4cf;
      @define-color purple      #bb9dbd;
      @define-color warn        #f3be7c;
      @define-color error       #d8647e;
      @define-color plus        #7fa563;

      /* ── reset ─────────────────────────────────────────────── */
      * {
        font-family: "JetBrains Mono", "Iosevka", monospace;
        font-size: 11px;
        font-weight: 400;
        min-height: 0;
        border: none;
        border-radius: 0;
        padding: 0;
        margin: 0;
      }

      /* ── bar ───────────────────────────────────────────────── */
      window#waybar {
        background: @bg;
        color: @fg;
        border-radius: 8px;
        border: 1px solid @border;
      }

      /* ── shared ────────────────────────────────────────────── */
      #workspaces, #window, #clock,
      #mpris, #pulseaudio, #bluetooth,
      #network, #battery {
        background: transparent;
        color: @fg;
        padding: 0 10px;
        margin: 0;
      }

      /* ── workspaces ────────────────────────────────────────── */
      #workspaces {
        padding: 0 6px;
        border-right: 1px solid @border;
      }

      #workspaces button {
        font-size: 10px;
        color: @fg-dim;
        padding: 0 8px;
        background: transparent;
        border-bottom: 2px solid transparent;
        min-width: 24px;
        min-height: 0;
        transition: color 150ms ease, border-color 150ms ease;
      }

      #workspaces button.active {
        color: @accent;
        border-bottom: 2px solid @accent;
      }

      #workspaces button.urgent {
        color: @error;
        border-bottom: 2px solid @error;
      }

      #workspaces button:hover {
        color: @fg;
        background: transparent;
      }

      /* ── window title ──────────────────────────────────────── */
      #window {
        font-style: italic;
        color: @fg-dim;
        padding: 0 8px;
      }

      /* ── clock ─────────────────────────────────────────────── */
      #clock {
        font-weight: 600;
        letter-spacing: 1px;
        color: @teal;
      }

      /* ── mpris ─────────────────────────────────────────────── */
      #mpris {
        font-style: italic;
        color: @purple;
        padding-right: 12px;
        border-right: 1px solid @border;
        margin-right: 2px;
      }

      /* ── right modules ─────────────────────────────────────── */
      #pulseaudio,
      #bluetooth,
      #network {
        color: @fg-mid;
        padding: 0 8px;
      }

      #pulseaudio.muted {
        opacity: 0.4;
      }

      #bluetooth.disabled,
      #bluetooth.off {
        opacity: 0;
        padding: 0;
        min-width: 0;
      }

      #network.disconnected {
        color: @error;
      }

      /* ── battery ───────────────────────────────────────────── */
      #battery {
        color: @fg-mid;
        border-left: 1px solid @border;
        padding-left: 12px;
        margin-left: 2px;
      }

      #battery.charging,
      #battery.plugged {
        color: @plus;
      }

      #battery.warning {
        color: @warn;
      }

      #battery.critical {
        color: @error;
      }
    '';
  };
}

