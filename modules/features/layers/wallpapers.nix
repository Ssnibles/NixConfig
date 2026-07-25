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
