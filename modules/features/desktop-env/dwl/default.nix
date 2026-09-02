# =============================================================================
# DWL (dwm for Wayland) Compositor Feature
# =============================================================================
# Lightweight dwl Wayland compositor feature with Quickshell status bar support,
# matching Mango WC keybindings, environment variables, theme palette integration,
# and session autostart routine.
# =============================================================================
{ inputs, ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.features.dwl;
    in
    {
      options.features.dwl.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable DWL Wayland compositor feature.";
      };

      config = lib.mkIf cfg.enable {
        wallpaper-destinations = [ "Pictures/wallpaper" ];
        programs.dwl.enable = true;

        environment.systemPackages = with pkgs; [
          swaybg
          networkmanagerapplet
          wtype
          tesseract
          grim
          slurp
          wl-clipboard
          playerctl
          brightnessctl
          wireplumber
        ];

        programs.dwl.package =
          let
            dwl-base = inputs.dwl.packages.${pkgs.system}.default;
          in
          pkgs.symlinkJoin {
            name = "dwl-${dwl-base.version}";
            paths = [ dwl-base ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              rm $out/bin/dwl
              makeWrapper ${dwl-base}/bin/dwl $out/bin/dwl \
                --run 'has_s=0; for arg in "$@"; do if [ "$arg" = "-s" ]; then has_s=1; break; fi; done; if [ "$has_s" -eq 0 ] && [ -f "$HOME/.config/dwl/autostart" ]; then set -- -s "$HOME/.config/dwl/autostart" "$@"; fi'
            '';
          };

        xdg.portal = {
          enable = true;
          config = {
            common = {
              default = [ "gtk" ];
              "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
              "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
            };
            dwl = {
              default = [ "gtk" ];
              "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
              "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
            };
            wlroots = {
              default = [ "gtk" ];
              "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
              "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
            };
          };
          extraPortals = [
            pkgs.xdg-desktop-portal-gtk
            pkgs.xdg-desktop-portal-wlr
          ];
        };

        hjem.users."${config.username}" = {
          enable = true;
          files = {
            ".config/xdg-desktop-portal-wlr/config" = {
              text = ''
                [screencast]
                max_fps = 60
                chooser_type = simple
                chooser_cmd = ${pkgs.slurp}/bin/slurp -f 'Monitor: %o' -or
                force_mod_linear = 1
              '';
            };
            ".config/dwl/autostart" = {
              executable = true;
              text = ''
                #!/usr/bin/env sh

                # Pipe dwl status output (stdin to this script) to FIFO line-buffered without data-stealing cat process
                rm -f /tmp/dwl-status.fifo
                mkfifo /tmp/dwl-status.fifo
                exec 3<> /tmp/dwl-status.fifo
                stdbuf -oL awk '{print; fflush()}' <&0 > /tmp/dwl-status.fifo &

                # Session Environment Variables
                export QS_BAR=dwl
                export QT_QPA_PLATFORM=wayland
                export ELECTRON_OZONE_PLATFORM_HINT=wayland
                export MOZ_ENABLE_WAYLAND=1
                export XCURSOR_THEME=Bibata-Modern-Ice
                export XCURSOR_SIZE=24
                export XDG_CURRENT_DESKTOP=wlroots:dwl
                export XDG_SESSION_DESKTOP=dwl
                export XDG_SESSION_TYPE=wayland

                # D-Bus & Systemd Session Target Initialization
                dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE QT_QPA_PLATFORM ELECTRON_OZONE_PLATFORM_HINT MOZ_ENABLE_WAYLAND XCURSOR_THEME XCURSOR_SIZE
                systemctl --user import-environment WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE QT_QPA_PLATFORM ELECTRON_OZONE_PLATFORM_HINT MOZ_ENABLE_WAYLAND XCURSOR_THEME XCURSOR_SIZE
                systemctl --user start wayland-session.target

                # Restart services to inherit updated graphical environment variables
                systemctl --user restart xdg-desktop-portal-wlr xdg-desktop-portal pipewire wireplumber vicinae-server 2>/dev/null || true

                # Background Applications
                pkill -x swaybg 2>/dev/null || true
                swaybg -i "$HOME/Pictures/wallpaper" -m fill &
                QS_BAR=dwl quickshell &
                sh -c "sleep 1; exec nm-applet --indicator" &
              '';
            };
          };
        };
      };
    };
}
