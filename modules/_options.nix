{ lib, ... }:
{
  options.wallpaper-destinations = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Destination paths for wallpapers";
  };

  options.wallpaper = lib.mkOption {
    type = lib.types.str;
    default = "wp5458622-stardew-valley-desktop-wallpapers.png";
    description = "Wallpaper filename from assets/wallpapers/";
  };

  config.theme.active = "vague";
  options.username = lib.mkOption {
    type = lib.types.str;
    description = "Global username used across the evaluation.";
    default = "josh";
  };

}
