# =============================================================================
# River Wayland Compositor Feature
# =============================================================================
# Lightweight River window manager feature with Quickshell status bar support,
# matching Mango WC keybindings, environment variables, theme palette integration,
# and system activation init script.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (config.theme.colors)
        bg
        border
        accent
        red
        ;
    in
    {
      config = {
        wallpaper-destinations = [ "Pictures/wallpaper" ];
        programs.river.enable = true;

        environment.systemPackages = with pkgs; [
          ristate
          rivercarro
          tesseract
        ];

        hjem.users."${config.username}" = {
          enable = true;
          files = {
            ".config/river/init" = {
              executable = true;
              text = ''
                #!/usr/bin/env sh

                # Environment Variables
                export QS_BAR=river
                export QT_QPA_PLATFORM=wayland
                export ELECTRON_OZONE_PLATFORM_HINT=wayland
                export XCURSOR_THEME=Bibata-Modern-Ice
                export XCURSOR_SIZE=24
                export XDG_CURRENT_DESKTOP=river
                export XDG_SESSION_DESKTOP=river

                # Window Appearance & Theme
                riverctl border-width 2
                riverctl border-color-focused 0x${accent}
                riverctl border-color-unfocused 0x${border}
                riverctl border-color-urgent 0x${red}
                riverctl background-color 0x${bg}

                riverctl set-repeat 35 200
                riverctl xcursor-theme Bibata-Modern-Ice 24
                riverctl focus-follows-cursor normal

                # Touchpad & Mouse Rules
                riverctl input "pointer-*" natural-scroll disabled
                riverctl input "touchpad-*" natural-scroll enabled
                riverctl input "touchpad-*" tap enabled
                riverctl input "touchpad-*" disable-while-typing enabled

                # Pointer Binds
                riverctl map-pointer normal Super BTN_LEFT move-view
                riverctl map-pointer normal Super BTN_RIGHT resize-view
                riverctl map-pointer normal Super BTN_MIDDLE toggle-float

                # Application Launchers
                riverctl map normal Super Return spawn foot
                riverctl map normal Super Space spawn "vicinae toggle"
                riverctl map normal Super d spawn "quickshell ipc call command-center toggle"
                riverctl map normal Super+Alt L spawn "quickshell ipc call lockscreen lock"
                riverctl map normal Super e spawn "foot -e yazi"

                # Window Management
                riverctl map normal Super q close
                riverctl map normal Super f toggle-fullscreen
                riverctl map normal Super+Shift f toggle-fullscreen
                riverctl map normal Super v toggle-float
                riverctl map normal Super c toggle-float
                riverctl map normal Super g toggle-float
                riverctl map normal Super+Shift r spawn "$HOME/.config/river/init"

                # Directional Focus (Vim & Arrow keys)
                riverctl map normal Super h focus-view left
                riverctl map normal Super l focus-view right
                riverctl map normal Super k focus-view up
                riverctl map normal Super j focus-view down
                riverctl map normal Super Left focus-view left
                riverctl map normal Super Right focus-view right
                riverctl map normal Super Up focus-view up
                riverctl map normal Super Down focus-view down

                # Move Windows (Vim & Arrow keys)
                riverctl map normal Super+Shift h swap left
                riverctl map normal Super+Shift l swap right
                riverctl map normal Super+Shift k swap up
                riverctl map normal Super+Shift j swap down
                riverctl map normal Super+Shift Left swap left
                riverctl map normal Super+Shift Right swap right
                riverctl map normal Super+Shift Up swap up
                riverctl map normal Super+Shift Down swap down

                # Resizing Tiled Layout (rivertile main-ratio & main-count)
                riverctl map normal Super+Control h send-layout-cmd rivertile "main-ratio -0.05"
                riverctl map normal Super+Control l send-layout-cmd rivertile "main-ratio +0.05"
                riverctl map normal Super+Control k send-layout-cmd rivertile "main-count +1"
                riverctl map normal Super+Control j send-layout-cmd rivertile "main-count -1"
                riverctl map normal Super+Control Left send-layout-cmd rivertile "main-ratio -0.05"
                riverctl map normal Super+Control Right send-layout-cmd rivertile "main-ratio +0.05"
                riverctl map normal Super+Control Up send-layout-cmd rivertile "main-count +1"
                riverctl map normal Super+Control Down send-layout-cmd rivertile "main-count -1"

                # Monitor Focus (Vim & Arrow keys)
                riverctl map normal Super+Alt h focus-output left
                riverctl map normal Super+Alt l focus-output right
                riverctl map normal Super+Alt k focus-output up
                riverctl map normal Super+Alt j focus-output down
                riverctl map normal Super+Alt Left focus-output left
                riverctl map normal Super+Alt Right focus-output right
                riverctl map normal Super+Alt Up focus-output up
                riverctl map normal Super+Alt Down focus-output down

                # Move Window to Monitor (Vim & Arrow keys)
                riverctl map normal Super+Shift+Control h send-to-output left
                riverctl map normal Super+Shift+Control l send-to-output right
                riverctl map normal Super+Shift+Control k send-to-output up
                riverctl map normal Super+Shift+Control j send-to-output down
                riverctl map normal Super+Shift+Control Left send-to-output left
                riverctl map normal Super+Shift+Control Right send-to-output right
                riverctl map normal Super+Shift+Control Up send-to-output up
                riverctl map normal Super+Shift+Control Down send-to-output down

                # Tags 1-9 & 0 (10)
                for i in $(seq 1 9); do
                  mask=$((1 << (i - 1)))
                  riverctl map normal Super $i set-focused-tags $mask
                  riverctl map normal Super+Shift $i set-view-tags $mask
                done
                riverctl map normal Super 0 set-focused-tags 512
                riverctl map normal Super+Shift 0 set-view-tags 512

                # Previous Tag
                riverctl map normal Super Tab focus-previous-tags

                # Screenshots
                riverctl map normal Super s spawn 'sh -c "pgrep -x slurp >/dev/null && exit 0; GEOM=\$(slurp); [ -n \"\$GEOM\" ] && grim -g \"\$GEOM\" - | tee \"\$HOME/Pictures/Screenshot_\$(date +%Y-%m-%d_%H-%M-%S).png\" | wl-copy -t image/png"'
                riverctl map normal Super+Shift s spawn 'sh -c "pgrep -x slurp >/dev/null && exit 0; GEOM=\$(slurp); [ -n \"\$GEOM\" ] && grim -g \"\$GEOM\" - | tesseract stdin stdout -l eng 2>/dev/null | wl-copy && notify-send \"OCR Complete\" \"Text copied to clipboard.\"'

                # Volume & Mic Controls
                riverctl map normal None XF86AudioRaiseVolume spawn "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"
                riverctl map normal None XF86AudioLowerVolume spawn "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
                riverctl map normal None XF86AudioMute spawn "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
                riverctl map normal None XF86AudioMicMute spawn "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"

                # Media Playback Controls
                riverctl map normal None XF86AudioPlay spawn "playerctl play-pause"
                riverctl map normal None XF86AudioNext spawn "playerctl next"
                riverctl map normal None XF86AudioPrev spawn "playerctl previous"
                riverctl map normal None XF86AudioStop spawn "playerctl stop"

                # Display Brightness Controls
                riverctl map normal None XF86MonBrightnessUp spawn "brightnessctl set +5%"
                riverctl map normal None XF86MonBrightnessDown spawn "brightnessctl set 5%-"

                # Layout Generator (rivertile)
                riverctl default-layout rivertile
                rivertile -view-padding 12 -outer-padding 12 -main-ratio 0.55 &

                # Systemd & Session Autostart
                riverctl spawn "dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP=river XDG_SESSION_DESKTOP=river XDG_SESSION_TYPE=wayland QT_QPA_PLATFORM=wayland ELECTRON_OZONE_PLATFORM_HINT=wayland MOZ_ENABLE_WAYLAND=1 XCURSOR_THEME=Bibata-Modern-Ice XCURSOR_SIZE=24"
                riverctl spawn "systemctl --user import-environment WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE QT_QPA_PLATFORM ELECTRON_OZONE_PLATFORM_HINT MOZ_ENABLE_WAYLAND XCURSOR_THEME XCURSOR_SIZE"
                riverctl spawn "systemctl --user start wayland-session.target"
                riverctl spawn "systemctl --user restart vicinae-server"
                riverctl spawn "QS_BAR=river quickshell"
                riverctl spawn "swaybg -i $HOME/Pictures/wallpaper -m fill"
                riverctl spawn "sh -c 'sleep 1; exec nm-applet --indicator'"
              '';
            };
          };
        };
      };
    };
}
