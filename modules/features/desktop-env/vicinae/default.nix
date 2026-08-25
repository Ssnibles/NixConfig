# =============================================================================
# Vicinae Application Launcher Feature
# =============================================================================
# Vicinae layer-shell launcher server, clipboard history script extension,
# and generated theme styling.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    { pkgs, lib, config, ... }:
    let
      inherit (config.theme.colors) bg bgRaised bgSubtle border fg fgMid fgDim
        accent teal purple green yellow red orange;

      clipboard-history-script = pkgs.writeShellScript "vicinae-clipboard-history" ''
        # @vicinae.schemaVersion 1
        # @vicinae.title Clipboard History
        # @vicinae.mode silent
        set -euo pipefail
        selection=$(${pkgs.cliphist}/bin/cliphist list | ${pkgs.vicinae}/bin/vicinae dmenu -p "Clipboard history")
        [ -n "$selection" ] || exit 0
        printf '%s\n' "$selection" | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy
      '';
    in
    {
      environment.systemPackages = with pkgs; [ vicinae ];

      hjem.users."${config.username}" = {
        enable = true;
        files = {
          ".local/share/vicinae/scripts/clipboard-history" = {
            source = clipboard-history-script;
            executable = true;
          };
          ".local/share/vicinae/snippets/.keep" = {
            text = "";
          };
          ".local/share/vicinae/themes/nixconfig.toml" = {
            text = ''
              [meta]
              version = 1
              name = "nixconfig"
              description = "Generated from theme colors"
              variant = "dark"

              [colors.core]
              background = "#${bg}"
              foreground = "#${fg}"
              secondary_background = "#${bgRaised}"
              border = "#${border}"
              accent = "#${accent}"

              [colors.accents]
              blue = "#${accent}"
              green = "#${green}"
              magenta = "#${purple}"
              orange = "#${orange}"
              purple = "#${purple}"
              red = "#${red}"
              yellow = "#${yellow}"
              cyan = "#${teal}"
            '';
          };
          ".config/vicinae/settings.json" = {
            text = ''
              {
                "theme": {
                  "dark": {
                    "name": "nixconfig"
                  }
                },
                "launcher_window": {
                  "layer_shell": {
                    "enabled": true,
                    "layer": "top"
                  }
                },
                "snippets": {
                  "enabled": false
                }
              }
            '';
          };
        };
      };

      systemd.user.services.vicinae-server = {
        description = "Vicinae application launcher server";
        wantedBy = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        path = [ config.system.path ];
        environment = {
          QT_QPA_PLATFORM = "wayland;xcb";
          ELECTRON_OZONE_PLATFORM_HINT = "auto";
          XDG_CURRENT_DESKTOP = "Hyprland";
        };
        serviceConfig = {
          Type = "simple";
          ExecStartPre = [
            "${pkgs.coreutils}/bin/mkdir -p %h/.local/share/vicinae/snippets"
            "${pkgs.coreutils}/bin/sleep 1"
          ];
          ExecStart = "${pkgs.vicinae}/bin/vicinae server";
          Restart = "on-failure";
          RestartSec = 2;
        };
      };
    };
}
