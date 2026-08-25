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

        hjem.users."${config.username}" = {
          enable = true;
          files = {
            ".config/dwl/autostart" = {
              executable = true;
              text = ''
                #!/usr/bin/env sh

                # Pipe dwl status output (stdin to this script) to FIFO
                rm -f /tmp/dwl-status.fifo
                mkfifo /tmp/dwl-status.fifo
                cat > /tmp/dwl-status.fifo &

                # Session Environment Variables
                export QS_BAR=dwl
                export QT_QPA_PLATFORM=wayland
                export ELECTRON_OZONE_PLATFORM_HINT=wayland
                export MOZ_ENABLE_WAYLAND=1
                export XCURSOR_THEME=Bibata-Modern-Ice
                export XCURSOR_SIZE=24
                export XDG_CURRENT_DESKTOP=dwl
                export XDG_SESSION_DESKTOP=dwl
                export XDG_SESSION_TYPE=wayland

                # D-Bus & Systemd Session Target Initialization
                dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE QT_QPA_PLATFORM ELECTRON_OZONE_PLATFORM_HINT MOZ_ENABLE_WAYLAND XCURSOR_THEME XCURSOR_SIZE
                systemctl --user import-environment WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE QT_QPA_PLATFORM ELECTRON_OZONE_PLATFORM_HINT MOZ_ENABLE_WAYLAND XCURSOR_THEME XCURSOR_SIZE
                systemctl --user start wayland-session.target

                # Restart services to inherit updated graphical environment variables
                systemctl --user restart vicinae-server 2>/dev/null || true

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
