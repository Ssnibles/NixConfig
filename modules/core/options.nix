# =============================================================================
# Core Global Options
# =============================================================================
# Defines central system configuration options used across all modules.
# =============================================================================
{ lib, ... }:
{
  nixos.modules.shared =
    { lib, ... }:
    {
      options = {
        username = lib.mkOption {
          type = lib.types.str;
          default = "josh";
          description = "Primary user account name used across system evaluation.";
        };

        wallpaper = lib.mkOption {
          type = lib.types.str;
          default = "blackbird.jpg";
          description = "Active wallpaper filename located in assets/wallpapers/.";
        };

        wallpaper-destinations = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Target user relative paths where active wallpaper should be deployed.";
        };
      };
    };
}
