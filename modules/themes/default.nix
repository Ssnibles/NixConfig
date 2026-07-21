{ lib, ... }:
{
  flake.nixosModules.theme = { lib, ... }: {
    options.theme = {
      active = lib.mkOption {
        type = lib.types.str;
        default = "catppuccin-mocha";
        description = "The active theme name from themes/palette.nix";
      };

      colors = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        description = "Color attributes for the currently active theme";
      };

      fonts = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          sans = "Inter";
          monospace = "JetBrainsMono Nerd Font";
        };
      };
    };
  };
}
