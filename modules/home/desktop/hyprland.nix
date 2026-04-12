# =============================================================================
# Hyprland Home Manager Configuration
# =============================================================================
# Wayland compositor settings, keybindings, and the Vicinae app launcher.
# System-level enablement (programs.hyprland.enable) lives in nixos/common.nix.
# =============================================================================
{ pkgs, colors, ... }:
let
  raw = colors.vague;
  c = colors.vague.withHash;
in
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
        "sleep 2 && awww img ~/NixConfig/wallpapers/stephanie-moody-nA3iwVnI8Mo-unsplash.jpg"
        "waybar"
        "nm-applet --indicator"
        "swaync"
      ];

      general = {
        gaps_in = 8;
        gaps_out = 16;
        border_size = 0;
        "col.inactive_border" = "rgb(${raw.border})";
        "col.active_border" = "rgb(${raw.border})";
      };

      decoration = {
        rounding = 16;
        blur.enabled = true;
        blur.size = 10;
        blur.passes = 3;
        blur.noise = 0.0;
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
        "$mod, ~, workspace, previous"

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
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, L, movewindow, r"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, J, movewindow, d"

        # Screenshots (S)
        "$mod, S, exec, mkdir -p ~/Pictures/Screenshots && file=~/Pictures/Screenshots/$(date +'%Y-%m-%d_%H-%M-%S').png && grim - | tee \"$file\" | wl-copy --type image/png"
        "$mod SHIFT, S, exec, mkdir -p ~/Pictures/Screenshots && file=~/Pictures/Screenshots/$(date +'%Y-%m-%d_%H-%M-%S').png && grim -g \"$(slurp -b 1e1e2ecc -c 89b4faff -s 00000000 -w 2)\" - | tee \"$file\" | wl-copy --type image/png"

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
        ", XF86MonBrightnessUp,   exec, brightnessctl set +5%"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];

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
        background = c.bg;
        foreground = c.fg;
        secondary_background = c.raisedBackground;
        border = c.border;
        accent = c.accent;
      };
      accents = {
        blue = c.accent;
        cyan = c.teal;
        purple = c.purple;
        green = c.green;
        yellow = c.yellow;
        red = c.red;
        orange = c.orange;
        magenta = c.magenta;
      };
    };
  };
}
