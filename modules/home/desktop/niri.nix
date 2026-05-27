{
  pkgs,
  lib,
  config,
  hostProfile,
  ...
}:
let
  raw = import ../../../lib/stylix/semantic-colors.nix { stylixColors = config.lib.stylix.colors; };
  wallpaper = toString (import ../../../lib/stylix/themes.nix).wallpaper;
  screenshotDir = "$HOME/Pictures/Screenshots";
  sattyCmd = "satty --fullscreen current-screen --floating-hack --filename - --output-filename \"${screenshotDir}/Screenshot-%Y-%m-%d_%H-%M-%S.png\" --copy-command wl-copy --actions-on-enter save-to-file,save-to-clipboard,exit";
  # Escape " → \" for use inside KDL double-quoted strings
  sattyCmdKDL = lib.replaceStrings [ "\"" ] [ "\\\"" ] sattyCmd;
  brightnessBinds = lib.optionalString hostProfile.isDesktop ''
    XF86MonBrightnessUp { spawn-sh "ddc-brightness up"; }
    XF86MonBrightnessDown { spawn-sh "ddc-brightness down"; }
  '' + lib.optionalString (!hostProfile.isDesktop) ''
    XF86MonBrightnessUp { spawn-sh "brightnessctl set +5%"; }
    XF86MonBrightnessDown { spawn-sh "brightnessctl set 5%-"; }
  '';
  inherit (lib) optionalString;
  liveDir = "${config.home.homeDirectory}/NixConfig/live";

  niriConfigKdl = ''
    input {
        keyboard {
            xkb {
                layout "us"
            }
        }
        touchpad {
            natural-scroll
            tap
        }
        ${optionalString hostProfile.isDesktop ''
        mouse {
            accel-profile "flat"
        }
        ''}
    }

    cursor {
        hide-when-typing
    }

    // Smooth animations for polished feel (like Hyprland)
    animations {
        workspace-switch { spring damping-ratio=0.8 stiffness=800 epsilon=0.0001; }
        window-open { duration-ms 150 curve "ease-out-expo"; }
        window-close { duration-ms 150 curve "ease-out-quad"; }
        horizontal-view-movement { spring damping-ratio=0.8 stiffness=800 epsilon=0.0001; }
        window-movement { spring damping-ratio=0.8 stiffness=800 epsilon=0.0001; }
        window-resize { spring damping-ratio=0.8 stiffness=800 epsilon=0.0001; }
    }

    spawn-at-startup "${pkgs.bash}/bin/bash" "-lc" "for i in {1..30}; do awww img ${toString wallpaper} && exit 0; sleep 0.1; done; exit 1"
    spawn-at-startup "qs" "-n"
    spawn-at-startup "nm-applet" "--indicator"

    environment {
        ELECTRON_OZONE_PLATFORM_HINT "auto"
    }

    layout {
        gaps 8
        // Outer gaps via struts (like Hyprland's gaps_out > gaps_in)
        struts {
            left 8
            right 8
            top 8
            bottom 8
        }
        center-focused-column "always"
    }

    // Dim inactive windows (Hyprland's dim_inactive equivalent)
    window-rule {
        match is-active=false
        opacity 0.85
    }

    // Consolidated floating dialogs
    window-rule {
        match title=r#"^(Save As|Upload File).*$"#
        open-floating true
        default-column-width { proportion 0.6; }
        default-window-height { proportion 0.6; }
    }

    // Floating utility windows
    window-rule {
        match app-id=r#"^(org\.pulseaudio\.pavucontrol|blueman-manager)$"#
        open-floating true
    }

    // Picture-in-Picture
    window-rule {
        match title="^Picture-in-Picture$"
        open-floating true
        default-column-width { proportion 0.25; }
        default-window-height { proportion 0.25; }
    }

    // Special scratchpad workspace (like Hyprland's togglespecialworkspace)
    workspace "scratch" {
        open-on-output "focused"
    }

    binds {
        // ---- Apps & Session ----
        Mod+Return { spawn "foot"; }
        Mod+Q { close-window; }
        Mod+E { spawn "yazi"; }
        Mod+V { toggle-window-floating; }
        Mod+G { spawn-sh "toggle-focus-mode"; }
        Mod+Space { spawn-sh "vicinae toggle"; }
        Mod+P { spawn-sh "qs ipc call controlpanel toggle"; }
        Mod+Delete { spawn "swaylock"; }
        Mod+Shift+R { spawn-sh "reload-all"; }
        Mod+F { fullscreen-window; }

        // ---- Screenshots ----
        Mod+S { spawn-sh "mkdir -p ${screenshotDir}; grim -o \"$(niri msg focused-monitor | head -1)\" - | ${sattyCmdKDL}"; }
        Mod+Shift+S { spawn-sh "mkdir -p ${screenshotDir}; grim -g \"$(slurp)\" - | ${sattyCmdKDL}"; }

        // ---- Focus Movement ----
        Mod+H { focus-column-left; }
        Mod+L { focus-column-right; }
        Mod+K { focus-window-up; }
        Mod+J { focus-window-down; }

        // ---- Window/Column Movement ----
        Mod+Shift+H { move-column-left; }
        Mod+Shift+L { move-column-right; }
        Mod+Shift+K { move-window-up; }
        Mod+Shift+J { move-window-down; }

        // ---- Workspaces ----
        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }
        Mod+0 { focus-workspace 10; }
        Mod+Grave { focus-workspace-previous; }
        Mod+Tab { focus-workspace-previous; }

        // Special scratchpad workspace (like Hyprland's Mod+W)
        Mod+W { focus-workspace "scratch"; }

        // ---- Move Column to Workspace ----
        Mod+Shift+1 { move-column-to-workspace 1; }
        Mod+Shift+2 { move-column-to-workspace 2; }
        Mod+Shift+3 { move-column-to-workspace 3; }
        Mod+Shift+4 { move-column-to-workspace 4; }
        Mod+Shift+5 { move-column-to-workspace 5; }
        Mod+Shift+6 { move-column-to-workspace 6; }
        Mod+Shift+7 { move-column-to-workspace 7; }
        Mod+Shift+8 { move-column-to-workspace 8; }
        Mod+Shift+9 { move-column-to-workspace 9; }
        Mod+Shift+0 { move-column-to-workspace 10; }
        Mod+Shift+W { move-column-to-workspace "scratch"; }

        // Move column to adjacent workspace
        Mod+Ctrl+Shift+Page_Down { move-column-to-workspace-down; }
        Mod+Ctrl+Shift+Page_Up { move-column-to-workspace-up; }

        // ---- Resize ----
        Mod+Ctrl+L { set-column-width "+10"; }
        Mod+Ctrl+H { set-column-width "-10"; }
        Mod+Ctrl+K { set-window-height "+10"; }
        Mod+Ctrl+J { set-window-height "-10"; }

        // ---- Misc ----
        Ctrl+F12 { spawn "kando"; }

        // Scroll through workspaces with mouse wheel
        Mod+WheelScrollDown { focus-workspace-down; }
        Mod+WheelScrollUp { focus-workspace-up; }

        ${brightnessBinds}

        // ---- Media Keys ----
        XF86AudioRaiseVolume { spawn-sh "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"; }
        XF86AudioLowerVolume { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"; }
        XF86AudioMute { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }
        XF86AudioMicMute { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; }
        XF86AudioPlay { spawn-sh "playerctl play-pause"; }
        XF86AudioNext { spawn-sh "playerctl next"; }
        XF86AudioPrev { spawn-sh "playerctl previous"; }
    }
  '';
in
{
  imports = [
    ../services/wayland.nix
    ./swaylock.nix
  ];

  home.packages = with pkgs; [
    libnotify
    networkmanagerapplet
    playerctl
    adwaita-icon-theme
    swayidle
  ];

  xdg.configFile."niri/config.kdl" = {
    source = config.lib.file.mkOutOfStoreSymlink "${liveDir}/niri/config.kdl";
    force = true;
  };

  home.activation.writeNiriConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    mkdir -p "$HOME/NixConfig/live/niri"
    cat > "$HOME/NixConfig/live/niri/config.kdl" << 'KDL'
    ${niriConfigKdl}
    KDL
  '';

  # ── Vicinae launcher ─────────────────────────────────────────────────────
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
