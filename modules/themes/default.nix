# Theme options.
{ lib, ... }:
{
  nixos.modules.shared =
    { config, ... }:
    let
      colourNames = [
        "bg"
        "bgRaised"
        "bgSubtle"
        "border"
        "fg"
        "fgMid"
        "fgDim"
        "accent"
        "teal"
        "purple"
        "green"
        "yellow"
        "red"
        "orange"
      ];
    in
    {
      options.theme = {
        active = lib.mkOption {
          type = lib.types.enum (builtins.attrNames config.theme.schemes);
          default = "vague";
          description = "Active colour palette scheme name defined in themes/palette.nix.";
        };

        colours = lib.mkOption {
          type = lib.types.submodule {
            options = lib.genAttrs colourNames (_: lib.mkOption { type = lib.types.str; });
          };
          description = "HEX colour attributes injected globally for UI styling.";
        };

        fonts = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = {
            sans = "SF Pro Text";
            monospace = "Maple Mono NR NF";
            serif = "Instrument Serif";
          };
          description = "System typography font family names.";
        };
      };
    };
}
