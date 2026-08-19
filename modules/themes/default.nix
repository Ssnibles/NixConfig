# =============================================================================
# Theme Engine Option Schema
# =============================================================================
# Exposes theme selection options (active theme palette, colors, and fonts).
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
          description = "Active color palette scheme name defined in themes/palette.nix.";
        };

        colors = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          description = "HEX color attributes injected globally for UI styling.";
        };

        fonts = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = {
            sans = "SF Pro Text";
            monospace = "JetBrainsMono Nerd Font";
            serif = "Instrument Serif";
          };
          description = "System typography font family names.";
        };
      };
    };
}
