# =============================================================================
# Theme Engine Option Schema
# =============================================================================
# Exposes theme selection options (active theme palette, colours, and fonts).
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    { lib, ... }:
    {
      options.theme = {
        active = lib.mkOption {
          type = lib.types.str;
          default = "vague";
          description = "Active colour palette scheme name defined in themes/palette.nix.";
        };

        colours = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
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
