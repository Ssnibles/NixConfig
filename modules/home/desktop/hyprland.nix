# =============================================================================
# Hyprland Home Manager Configuration
# =============================================================================
# Wayland compositor settings, keybindings, and the Vicinae app launcher.
# System-level enablement (programs.hyprland.enable) lives in nixos/common.nix.
# =============================================================================
{ pkgs, ... }:
{
  imports = [
    ../services/wayland.nix
    ./hyprlock.nix
  ];

  home.packages = with pkgs; [
    awww # Wallpaper daemon
    libnotify
    networkmanagerapplet
    playerctl
    adwaita-icon-theme
    hyprlock
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
        # services handled by systemd (see services/wayland.nix):
        # awww-daemon, vicinae server
        "sleep 2 && awww img ~/NixConfig/wallpapers/517020ldsdl.jpg"
        "waybar"
        "nm-applet --indicator"
        "swaync"
      ];

      general = {
        gaps_in = 8;
        gaps_out = 16;
        border_size = 0;
        "col.inactive_border" = "rgb(120,120,120)";
        "col.active_border" = "rgb(120,120,120)";
      };

      decoration = {
        rounding = 16;
        blur.enabled = false;
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

      windowrule = [
        # "bordersize 2, floating:1"
        # "float, class:(org.pulseaudio.pavucontrol)"
        # "float, class:(blueman-manager)"
      ];

      binds.allow_workspace_cycles = true;

      monitor = [ ",preferred,auto,1" ];

      bind = [
        "$mod, RETURN, exec, foot"
        "$mod, X, killactive"
        "$mod, E, exec, yazi"
        "$mod, V, exec, toggle-float"
        "$mod, G, exec, toggle-focus-mode"
        "$mod, SPACE, exec, vicinae toggle"
        "$mod, N, exec, swaync-client -t -sw"
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
        "$mod, P, workspace, previous"
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
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
        ", XF86AudioMute,        exec, wpctl set-mute   @DEFAULT_AUDIO_SINK@   toggle"
        ", XF86AudioMicMute,     exec, wpctl set-mute   @DEFAULT_AUDIO_SOURCE@ toggle"
        ", XF86AudioPlay,        exec, playerctl play-pause"
      ];
    };
  };

  # ── Vicinae launcher ─────────────────────────────────────────────────────
  programs.vicinae = {
    enable = true;
    settings.theme.dark.name = "vague";
  };

  xdg.configFile."vicinae/themes/vague.json".text = builtins.toJSON {
    meta = {
      version = 1;
      name = "Vague";
      description = "A cool, dark, low-contrast theme.";
      variant = "dark";
      inherits = "vicinae-dark";
    };
    colors = {
      core = {
        background = "#141415";
        foreground = "#cdcdcd";
        secondary_background = "#1c1c24";
        border = "#252530";
        accent = "#6e94b2";
      };
      accents = {
        blue = "#6e94b2";
        cyan = "#b4d4cf";
        purple = "#bb9dbd";
        green = "#7fa563";
        yellow = "#f3be7c";
        red = "#d8647e";
        orange = "#e8b589";
        magenta = "#c48282";
      };
    };
  };
}
