{ self, inputs, ... }:
{
  flake.nixosModules.wallpapers =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      options.wallpaper-destinations = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Destination paths for wallpapers";
      };

      config = {
        hjem.users."${config.username}" = {
          enable = true;
          files = lib.genAttrs config.wallpaper-destinations (_: {
            source = pkgs.runCommand "wallpapers" { } ''
              mkdir -p $out
              cp -r ${../../../assets/wallpapers}/* $out/
            '';
          });
        };
      };
    };
}
