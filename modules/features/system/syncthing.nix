# Syncthing file synchronisation.
{ ... }:
{
  nixos.modules.shared =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.features.syncthing;
    in
    {
      options.features.syncthing.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Syncthing peer-to-peer folder synchronisation with the homeserver.";
      };

      config = lib.mkIf cfg.enable {
        services.syncthing = {
          enable = true;
          user = config.username;
          group = "users";
          dataDir = "/home/${config.username}/Sync";
          configDir = "/home/${config.username}/.config/syncthing";
          guiAddress = "127.0.0.1:8384";
          openDefaultPorts = true;

          # Keep devices and folders that were added or accepted at runtime.
          overrideDevices = false;
          overrideFolders = false;

          settings = {
            devices = {
              "homeserver" = {
                id = "4V7XZFM-QEHVMHV-OYQXCV2-WBDIHJI-WYOPD46-KHIOD22-352EP6X-FY3DEAB";
                addresses = [
                  "tcp://homeserver:22000"
                  "dynamic"
                ];
                autoAcceptFolders = true;
              };
            };

            folders = {
              "Documents" = {
                id = "pfqwn-dke5x";
                path = "/home/${config.username}/Documents";
                devices = [ "homeserver" ];
              };
            };

            options = {
              # Battery saving: no internet relaying or global discovery.
              globalAnnounceEnabled = false;
              relaysEnabled = false;
              natEnabled = false;
              localAnnounceEnabled = true; # Discovery on the local network.
              urAccepted = -1; # No usage reporting.
              defaultFolderPath = "~";
            };
            gui = {
              theme = "dark";
            };
          };
        };

        systemd.services.syncthing.serviceConfig.WorkingDirectory = "/home/${config.username}";

        # Start at graphical.target so early boot is not delayed.
        systemd.services.syncthing.wantedBy = lib.mkForce [ "graphical.target" ];
        systemd.services.syncthing-init.wantedBy = lib.mkForce [ "graphical.target" ];
      };
    };
}
