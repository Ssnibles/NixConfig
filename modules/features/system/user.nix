# Primary user account.
{ ... }:
{
  nixos.modules.shared =
    {
      config,
      ...
    }:
    {
      users.groups.plugdev = { };

      users.users.${config.username} = {
        isNormalUser = true;
        description = "${config.username} user account";
        extraGroups = [
          "networkmanager"
          "wheel"
          "plugdev"
          "dialout"
        ];
      };

      hjem.users.${config.username} = {
        enable = true;
        clobberFiles = true;
      };

      # Hjem calls nix-store during update-state to register garbage collection
      # roots. Its service has a small PATH, so nix-store is missing and the
      # roots are skipped. Add the Nix package to the service PATH.
      systemd.services."hjem-update-state@".path = [ config.nix.package ];
    };
}
