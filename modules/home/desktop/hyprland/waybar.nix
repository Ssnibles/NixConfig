{
  config,
  ...
}:
let
  repoRoot = "${config.home.homeDirectory}/NixConfig";
  hyprDir = "${repoRoot}/modules/home/desktop/hyprland";
in
{
  xdg.configFile."waybar/config".source =
    config.lib.file.mkOutOfStoreSymlink "${hyprDir}/waybar/config.jsonc";
  xdg.configFile."waybar/style.css".source =
    config.lib.file.mkOutOfStoreSymlink "${hyprDir}/waybar/style.css";
  xdg.configFile."waybar/special-workspace-indicator.sh".source =
    config.lib.file.mkOutOfStoreSymlink "${hyprDir}/waybar/special-workspace-indicator.sh";
}
