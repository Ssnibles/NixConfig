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
    {
      services.syncthing = {
        enable = true;
        user = config.username;
        group = "users";
        dataDir = "/home/${config.username}/Sync";
        configDir = "/home/${config.username}/.config/syncthing";
        guiAddress = "127.0.0.1:8384";
        openDefaultPorts = true;

        settings = {
          options = {
            # Laptop battery optimization: disable battery-draining internet relaying & global discovery
            globalAnnounceEnabled = false;
            relaysEnabled = false;
            natEnabled = false;
            localAnnounceEnabled = true; # Direct discovery on local Wi-Fi
            urAccepted = -1; # Disable anonymous usage reporting
          };
          gui = {
            theme = "dark";
          };
        };
      };
    };
}
