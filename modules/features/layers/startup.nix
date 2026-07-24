{ self, inputs, ... }:
{
  flake.nixosModules.startup =
    { pkgs, lib, config, ... }:
    {
      systemd.user.services.vicinae-server = {
        description = "Vicinae application launcher server";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        path = [ config.system.path ];
        environment = {
          QT_QPA_PLATFORM = "wayland";
        };
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.vicinae}/bin/vicinae server";
          Restart = "on-failure";
          RestartSec = 2;
        };
      };
    };
}
