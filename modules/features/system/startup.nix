# Wayland session and clipboard services.
_: {
  flake.nixosModules.shared =
    {
      pkgs,
      mkWaylandService,
      ...
    }:
    {
      environment.systemPackages = with pkgs; [
        wl-clip-persist
        cliphist
      ];

      systemd.user = {
        targets.wayland-session = {
          description = "Wayland session target";
          bindsTo = [ "graphical-session.target" ];
          wants = [ "graphical-session-pre.target" ];
          after = [ "graphical-session-pre.target" ];
        };

        sockets.speech-dispatcher.enable = false;

        services = {
          # Keep the clipboard alive after the source application exits.
          clipboard-persist = mkWaylandService {
            description = "Persist Wayland clipboard (regular and primary) after source application exits";
            execStart = "${pkgs.wl-clip-persist}/bin/wl-clip-persist --clipboard both";
          };

          cliphist-store-text = mkWaylandService {
            description = "Index text clipboard history with cliphist";
            execStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store";
          };

          cliphist-store-image = mkWaylandService {
            description = "Index image clipboard history with cliphist";
            execStart = "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store";
          };
        };
      };
    };
}
