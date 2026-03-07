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

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;

    settings = {
      "$mod" = "SUPER";

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
        };
      };

      exec-once = [
        "waybar"
        "swww-daemon"
        "nm-applet --indicator"
        "swaync"
      ];

      # --- Corrected 0.53+ Syntax ---
      windowrule = [
        "float on, match:class ^(nm-connection-editor|blueman-manager)$"
        "float on, match:class ^(org.gnome.Nautilus)$, match:title ^(File Operation Progress)$"
        "float on, match:class ^(org.gnome.Nautilus)$, match:title ^(Confirm to replace files)$"
      ];

      bind = [
        "$mod, RETURN, exec, ghostty"
        "$mod, Q, killactive,"
        "$mod, E, exec, nautilus"
        "$mod, V, togglefloating,"
        "$mod, SPACE, exec, vicinae toggle"
        "$mod, N, exec, swaync-client -t -sw"
        "$mod, F, fullscreen,"

        # Focus & Workspaces
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"
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

        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"

        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      binde = [
        "$mod SHIFT, L, resizeactive, 10 0"
        "$mod SHIFT, H, resizeactive, -10 0"
        "$mod SHIFT, K, resizeactive, 0 -10"
        "$mod SHIFT, J, resizeactive, 0 10"
        ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];

      bindel = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ", XF86AudioPlay, exec, playerctl play-pause"
      ];

      monitor = ", 1920x1080, auto, 1";

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
      };

      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
      };

      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "workspaces, 1, 6, default"
        ];
      };
    };
  };

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
      modules-right = [ "pulseaudio" "network" "battery" "tray" ];

      "hyprland/workspaces" = {
        format = "{name}";
        on-click = "activate";
        all-outputs = true;
        format-icons = {
          active = "";
          default = "";
        };
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
        font-family: "JetBrains Mono Nerd Font", "Roboto", "sans-serif";
        font-size: 13px;
        font-weight: bold;
        min-height: 0;
      }

      window#waybar {
        background: transparent;
        color: #cdd6f4;
      }

      /* Base pill style for all modules */
      #workspaces, #window, #clock, #pulseaudio, #network, #battery, #tray {
        background: rgba(30, 30, 46, 0.85); /* Catppuccin Crust with opacity */
        padding: 0px 12px;
        margin: 0 4px;
        border-radius: 12px;
        border: 1px solid rgba(255, 255, 255, 0.1);
      }

      /* Workspaces specific */
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

      #clock {
        color: #f9e2af;
      }

      #pulseaudio { color: #89b4fa; }
      #network { color: #94e2d5; }
      #battery { color: #a6e3a1; }
      #battery.warning { color: #fab387; }
      #battery.critical { color: #f38ba8; }

      #tray {
        padding: 0 8px;
      }
    '';
  };

  programs.vicinae.enable = true;
  systemd.user.services.vicinae = {
    Unit = {
      Description = "Vicinae launcher daemon";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.vicinae}/bin/vicinae server";
      Restart = "on-failure";
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };
}
