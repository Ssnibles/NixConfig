# =============================================================================
# Syncthing Continuous File Synchronization Feature
# =============================================================================
# Peer-to-peer decentralized folder synchronization optimized for laptop battery.
# =============================================================================
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
        description = "Enable Syncthing peer-to-peer folder synchronization with the homeserver.";
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

          # Keep dynamically added or auto-accepted devices and folders
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
              "Hermes" = {
                id = "tuyqy-adrau";
                path = "/home/${config.username}/Hermes";
                devices = [ "homeserver" ];
              };
            };

            options = {
              # Laptop battery optimization: disable battery-draining internet relaying & global discovery
              globalAnnounceEnabled = false;
              relaysEnabled = false;
              natEnabled = false;
              localAnnounceEnabled = true; # Direct discovery on local Wi-Fi
              urAccepted = -1; # Disable anonymous usage reporting
              defaultFolderPath = "~";
            };
            gui = {
              theme = "dark";
            };
          };
        };

        systemd.services.syncthing.serviceConfig.WorkingDirectory = "/home/${config.username}";

        # Defer syncthing to graphical.target to eliminate ~1.5s blocking delay during early boot
        systemd.services.syncthing.wantedBy = lib.mkForce [ "graphical.target" ];
        systemd.services.syncthing-init.wantedBy = lib.mkForce [ "graphical.target" ];
      };
    };
}
