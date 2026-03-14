{ pkgs, ... }: {

  home.packages = with pkgs; [
    awww
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
      ];

      # -----------------------------------------------------------------------
      # WINDOW RULES
      # -----------------------------------------------------------------------
      windowrule = [
        #------------------------#
        # Global: suppress maximize/fullscreen requests from apps
        # This is CRITICAL - without it, apps can override your float sizes
        #------------------------#
        # "match:float true, suppress_event maximize"
        # "match:float true, suppress_event fullscreen"
        # "match:float true, fullscreen off"

        #------------------------#
        # Monitor Assignment
        #------------------------#
        # "match:class ^(gamescope)$, monitor DP-1"

        #------------------------#
        # Tiling (terminals)
        #------------------------#
        # "match:class ^(kitty|alacritty|foot)$, tile on"

        #------------------------#
        # Floating catch-all
        # Applies to any window that opens floating (not toggled post-creation)
        #------------------------#
        "match:float 0, size 60% 60%"
        "match:float 0, center on"

        #------------------------#
        # Picture-in-Picture
        #------------------------#
        # "match:title ^Picture-in-Picture$, float on, pin on, size 960 540, center on"

        #------------------------#
        # Media players
        #------------------------#
        # "match:class ^(imv|mpv)$, float on, size 60% 60%, center on"

        #------------------------#
        # Utilities, file manager, system dialogs
        #------------------------#
        # "match:class ^(danmufloat|termfloat|ncmpcpp|nemo|pavucontrol|.blueman-manager-wrapped)$, float on, size 30% 30%, center on"

        #------------------------#
        # Desktop portal / auth / welcome dialogs
        #------------------------#
        # "match:class ^(xdg-desktop-portal-gtk|xdg-desktop-portal-kde|xdg-desktop-portal-hyprland|org.kde.polkit-kde-authentication-agent-1|zenity)$, float on, size 30% 30%, center on"

        #------------------------#
        # Brave file dialogs
        #------------------------#
        # "match:class ^brave$, match:title ^(Save File|Open File)$, float on, size 60% 65%, center on"

        #------------------------#
        # Steam updater
        #------------------------#
        # "match:title ^Steam - Self Updater$, float on, size 40% 30%, center on"

        #------------------------#
        # Floating border (dynamic — re-evaluates when float state changes)
        #------------------------#
        # "match:float true, border_size 2"

        #------------------------#
        # Opacity
        #------------------------#
        # "match:title ^(Telegram|QQ|NetEase Cloud Music Gtk4)$, opacity 0.95 0.95"
        # "match:class ^alacritty$, opacity 0.85 0.85"
        # "match:title ^Picture-in-Picture$, opacity 1.0 override 1.0 override"
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
        "$mod, V, togglefloating"
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
      # -----------------------------------------------------------------------
      monitor = [
        ", preferred, auto, 1"
      ];

      # -----------------------------------------------------------------------
      # APPEARANCE
      # vague.nvim palette:
      #   active border   → keyword  #6e94b2  (blue accent)
      #   inactive border → line     #252530  (barely visible)
      # -----------------------------------------------------------------------
      general = {
        gaps_in = 8;
        gaps_out = 16;
        border_size = 0;
        "col.active_border" = "rgb(6e94b2)";
        "col.inactive_border" = "rgb(252530)";
      };

      misc.disable_hyprland_logo = true;

      decoration = {
        rounding = 18;
        blur = {
          enabled = false;
          size = 3;
          passes = 1;
        };
        shadow = {
          enabled = false;
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
  # VICINAE (App launcher) — vague theme
  # ===========================================================================
  programs.vicinae = {
    enable = true;
    settings = {
      theme = { dark.name = "vague"; };
    };
  };

  xdg.configFile."vicinae/themes/vague.json".text = builtins.toJSON {
    meta = {
      version = 1;
      name = "Vague";
      description = "A cool, dark, low contrast theme. Pastel yet vivid, like a fleeting memory.";
      variant = "dark";
      inherits = "vicinae-dark";
    };
    colors = {
      core = {
        background = "#141415"; # bg
        foreground = "#cdcdcd"; # fg
        secondary_background = "#1c1c24"; # inactiveBg
        border = "#252530"; # line
        accent = "#6e94b2"; # keyword
      };
      accents = {
        blue = "#6e94b2"; # keyword
        cyan = "#b4d4cf"; # builtin
        purple = "#bb9dbd"; # parameter
        green = "#7fa563"; # plus
        yellow = "#f3be7c"; # warning
        red = "#d8647e"; # error
        orange = "#e8b589"; # string
        magenta = "#c48282"; # func
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

