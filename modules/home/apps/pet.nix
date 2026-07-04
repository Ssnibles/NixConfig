{
  config,
  ...
}:
{
  xdg.configFile."pet/snippet.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/NixConfig/modules/home/apps/pet/snippet.toml";
  xdg.configFile."pet/config.toml".text = ''
    [General]
      snippetfile = "${config.xdg.configHome}/pet/snippet.toml"
      editor = "nvim"
      selectcmd = "fzf --ansi --layout=reverse --height=40%"
      color = true
      sortby = "recency"
  '';
}
