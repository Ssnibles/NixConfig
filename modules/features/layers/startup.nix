{ ... }:
{
  nixos.modules.shared =
    { pkgs, config, ... }:
    {
      environment.systemPackages = with pkgs; [
        wl-clip-persist
        cliphist
      ];

      systemd.user.targets.wayland-session = {
        description = "Wayland session target";
        bindsTo = [ "graphical-session.target" ];
        wants = [ "graphical-session-pre.target" ];
        after = [ "graphical-session-pre.target" ];
      };

      systemd.user.services.clipboard-persist = {
        description = "Persist Wayland clipboard after the source application closes";
        wantedBy = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
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
        after = [ "graphical-session.target" ];
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
        after = [ "graphical-session.target" ];
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
        after = [ "graphical-session.target" ];
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
