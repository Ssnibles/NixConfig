{ lib, ... }:
{
  options.username = lib.mkOption {
    type = lib.types.str;
    description = "Global username used across the evaluation.";
    default = "jingus";
  };
}
