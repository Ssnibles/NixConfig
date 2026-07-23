{ self, inputs, ... }:
{
  flake.nixosModules.mangowc =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.programs.mango;
      accent = config.theme.colors.accent;
      bg = config.theme.colors.bg;
      fg = config.theme.colors.fg;
    in
    {
      imports = [
        inputs.mangowc.nixosModules.mango
        self.nixosModules.cursors
        self.nixosModules.vicinae
        self.nixosModules.quickshell
        self.nixosModules.wallpapers
      ];

      config = {
        wallpaper-destinations = [ "Pictures/wallpapers" ];

        programs.mango.enable = true;

        environment.systemPackages = with pkgs; [
          swaybg
          wl-clipboard
          brightnessctl
          playerctl
          grim
          grimblast
          slurp
          libnotify
          networkmanagerapplet
          adwaita-icon-theme
        ];

        xdg.portal = {
          enable = true;
          extraPortals = [
            pkgs.xdg-desktop-portal-gtk
            pkgs.xdg-desktop-portal-wlr
          ];
          configPackages = [ pkgs.xdg-desktop-portal-gnome ];
        };

        hjem.users."${config.username}" = {
          enable = true;
          files = {
            ".config/mango/config.conf".text = ''
              # Window effects
              blur = 1
              blur_optimized = 1
              blur_params_radius = 5
              blur_params_num_passes = 2
              border_radius = 8
              focused_opacity = 1.0
              inactive_opacity = 0.85

              # Colors
              border_color = #${accent}
              inactive_border_color = #${bg}

              # Gaps
              gaps = 8

              # Layout
              layout_name = tile

              # Animations
              animations = 1
              animation_duration_open = 400
              animation_duration_close = 300

              # Mouse
              focus_on_click = 1
              natural_scroll = 0

              # Touchpad
              touchpad_natural_scroll = 1

              # Launcher
              bind = SUPER,Space,spawn,vicinae toggle

              # Terminal
              bind = SUPER,Return,spawn,foot

              # Window management
              bind = SUPER,q,killclient
              bind = SUPER,f,togglefullscreen
              bind = SUPER,v,togglefloating
              bind = SUPER+Shift,r,reload_config

              # Focus
              bind = SUPER,h,focusdir,left
              bind = SUPER,l,focusdir,right
              bind = SUPER,k,focusdir,up
              bind = SUPER,j,focusdir,down

              # Move windows
              bind = SUPER+Shift,h,exchange_client,left
              bind = SUPER+Shift,l,exchange_client,right
              bind = SUPER+Shift,k,exchange_client,up
              bind = SUPER+Shift,j,exchange_client,down

              # Tags 1-9
              bind = SUPER,1,view,1
              bind = SUPER,2,view,2
              bind = SUPER,3,view,3
              bind = SUPER,4,view,4
              bind = SUPER,5,view,5
              bind = SUPER,6,view,6
              bind = SUPER,7,view,7
              bind = SUPER,8,view,8
              bind = SUPER,9,view,9
              bind = SUPER,0,view,10

              # Move to tag
              bind = SUPER+Shift,1,tag,1,0
              bind = SUPER+Shift,2,tag,2,0
              bind = SUPER+Shift,3,tag,3,0
              bind = SUPER+Shift,4,tag,4,0
              bind = SUPER+Shift,5,tag,5,0
              bind = SUPER+Shift,6,tag,6,0
              bind = SUPER+Shift,7,tag,7,0
              bind = SUPER+Shift,8,tag,8,0
              bind = SUPER+Shift,9,tag,9,0
              bind = SUPER+Shift,0,tag,10,0

              # Previous tag
              bind = SUPER,Tab,view,-1

              # Screenshots
              bind = SUPER,s,spawn,grimblast save output - | wl-copy
              bind = SUPER+Shift,s,spawn,grimblast save area - | wl-copy

              # File manager
              bind = SUPER,e,spawn,foot yazi

              # Lock
              bind = SUPER,Delete,spawn,loginctl lock-session

              # Volume
              bind = ,XF86AudioRaiseVolume,spawn,wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
              bind = ,XF86AudioLowerVolume,spawn,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
              bind = ,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
              bind = ,XF86AudioMicMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
              bind = ,XF86AudioPlay,spawn,playerctl play-pause
              bind = ,XF86AudioNext,spawn,playerctl next
              bind = ,XF86AudioPrev,spawn,playerctl previous

              # Brightness
              bind = ,XF86MonBrightnessUp,spawn,brightnessctl set +5%
              bind = ,XF86MonBrightnessDown,spawn,brightnessctl set 5%-

              # Autostart
              exec-once = quickshell
              exec-once = swaybg -i ~/Pictures/wallpapers/default.png -m fill
              exec-once = nm-applet --indicator
              exec-once = flameshot
            '';
          };
        };
      };
    };
}
