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
      cfg = config.features.vicinae;

      inherit (config.theme.colors)
        bg
        bgRaised
        border
        fg
        accent
        teal
        purple
        green
        yellow
        red
        orange
        ;

      clipboard-history-script = pkgs.writeShellScript "vicinae-clipboard-history" ''
        # @vicinae.schemaVersion 1
        # @vicinae.title Clipboard History
        # @vicinae.mode silent
        set -euo pipefail
        selection=$(${pkgs.unstable.vicinae}/bin/vicinae dmenu -p "Clipboard history")
        [ -n "$selection" ] || exit 0
        printf '%s\n' "$selection" | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy
      '';
    in
    {
      options.features.vicinae.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable the Vicinae application launcher daemon with themed styling and clipboard history.";
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = with pkgs.unstable; [ vicinae ];

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
                      "layer": "overlay"
                    }
                  },
                  "snippets": {
                    "enabled": false
                  },
                  "fallbacks": [],
                  "providers": {
                    "files": {
                      "preferences": {
                        "autoIndexing": false
                      },
                      "entrypoints": {
                        "search": {
                          "enabled": false
                        }
                      }
                    }
                  }
                }
              '';
            };
          };
        };

        systemd.user.services.vicinae-server = {
          description = "Vicinae application launcher server";
          wantedBy = [ "wayland-session.target" ];
          after = [ "wayland-session.target" ];
          partOf = [ "wayland-session.target" ];
          path = [ config.system.path ];
          environment = {
            QT_QPA_PLATFORM = "wayland;xcb";
            ELECTRON_OZONE_PLATFORM_HINT = "auto";
          };
          serviceConfig = {
            Type = "simple";
            ExecStartPre = [
              "${pkgs.coreutils}/bin/mkdir -p %h/.local/share/vicinae/snippets"
            ];
            ExecStart = "${pkgs.unstable.vicinae}/bin/vicinae server";
            Restart = "on-failure";
            RestartSec = 2;
          };
        };
      };
    };
}