{ pkgs, ... }: {

  home.packages = with pkgs; [
    swww
    swaynotificationcenter
    libnotify
    networkmanagerapplet
    brightnessctl
    playerctl
    adwaita-icon-theme
  ];

  # ===========================================================================
  # HYPRLAND
  # ===========================================================================
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;

    settings = {
      "$mod" = "SUPER";

      # -----------------------------------------------------------------------
      # INPUT
      # -----------------------------------------------------------------------
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
        };
      };

      # -----------------------------------------------------------------------
      # AUTOSTART
      # -----------------------------------------------------------------------
      exec-once = [
        "awww-daemon"
        "sleep 2 && awww img ~/NixConfig/wallpapers/400556mtsdl.jpg"
        "waybar"
        "nm-applet --indicator"
        "swaync"
      ];

      # -----------------------------------------------------------------------
      # WINDOW RULES
      # -----------------------------------------------------------------------
      windowrule = [
        "match:class ^(nm-connection-editor|blueman-manager)$, float on"
        "match:class ^(org.gnome.Nautilus)$, match:title ^(File Operation Progress)$, float on"
        "match:class ^(org.gnome.Nautilus)$, match:title ^(Confirm to replace files)$, float on"
      ];

      # -----------------------------------------------------------------------
      # KEYBINDS
      # bind   = fires on press
      # binde  = repeatable (held key)
      # bindel = repeatable + locked (works on lock screen)
      # bindm  = mouse bind
      # -----------------------------------------------------------------------
      bind = [
        "$mod, RETURN, exec, foot"
        "$mod, Q, killactive,"
        "$mod, E, exec, nautilus"
        "$mod, V, togglefloating,"
        "$mod, SPACE, exec, vicinae toggle"
        "$mod, N, exec, swaync-client -t -sw"
        "$mod, F, fullscreen,"

        # Focus (vim-style)
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"

        # Switch workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        # Move window to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"

        # Scroll through workspaces with mouse wheel
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up,   workspace, e-1"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      binde = [
        "$mod SHIFT, L, resizeactive,  10 0"
        "$mod SHIFT, H, resizeactive, -10 0"
        "$mod SHIFT, K, resizeactive,  0 -10"
        "$mod SHIFT, J, resizeactive,  0  10"
        ", XF86MonBrightnessUp,   exec, brightnessctl set +5%"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];

      bindel = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute,        exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute,     exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ", XF86AudioPlay,        exec, playerctl play-pause"
      ];

      # -----------------------------------------------------------------------
      # MONITOR
      # Add entries for external displays as needed:
      #   "HDMI-A-1, 2560x1440, 1920x0, 1"
      # -----------------------------------------------------------------------
      monitor = [
        ", 1920x1080, auto, 1"
        "HDMI-A-1, 2560x1440, 1920x0, 1"
      ];

      # -----------------------------------------------------------------------
      # APPEARANCE
      # -----------------------------------------------------------------------
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgb(254,250,220)";
        "col.inactive_border" = "rgb(237,237,237)";
      };

      misc.disable_hyprland_logo = true;

      decoration = {
        rounding = 16;
        blur = {
          enabled = false;
          size = 3;
          passes = 1;
        };
      };

      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows,    1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "workspaces, 1, 6, default"
        ];
      };
    };
  };

  # ===========================================================================
  # WAYBAR
  # ===========================================================================
  programs.waybar = {
    enable = true;
    settings.main = {
      layer = "top";
      position = "top";
      margin-top = 8;
      margin-left = 10;
      margin-right = 10;
      spacing = 4;

      modules-left = [ "hyprland/workspaces" "hyprland/window" ];
      modules-center = [ "clock" ];
      modules-right = [ "bluetooth" "pulseaudio" "network" "battery" "tray" ];

      "hyprland/workspaces" = {
        format = "{name}";
        on-click = "activate";
        all-outputs = true;
        format-icons = { active = ""; default = ""; };
      };

      "hyprland/window" = {
        format = " | {initialTitle}";
        rewrite = {
          "(.*) — Mozilla Firefox" = "󰈹 Firefox";
          "(.*) - Ghostty" = "󰊠 Terminal";
          "(.*) - Nautilus" = "󰉋 Files";
        };
        separate-outputs = true;
      };

      "clock" = {
        format = "󰥔 {:%H:%M}";
        format-alt = "󰃭 {:%a, %d %b}";
        tooltip-format = "<tt><small>{calendar}</small></tt>";
      };

      "bluetooth" = {
        format = "󰂯";
        format-disabled = "󰂲";
        format-connected = "󰂱 {device_alias}";
        on-click = "blueman-manager";
        tooltip-format = "{controller_alias} — {num_connections} connected";
      };

      "pulseaudio" = {
        format = "{icon} {volume}%";
        format-muted = "󰝟";
        format-icons = {
          headphone = "󰋋";
          default = [ "󰕿" "󰖀" "󰕾" ];
        };
        on-click = "pavucontrol";
      };

      "network" = {
        format-wifi = "󰤨";
        format-ethernet = "󰈀";
        format-disconnected = "󰤮";
        tooltip-format = "{essid} {signalStrength}%";
      };

      "battery" = {
        states = { warning = 30; critical = 15; };
        format = "{icon} {capacity}%";
        format-icons = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
      };
    };

    style = ''
      * {
        font-family: "JetBrains Mono Nerd Font", "Roboto", sans-serif;
        font-size: 13px;
        font-weight: bold;
        min-height: 0;
      }

      window#waybar {
        background: transparent;
        color: #cdd6f4;
      }

      #workspaces, #window, #clock,
      #bluetooth, #pulseaudio, #network, #battery, #tray {
        background: rgba(30, 30, 46, 0.85);
        padding: 0 12px;
        margin: 0 4px;
        border-radius: 12px;
        border: 1px solid rgba(255, 255, 255, 0.1);
      }

      #workspaces button {
        padding: 0 5px;
        color: #6c7086;
        border-radius: 8px;
        transition: all 0.3s ease;
      }

      #workspaces button.active {
        color: #89b4fa;
        background: rgba(137, 180, 250, 0.15);
      }

      #workspaces button:hover {
        background: rgba(255, 255, 255, 0.1);
      }

      #window {
        background: transparent;
        border: none;
        font-weight: normal;
        color: #a6adc8;
      }

      #clock      { color: #f9e2af; }
      #bluetooth  { color: #cba6f7; }
      #pulseaudio { color: #89b4fa; }
      #network    { color: #94e2d5; }
      #battery    { color: #a6e3a1; }

      #battery.warning  { color: #fab387; }
      #battery.critical { color: #f38ba8; }

      #tray { padding: 0 8px; }
    '';
  };

  # ===========================================================================
  # VICINAE (App launcher)
  # ===========================================================================
  programs.vicinae = {
    enable = true;
    settings = {
      theme = { dark.name = "catppuccin-mocha"; };
    };
  };

  xdg.configFile."vicinae/themes/catppuccin-mocha.json".text = builtins.toJSON {
    meta = {
      version = 1;
      name = "Catppuccin Mocha";
      description = "Cozy feeling with color-rich accents";
      variant = "dark";
      icon = "icons/catppuccin-mocha.png";
      inherits = "vicinae-dark";
    };
    colors = {
      core = {
        background = "#1E1E2E";
        foreground = "#CDD6F4";
        secondary_background = "#181825";
        border = "#313244";
        accent = "#89B4FA";
      };
      accents = {
        blue = "#89B4FA";
        green = "#A6E3A1";
        magenta = "#F5C2E7";
        orange = "#FAB387";
        purple = "#CBA6F7";
        red = "#F38BA8";
        yellow = "#F9E2AF";
        cyan = "#94E2D5";
      };
    };
  };

  systemd.user.services.vicinae = {
    Unit = {
      Description = "Vicinae launcher daemon";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.vicinae}/bin/vicinae server";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}

