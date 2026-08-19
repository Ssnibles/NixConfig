{ ... }:
{
  nixos.modules.shared =
    {
      config,
      ...
    }:
    {
      # Create system groups
      users.groups.plugdev = { };

      # Define a user account.
      users.users."${config.username}" = {
        isNormalUser = true;
        description = "${config.username} user account";
        extraGroups = [
          "networkmanager"
          "wheel"
          "plugdev"
          "dialout"
        ];
      };
      hjem.users."${config.username}" = {
        enable = true;
        clobberFiles = true;
      };
    };
}
