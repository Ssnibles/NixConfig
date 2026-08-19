# =============================================================================
# Primary User Account Feature
# =============================================================================
# Configuration for primary user account (`josh`), system groups, and Hjem home engine.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    {
      config,
      ...
    }:
    {
      # System groups
      users.groups.plugdev = { };

      # Primary user account definition
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

      # Hjem user configuration root
      hjem.users.${config.username} = {
        enable = true;
        clobberFiles = true;
      };
    };
}
