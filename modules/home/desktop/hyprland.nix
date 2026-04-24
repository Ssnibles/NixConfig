# =============================================================================
# Hyprland Home Manager Configuration
# =============================================================================
# Wayland compositor settings, keybindings, and the Vicinae app launcher.
# System-level enablement (programs.hyprland.enable) lives in nixos/common.nix.
# =============================================================================
{
  pkgs,
  lib,
  config,
  hostProfile,
  ...
}:
let
  raw = import ../../../lib/stylix/semantic-colors.nix { stylixColors = config.lib.stylix.colors; };
  wallpaper = ../../../wallpapers/kalen-emsley-Bkci_8qcdvQ-unsplash.jpg;
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
  sattyCaptureCommand = "satty --fullscreen current-screen --floating-hack --filename - --output-filename \"${screenshotDir}/Screenshot-%Y-%m-%d_%H-%M-%S.png\" --copy-command wl-copy --actions-on-enter save-to-file,save-to-clipboard,exit";
in
{
  imports = [
    ../services/wayland.nix
    ./hyprlock.nix
  ];

  home.packages = with pkgs; [
    libnotify
    networkmanagerapplet
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
      }
      // (lib.optionalAttrs hostProfile.isDesktop {
        # Keep mouse movement 1:1 on desktop/gaming rigs.
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

      exec-once = [
        # Some services are handled by systemd (see services/wayland.nix)
        "sleep 2 && awww img ${toString wallpaper}"
        "waybar"
        "nm-applet --indicator"
        "swaync"
      ];

      general = {
        gaps_in = 8;
        gaps_out = 16;
        border_size = 0;
        # Keep compositor vsync active to avoid visible tearing during fast motion.
        allow_tearing = true;
        "col.inactive_border" = "rgb(${raw.border})";
        "col.active_border" = "rgb(${raw.border})";
      };

      decoration = {
        rounding = 16;
        blur = {
          enabled = false;
          size = 10;
          passes = 3;
          noise = 0.0;
        };
        shadow.enabled = false;
      };

      animations = {
        enabled = true;
        bezier = "smooth, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows,    1, 7, smooth"
          "windowsOut, 1, 7, default, popin 80%"
          "workspaces, 1, 6, default"
        ];
      };

      misc.disable_hyprland_logo = true;
      misc.vrr = 1;

      windowrule = [
        "bordersize 2, floating:1"
        "float, class:(org.pulseaudio.pavucontrol)"
        "float, class:(blueman-manager)"
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"
        "keepaspectratio, title:^(Picture-in-Picture)$"
        "move 72% 72%, title:^(Picture-in-Picture)$"
        "size 25% 25%, title:^(Picture-in-Picture)$"
        "immediate, class:^(steam_app_.*)$" # Applies to all Steam games
        "immediate, class:^(warframe.exe)$"
        "immediate, class:^(minecraft)$"
      ];

      windowrulev2 = [ ];

      layerrule = [
        "blur,hyprlock"
        "ignorezero,hyprlock"
      ];

      binds.allow_workspace_cycles = true;

      monitor = [ ",preferred,auto,1" ];

      bind = [
        # App / session
        "$mod, RETURN, exec, foot"
        "$mod, Q, killactive"
        "$mod, E, exec, yazi"
        "$mod, V, exec, toggle-float"
        "$mod, G, exec, toggle-focus-mode"
        "$mod, SPACE, exec, vicinae toggle"
        "$mod, N, exec, swaync-client -t -sw"
        "$mod, DELETE, exec, hyprlock"
        "$mod, F, fullscreen"

        # Window focus (vim directions)
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"

        # Workspaces
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

        # Move window to workspace (follow)
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

        # Move window to workspace (silent, stay on current workspace)
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

        # Move active window (vim directions)
        "$mod CTRL, H, movewindow, l"
        "$mod CTRL, L, movewindow, r"
        "$mod CTRL, K, movewindow, u"
        "$mod CTRL, J, movewindow, d"

        # Screenshots (S)
        "$mod, S, exec, mkdir -p ${screenshotDir}; ${sattyFocusCommand} & grim -o \"$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')\" - | ${sattyCaptureCommand}"
        "$mod SHIFT, S, exec, mkdir -p ${screenshotDir}; ${sattyFocusCommand} & grim -g \"$(hyprctl -j clients | jq -r --argjson ws $(hyprctl -j activeworkspace | jq -r '.id') '.[] | select(.mapped and .workspace.id == $ws) | (.at[0]|tostring) + \",\" + (.at[1]|tostring) + \" \" + (.size[0]|tostring) + \"x\" + (.size[1]|tostring)' | slurp)\" - | ${sattyCaptureCommand}"

        # Workspace cycling
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
      ]
      ++ brightnessBinds;

      bindel = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute,        exec, wpctl set-mute   @DEFAULT_AUDIO_SINK@   toggle"
        ", XF86AudioMicMute,     exec, wpctl set-mute   @DEFAULT_AUDIO_SOURCE@ toggle"
        ", XF86AudioPlay,        exec, playerctl play-pause"
      ];
    };
  };

  # ── Vicinae launcher ─────────────────────────────────────────────────────
  programs.vicinae = {
    enable = true;
  };
  # Vicinae may create this settings file itself; force lets Home Manager
  # take ownership on rebuild instead of failing with a clobber error.
  xdg.configFile."vicinae/vicinae.json".force = true;
}
