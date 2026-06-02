{
  config,
  ...
}:
{
  xdg.configFile."pet/snippet.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/NixConfig/modules/home/apps/pet/snippet.toml";
  xdg.configFile."pet/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/NixConfig/modules/home/apps/pet/config.toml";
}
