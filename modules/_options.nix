{ lib, ... }:
{
  config.theme.active = "catppuccin-mocha";
  options.username = lib.mkOption {
    type = lib.types.str;
    description = "Global username used across the evaluation.";
    default = "josh";
  };

}
