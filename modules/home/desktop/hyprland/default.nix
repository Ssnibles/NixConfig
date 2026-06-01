{
  pkgs,
  lib,
  config,
  hostProfile,
  ...
}:
let
  raw = import ../../../../lib/stylix/semantic-colors.nix {
    stylixColors = config.lib.stylix.colors;
  };
  wallpaper = (import ../../../../lib/stylix/themes.nix).wallpaper;
  repoRoot = "${config.home.homeDirectory}/NixConfig";
  hyprDir = "${repoRoot}/modules/home/desktop/hyprland";
  qsDir = "${repoRoot}/modules/home/desktop/quickshell";
  specialWorkspaceName = "special";
  brightnessBinds =
    if hostProfile.isDesktop then
      [
        ", XF86MonBrightnessUp,   exec, ddc-brightness up"
        ", XF86MonBrightnessDown, exec, ddc-brightness down"
      ]
    else
      [
        ", XF86MonBrightnessUp,   exec, brightnessctl set +5%"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];
  screenshotDir = "~/Pictures/Screenshots";
  sattyFocusCommand = "(sleep 0.15 && (hyprctl dispatch focuswindow 'class:^(satty)$' || hyprctl dispatch focuswindow 'class:^(com\\.gabm\\.satty)$'))";
  sattyCaptureCommand = "satty --floating-hack --filename - --output-filename \"${screenshotDir}/Screenshot-%Y-%m-%d_%H-%M-%S.png\" --copy-command wl-copy --actions-on-enter save-to-file,save-to-clipboard,exit";
  xdphConfig = ''
    screencopy {
      max_fps = 60
  ''
  + lib.optionalString hostProfile.hasNvidia "        force_shm = true\n"
  + ''
    }
  '';
