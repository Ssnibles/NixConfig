{
  self,
  inputs,
  config,
  ...
}:
{
  flake.nixosModules.user =
    { pkgs, lib, ... }:
    {
      # Define a user account. Don't forget to set a password with ‘passwd’.
      users.users."${config.username}" = {
        isNormalUser = true;
        description = "${config.username} user account";
        extraGroups = [
          "networkmanager"
          "wheel"
          "docker"
          "dialout"
        ];
        shell = pkgs.zsh;
      };
      hjem.users."${config.username}".enable = true;
    };
}
