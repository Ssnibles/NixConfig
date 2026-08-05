{ ... }:
{
  nixos.modules.shared =
    { pkgs, lib, config, ... }:
    let
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
      environment.systemPackages = with pkgs; [
        wl-clip-persist
        cliphist
      ];

      hjem.users.${config.username} = {
        enable = true;
        files = {
          ".local/share/vicinae/scripts/clipboard-history" = {
            source = clipboard-history-script;
            executable = true;
          };
        };
      };

      systemd.user.services.vicinae-server = {
        description = "Vicinae application launcher server";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        path = [ config.system.path ];
        environment = { };
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.vicinae}/bin/vicinae server";
          Restart = "on-failure";
          RestartSec = 2;
        };
      };

      systemd.user.services.clipboard-persist = {
        description = "Persist Wayland clipboard after the source application closes";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        path = [ config.system.path ];
        startLimitBurst = 0;
        startLimitIntervalSec = 0;
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.wl-clip-persist}/bin/wl-clip-persist --clipboard regular";
          Restart = "on-failure";
          RestartSec = 2;
        };
      };

      systemd.user.services.clipboard-persist-primary = {
        description = "Persist Wayland primary selection after the source application closes";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        path = [ config.system.path ];
        startLimitBurst = 0;
        startLimitIntervalSec = 0;
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.wl-clip-persist}/bin/wl-clip-persist --clipboard primary";
          Restart = "on-failure";
          RestartSec = 2;
        };
      };

      systemd.user.services.cliphist-store-text = {
        description = "Store text clipboard history with cliphist";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        path = [ config.system.path ];
        startLimitBurst = 0;
        startLimitIntervalSec = 0;
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store";
          Restart = "on-failure";
          RestartSec = 2;
        };
      };

      systemd.user.services.cliphist-store-image = {
        description = "Store image clipboard history with cliphist";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        path = [ config.system.path ];
        startLimitBurst = 0;
        startLimitIntervalSec = 0;
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store";
          Restart = "on-failure";
          RestartSec = 2;
        };
      };
    };
}