in
{
  imports = [
    ../../services/wayland.nix
    ../hyprlock.nix
  ];

  xdg.configFile."hypr/xdph.conf".text = xdphConfig;

  home.packages = with pkgs; [
    libnotify
    networkmanagerapplet
    playerctl
    adwaita-icon-theme
  ];

  xdg.configFile."hypr/hypridle.conf".text = ''
    general {
        lock_cmd = pidof hyprlock || hyprlock
        before_sleep_cmd = loginctl lock-session
        after_sleep_cmd = hyprctl dispatch dpms on
    }

    listener {
        timeout = 300
        on-timeout = hyprlock
    }

    listener {
        timeout = 600
        on-timeout = hyprctl dispatch dpms off
        on-resume = hyprctl dispatch dpms on
    }
  ''
  + lib.optionalString hostProfile.isLaptop ''
    listener {
        timeout = 1200
        on-timeout = systemctl suspend
    }
  '';

  systemd.user.services.hypridle = {
    Unit = {
      Description = "Hyprland idle daemon";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.unstable.hypridle}/bin/hypridle";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };

  xdg.configFile."waybar/config".source =
    config.lib.file.mkOutOfStoreSymlink "${hyprDir}/waybar/config.jsonc";
  xdg.configFile."waybar/style.css".source =
    config.lib.file.mkOutOfStoreSymlink "${hyprDir}/waybar/style.css";

  xdg.configFile."quickshell/hyprland/shell.qml".source =
    config.lib.file.mkOutOfStoreSymlink "${hyprDir}/quickshell/shell.qml";
  xdg.configFile."quickshell/hyprland/bar.qml".source =
    config.lib.file.mkOutOfStoreSymlink "${hyprDir}/quickshell/bar.qml";
  xdg.configFile."quickshell/hyprland/Colors.qml".source =
    config.lib.file.mkOutOfStoreSymlink "${qsDir}/Colors.qml";
  xdg.configFile."quickshell/hyprland/Pill.qml".source =
    config.lib.file.mkOutOfStoreSymlink "${qsDir}/Pill.qml";
  xdg.configFile."quickshell/hyprland/notifications.qml".source =
    config.lib.file.mkOutOfStoreSymlink "${qsDir}/notifications.qml";
  xdg.configFile."quickshell/hyprland/CommandCenter.qml".source =
    config.lib.file.mkOutOfStoreSymlink "${qsDir}/CommandCenter.qml";
  xdg.configFile."quickshell/hyprland/AppIcon.qml".source =
    config.lib.file.mkOutOfStoreSymlink "${qsDir}/AppIcon.qml";
  xdg.configFile."quickshell/hyprland/ActionRow.qml".source =
    config.lib.file.mkOutOfStoreSymlink "${qsDir}/ActionRow.qml";
  xdg.configFile."quickshell/hyprland/SliderControl.qml".source =
    config.lib.file.mkOutOfStoreSymlink "${qsDir}/SliderControl.qml";
  xdg.configFile."quickshell/hyprland/shaders/waveform.frag.qsb".source =
    config.xdg.configFile."quickshell/shaders/waveform.frag.qsb".source;
  xdg.configFile."quickshell/hyprland/shaders/waveform.frag".source =
    config.xdg.configFile."quickshell/shaders/waveform.frag".source;
  xdg.configFile."quickshell/hyprland/shaders/circleMask.frag.qsb".source =
    config.xdg.configFile."quickshell/shaders/circleMask.frag.qsb".source;
  xdg.configFile."quickshell/hyprland/shaders/circleMask.frag".source =
    config.xdg.configFile."quickshell/shaders/circleMask.frag".source;

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    settings = {
      "$mod" = "SUPER";

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        natural_scroll = false;
        emulate_discrete_scroll = 2;
      }
      // (lib.optionalAttrs hostProfile.isDesktop {
        accel_profile = "flat";
        force_no_accel = true;
        sensitivity = 0;
      })
      // {
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
        };
      };

      cursor = {
        hide_on_key_press = true;
      };

      exec-once = [
        "${pkgs.bash}/bin/bash -lc 'for i in {1..30}; do awww img ${toString wallpaper} && exit 0; sleep 0.1; done; exit 1'"
        "qs -n -c hyprland"
        "nm-applet --indicator"
      ];

      env = [
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
      ];

      general = {
        gaps_in = 8;
        gaps_out = 16;
        border_size = 0;
        resize_on_border = false;
        allow_tearing = hostProfile.isDesktop;
        "col.active_border" = "rgb(${raw.accent})";
        "col.inactive_border" = "rgb(${raw.border})";
      };

      decoration = {
        rounding = 16;
        blur = {
          enabled = false;
          xray = true;
          special = false;
          passes = 2;
          size = 6;
          noise = 0.02;
          brightness = 0.9;
          contrast = 0.8;
          popups = true;
        };
        shadow = {
          enabled = false;
          range = 12;
          render_power = 3;
          color = "rgba(00000055)";
        };
        dim_inactive = true;
        dim_strength = 0.15;
      };

      animations = {
        enabled = true;
        bezier = [
          "m3_expressive, 0.1, 1, 0, 1"
          "m3_expressive_out, 0.3, 0, 0, 1"
        ];

        animation = [
          "windows,           1, 2.2, m3_expressive, popin 40%"
          "windowsIn,         1, 2.2, m3_expressive, popin 40%"
          "windowsOut,        1, 1.8, m3_expressive_out, popin 70%"
          "border,            1, 1.5, m3_expressive"
          "fade,              1, 1.8, m3_expressive"
          "layers,            1, 2, m3_expressive, slide"
          "layersIn,          1, 2, m3_expressive, slide"
          "layersOut,         1, 1.5, m3_expressive_out, slide"
          "workspaces,        1, 2.5, m3_expressive, slide"
          "specialWorkspace,  1, 2.5, m3_expressive, slide"
        ];
      };

      dwindle = {
        preserve_split = true;
      };

      misc.vfr = true;
      misc.disable_hyprland_logo = true;
      misc.vrr = 1;
      misc.enable_swallow = true;
      misc.swallow_regex = "^(foot|Alacritty|kitty)$";

      windowrule = [
        "bordersize 2, floating:1"
        "float, class:(org.pulseaudio.pavucontrol)"
        "float, class:(blueman-manager)"
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"
        "keepaspectratio, title:^(Picture-in-Picture)$"
        "move 72% 72%, title:^(Picture-in-Picture)$"
        "size 25% 25%, title:^(Picture-in-Picture)$"
        "immediate, class:^(steam_app_.*)$"
        "immediate, class:^(warframe.exe)$"
        "immediate, class:^(minecraft)$"
        "immediate, class:^(qemu)$"
      ];

      windowrulev2 = [
        "float, size 60% 60%, move 20% 20%, title:^(Save As.*)$"
        "float, size 60% 60%, move 20% 20%, title:^(Upload File.*)$"

        "size 50% 50%, floating:1"
        "opacity 0.8 0.8, onworkspace:name:special:special"
        "suppressevent maximize, class:.*"
        "nofocus, class:^$,title:^$,xwayland:1,floating:1,fullscreen:0"
        "workspace special, class:^(Spotify|spotify)$"
        "noblur, class:^(firefox)$, title:^(Picture-in-Picture)$"
        "noblur, class:^(org\\.pulseaudio\\.pavucontrol)$"

        "float, class:^(satty|com\\.gabm\\.satty)$"
        "size 60% 60%, class:^(satty|com\\.gabm\\.satty)$"
        "center, class:^(satty|com\\.gabm\\.satty)$"
      ];

      layerrule = [
        "ignorezero,quickshell-bar"
      ];

      binds.allow_workspace_cycles = true;

      monitor = [ ",preferred,auto,1" ];

      workspace = [
        "1, persistent:true, default:true"
        "2, persistent:true"
        "3, persistent:true"
        "4, persistent:true"
        "5, persistent:true"
      ];

      bind = [
        "$mod, RETURN, exec, foot"
        "$mod, Q, killactive"
        "$mod, E, exec, foot yazi"
        "$mod, V, exec, toggle-float-hyprland"
        "$mod, G, exec, toggle-focus-mode-hyprland"
        "$mod, SPACE, exec, vicinae toggle"
        "$mod, P, exec, qs ipc call controlpanel toggle"
        "$mod, DELETE, exec, hyprlock"
        "$mod SHIFT, R, exec, reload-all-hyprland"
        "$mod, F, fullscreen"

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
        "$mod, `, workspace, previous"
        "$mod, TAB, workspace, previous"

        "$mod, W, togglespecialworkspace, ${specialWorkspaceName}"

        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"
        "$mod SHIFT, W, movetoworkspace, special:${specialWorkspaceName}"

        "$mod CTRL SHIFT, 1, movetoworkspacesilent, 1"
        "$mod CTRL SHIFT, 2, movetoworkspacesilent, 2"
        "$mod CTRL SHIFT, 3, movetoworkspacesilent, 3"
        "$mod CTRL SHIFT, 4, movetoworkspacesilent, 4"
        "$mod CTRL SHIFT, 5, movetoworkspacesilent, 5"
        "$mod CTRL SHIFT, 6, movetoworkspacesilent, 6"
        "$mod CTRL SHIFT, 7, movetoworkspacesilent, 7"
        "$mod CTRL SHIFT, 8, movetoworkspacesilent, 8"
        "$mod CTRL SHIFT, 9, movetoworkspacesilent, 9"
        "$mod CTRL SHIFT, 0, movetoworkspacesilent, 10"
        "$mod CTRL SHIFT, W, movetoworkspacesilent, special:${specialWorkspaceName}"
        "$mod ALT, 1, movetoworkspacesilent, 1"
        "$mod ALT, 2, movetoworkspacesilent, 2"
        "$mod ALT, 3, movetoworkspacesilent, 3"
        "$mod ALT, 4, movetoworkspacesilent, 4"
        "$mod ALT, 5, movetoworkspacesilent, 5"
        "$mod ALT, 6, movetoworkspacesilent, 6"
        "$mod ALT, 7, movetoworkspacesilent, 7"
        "$mod ALT, 8, movetoworkspacesilent, 8"
        "$mod ALT, 9, movetoworkspacesilent, 9"
        "$mod ALT, 0, movetoworkspacesilent, 10"
        "$mod ALT, W, movetoworkspacesilent, special:${specialWorkspaceName}"

        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, L, movewindow, r"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, J, movewindow, d"

        "$mod, S, exec, mkdir -p ${screenshotDir}; ${sattyFocusCommand} & grim -o \"$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')\" - | ${sattyCaptureCommand}"
        "$mod SHIFT, S, exec, mkdir -p ${screenshotDir}; region=$(hyprctl -j clients | jq -r --argjson ws $(hyprctl -j activeworkspace | jq -r '.id') '.[] | select(.mapped and .workspace.id == $ws) | (.at[0]|tostring) + \",\" + (.at[1]|tostring) + \" \" + (.size[0]|tostring) + \"x\" + (.size[1]|tostring)' | slurp); [ -n \"$region\" ] && { ${sattyFocusCommand} & grim -g \"$region\" - | ${sattyCaptureCommand}; }"

        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up,   workspace, e-1"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      binde = [
        "$mod CTRL, L, resizeactive,  10 0"
        "$mod CTRL, H, resizeactive, -10 0"
        "$mod CTRL, K, resizeactive,  0 -10"
        "$mod CTRL, J, resizeactive,  0  10"
      ]
      ++ brightnessBinds;

      bindel = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute,        exec, wpctl set-mute   @DEFAULT_AUDIO_SINK@   toggle"
        ", XF86AudioMicMute,     exec, wpctl set-mute   @DEFAULT_AUDIO_SOURCE@ toggle"
        ", XF86AudioPlay,        exec, playerctl play-pause"
        ", XF86AudioNext,        exec, playerctl next"
        ", XF86AudioPrev,        exec, playerctl previous"
      ];
    };
  };

  programs.vicinae = {
    enable = true;
    settings = {
      search_files_in_root = false;
      pixmap_cache_mb = 128;
      launcher_window = {
        opacity = 1.0;
        blur.enabled = false;
        dim_around = false;
      };
    };
  };
  xdg.configFile."vicinae/vicinae.json".force = true;
}
