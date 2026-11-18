# Wallpaper deployment.
_: {
  flake.nixosModules.shared =
    {
      lib,
      config,
      ...
    }:
    {
      config = {
        hjem.users.${config.username} = {
          files = lib.genAttrs config.wallpaper-destinations (_: {
            source = "${../../../assets/wallpapers}/${config.wallpaper}";
          });
        };
      };
    };
}
