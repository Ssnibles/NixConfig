{ ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      config,
      ...
    }:
    {
      # Define a user account. Don't forget to set a password with 'passwd'.
      users.users."${config.username}" = {
        isNormalUser = true;
        description = "${config.username} user account";
        extraGroups = [
          "networkmanager"
          "wheel"
          "plugdev"
          "dialout"
        ];
        shell = pkgs.fish;
      };
      hjem.users."${config.username}" = {
        enable = true;
        clobberFiles = true;
      };
    };
}
