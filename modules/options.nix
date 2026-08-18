{ lib, ... }:
{
  nixos.modules.shared =
    { lib, ... }:
    {
      options.wallpaper-destinations = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Destination paths for wallpapers";
      };

      options.wallpaper = lib.mkOption {
        type = lib.types.str;
        default = "sheppard.jpg";
        description = "Wallpaper filename from assets/wallpapers/";
      };

      options.username = lib.mkOption {
        type = lib.types.str;
        description = "Global username used across the evaluation.";
        default = "josh";
      };

      config.theme.active = "vague";
    };
}
