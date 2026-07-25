{ lib, ... }:
{
  options.wallpaper-destinations = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    description = "Destination paths for wallpapers";
  };

  config.theme.active = "vague";
  options.username = lib.mkOption {
    type = lib.types.str;
    description = "Global username used across the evaluation.";
    default = "josh";
  };

}
