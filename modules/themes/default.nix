# Theme options.
{ ... }:
{
  nixos.modules.shared =
    { lib, ... }:
    {
      options.theme = {
        active = lib.mkOption {
          type = lib.types.enum [
            "catppuccin-mocha"
            "gruvbox-dark"
            "default-dark"
            "default-light"
            "gruvbox-dark-hard"
            "gruvbox-light-hard"
            "rose-pine"
            "rose-pine-moon"
            "rose-pine-dawn"
            "everforest-light"
            "vague"
          ];
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
