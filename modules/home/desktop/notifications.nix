{ config, pkgs, ... }:

let
  liveDir = "${config.home.homeDirectory}/NixConfig/live";
in
{
  programs.quickshell = {
    enable = true;
    package = pkgs.unstable.quickshell;
  };

  home.sessionVariables.QML2_IMPORT_PATH = "${pkgs.unstable.quickshell}/lib/qt-6/qml";

  xdg.configFile."quickshell/shell.qml".source =
    config.lib.file.mkOutOfStoreSymlink "${liveDir}/quickshell/shell.qml";
}
