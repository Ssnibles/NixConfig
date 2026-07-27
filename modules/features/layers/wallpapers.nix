{ self, inputs, ... }:
{
  flake.nixosModules.wallpapers =
    {
      lib,
      config,
      ...
    }:
    {
      config = {
        hjem.users."${config.username}" = {
          enable = true;
          files = lib.genAttrs config.wallpaper-destinations (_: {
            source = "${../../../assets/wallpapers}/${config.wallpaper}";
          });
        };
      };
    };
}
