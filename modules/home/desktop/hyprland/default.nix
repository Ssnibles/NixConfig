{
  config,
  lib,
  ...
}:
let
  repoRoot = "${config.home.homeDirectory}/NixConfig";
  hyprDir = "${repoRoot}/modules/home/desktop/hyprland";

  qsCommonNames = [
    "Colors.qml"
    "Pill.qml"
    "AppIcon.qml"
    "ActionRow.qml"
    "SliderControl.qml"
    "notifications.qml"
    "CommandCenter.qml"
  ];
in
{
  imports = [
    ../hyprlock.nix
    ./wm.nix
    ./idle.nix
    ./waybar.nix
  ];

  # Re-use the base quickshell symlinks in the hyprland config directory
  # so we don't duplicate the source expressions.
  xdg.configFile =
    lib.listToAttrs (
      map (name: {
        name = "quickshell/hyprland/${name}";
        value = {
          source = config.xdg.configFile."quickshell/${name}".source;
        };
      }) qsCommonNames
    )
    // {
      "quickshell/hyprland/shell.qml".source =
        config.lib.file.mkOutOfStoreSymlink "${hyprDir}/quickshell/shell.qml";
      "quickshell/hyprland/bar.qml".source =
        config.lib.file.mkOutOfStoreSymlink "${hyprDir}/quickshell/bar.qml";
    };
}
