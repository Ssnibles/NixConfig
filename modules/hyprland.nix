{ pkgs, ... }: {
  home.packages = with pkgs; [
    swww
    swaynotificationcenter
    libnotify
    networkmanagerapplet
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "SUPER";
      exec-once = [
        "waybar"
        "swww init"
        "nm-applet --indicator"
        "swaync"
      ];
      bind = [
        # Applications 
        "$mod, RETURN, exec, ghostty"
        "$mod, Q, killactive,"
        "$mod, E, exec, nautilus"
        "$mod, V, togglefloating,"
        "$mod, SPACE, exec, vicinae toggle"

        # System
        "$mod, N, exec, swaync-client -t -sw"
        "$mod, F, fullscreen,"
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
        # Audio
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
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
      };
      decoration = {
        rounding = 10;
      };
    };
  };

  programs.waybar = {
    enable = true;
    style = ''
      * { border: none; font-family: "FiraCode Nerd Font"; }
      window#waybar { background: rgba(30, 30, 46, 0.5); color: #cdd6f4; }
    '';
  };

  # Vicinae Launcher Service [cite: 113, 120, 121]
  programs.vicinae.enable = true;
  systemd.user.services.vicinae = {
    Unit = { Description = "Vicinae launcher daemon"; PartOf = [ "graphical-session.target" ]; };
    Service = { ExecStart = "${pkgs.vicinae}/bin/vicinae server"; Restart = "on-failure"; };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };
}
