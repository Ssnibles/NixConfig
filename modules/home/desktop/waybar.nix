{ config, pkgs, lib, ... }:

let
  liveDir = "${config.home.homeDirectory}/NixConfig/live";
in
{
  programs.waybar = {
    enable = false;
  };

  xdg.configFile = {
    "waybar/config".source = config.lib.file.mkOutOfStoreSymlink "${liveDir}/waybar/config.jsonc";
    "waybar/style.css".source = config.lib.file.mkOutOfStoreSymlink "${liveDir}/waybar/style.css";
  };
}
