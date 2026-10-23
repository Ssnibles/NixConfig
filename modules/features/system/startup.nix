# Wayland session and clipboard services.
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

      systemd.user.sockets.speech-dispatcher.enable = false;

      # Keep the clipboard alive after the source application exits.
      systemd.user.services.clipboard-persist = {
        description = "Persist Wayland clipboard (regular and primary) after source application exits";
        wantedBy = [ "wayland-session.target" ];
        after = [ "wayland-session.target" ];
        partOf = [ "wayland-session.target" ];
        path = [ config.system.path ];
        startLimitBurst = 0;
        startLimitIntervalSec = 0;
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.wl-clip-persist}/bin/wl-clip-persist --clipboard both";
          Restart = "on-failure";
          RestartSec = 2;
        };
      };

      systemd.user.services.cliphist-store-text = {
        description = "Index text clipboard history with cliphist";
        wantedBy = [ "wayland-session.target" ];
        after = [ "wayland-session.target" ];
        partOf = [ "wayland-session.target" ];
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
        description = "Index image clipboard history with cliphist";
        wantedBy = [ "wayland-session.target" ];
        after = [ "wayland-session.target" ];
        partOf = [ "wayland-session.target" ];
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
