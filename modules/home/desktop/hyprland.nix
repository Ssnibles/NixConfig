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
  sattyCaptureCommand = "satty --fullscreen current-screen --floating-hack --filename - --output-filename \"${screenshotDir}/Screenshot-%Y-%m-%d_%H-%M-%S.png\" --copy-command wl-copy --actions-on-enter save-to-file,save-to-clipboard,exit";
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
    ../services/wayland.nix
    ./hyprlock.nix
  ];

  xdg.configFile."hypr/xdph.conf".text = xdphConfig;

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
        natural_scroll = false;
        emulate_discrete_scroll = 2;
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
        "${pkgs.bash}/bin/bash -lc 'for i in {1..30}; do awww img ${toString wallpaper} && exit 0; sleep 0.1; done; exit 1'"
        "qs -n"
        "nm-applet --indicator"
      ];

      env = [
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
      ];

      general = {
        gaps_in = 8;
        gaps_out = 16;
        border_size = 0;
        # Make borderless windows easier to resize.
        resize_on_border = true;
        # Prefer low-latency tearing on desktop/gaming rigs, but keep laptops tear-free.
        allow_tearing = hostProfile.isDesktop;
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
        bezier = [
          # Material 3 Expressive: Extreme initial launch with a sudden, rigid snap into place
          "m3_expressive, 0.1, 1, 0, 1"
          # Sharp acceleration curve for rapid window exits
          "m3_expressive_out, 0.3, 0, 0, 1"
        ];

        animation = [
          # Windows: Dramatic scale up from 40% with a hard snap finish
          "windows,           1, 2.2, m3_expressive, popin 40%"
          "windowsIn,         1, 2.2, m3_expressive, popin 40%"
          "windowsOut,        1, 1.8, m3_expressive_out, popin 70%"

          # Borders & Fades: Cut the duration down so they flash and lock immediately
          "border,            1, 1.5, m3_expressive"
          "fade,              1, 1.8, m3_expressive"

          # Layers (menus, rofi, notifications): Instantaneous sliding snap
          "layers,            1, 2, m3_expressive, slide"
          "layersIn,          1, 2, m3_expressive, slide"
          "layersOut,         1, 1.5, m3_expressive_out, slide"

          # Workspaces: Lightning-fast translation across the viewport
          "workspaces,        1, 2.5, m3_expressive, slide"
          "specialWorkspace,  1, 2.5, m3_expressive, slide"
        ];
      };

      dwindle = {
        # Keep split directions consistent when adding/removing windows.
        preserve_split = true;
      };

      # Reduce idle power usage by throttling frame delivery when nothing changes.
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
        "immediate, class:^(steam_app_.*)$" # Applies to all Steam games
        "immediate, class:^(warframe.exe)$"
        "immediate, class:^(minecraft)$"
        "immediate, class:^(qemu)$"
      ];

      windowrulev2 = [
        # Stop apps from forcing maximize on launch.
        "suppressevent maximize, class:.*"
        # Avoid focus stealing while dragging some XWayland popups.
        "nofocus, class:^$,title:^$,xwayland:1,floating:1,fullscreen:0"
        # Kando pie menu overlay.
        "float, class:^(menu\\.kando\\.Kando)$, title:^(Kando Menu)$"
        "pin, class:^(menu\\.kando\\.Kando)$, title:^(Kando Menu)$"
        "size 100% 100%, class:^(menu\\.kando\\.Kando)$, title:^(Kando Menu)$"
        "move 0 0, class:^(menu\\.kando\\.Kando)$, title:^(Kando Menu)$"
        "noanim, class:^(menu\\.kando\\.Kando)$, title:^(Kando Menu)$"
        "noblur, class:^(menu\\.kando\\.Kando)$, title:^(Kando Menu)$"
        "opaque, class:^(menu\\.kando\\.Kando)$, title:^(Kando Menu)$"
        "rounding 0, class:^(menu\\.kando\\.Kando)$, title:^(Kando Menu)$"
        "bordersize 0, class:^(menu\\.kando\\.Kando)$, title:^(Kando Menu)$"
      ];

      layerrule = [
        "blur,hyprlock"
        "ignorezero,hyprlock"
      ];

      binds.allow_workspace_cycles = true;

      monitor = [ ",preferred,auto,1" ];

      workspace = [
        "1, persistent:true"
        "2, persistent:true"
        "3, persistent:true"
        "4, persistent:true"
        "5, persistent:true"
      ];

      bind = [
        # App / session
        "$mod, RETURN, exec, foot"
        "$mod, Q, killactive"
        "$mod, E, exec, yazi"
        "$mod, V, exec, toggle-float"
        "$mod, G, exec, toggle-focus-mode"
        "$mod, SPACE, exec, vicinae toggle"
        # Kando example menu (shortcut ID in Kando's menu editor).
        "CTRL, F12, global, menu.kando.Kando:example-menu"
        "$mod, N, exec, qs ipc call controlpanel toggle"
        "$mod, DELETE, exec, hyprlock"
        "$mod SHIFT, R, exec, reload-all"
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

        # Special workspace (scratch/work stash)
        "$mod, W, togglespecialworkspace, ${specialWorkspaceName}"

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
        "$mod SHIFT, W, movetoworkspace, special:${specialWorkspaceName}"

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

        # Move active window (vim directions)
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, L, movewindow, r"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, J, movewindow, d"

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

  # ── Vicinae launcher ─────────────────────────────────────────────────────
  programs.vicinae = {
    enable = true;
    settings = {
      # Keep launcher rendering light on Hyprland; these effects can make
      # open/search interactions feel sluggish on some GPUs.
      search_files_in_root = false;
      pixmap_cache_mb = 128;
      launcher_window = {
        opacity = 1.0;
        blur.enabled = false;
        dim_around = false;
      };
    };
  };
  # Vicinae may create this settings file itself; force lets Home Manager
  # take ownership on rebuild instead of failing with a clobber error.
  xdg.configFile."vicinae/vicinae.json".force = true;
}
