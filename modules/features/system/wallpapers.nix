# =============================================================================
# Wallpaper Deployment Feature
# =============================================================================
# Deploys active wallpaper asset to defined target destinations via Hjem.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
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
