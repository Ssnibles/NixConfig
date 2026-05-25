{ config, pkgs, lib, ... }:

let
  c = (import ../../../lib/stylix/semantic-colors.nix { stylixColors = config.lib.stylix.colors; }).withHash;
  liveDir = "${config.home.homeDirectory}/NixConfig/live";
in
{
  programs.quickshell = {
    enable = true;
    package = pkgs.unstable.quickshell;
  };

  home.sessionVariables.QML2_IMPORT_PATH = "${pkgs.unstable.quickshell}/lib/qt-6/qml";

  xdg.configFile = {
    "quickshell/shell.qml".source =
      config.lib.file.mkOutOfStoreSymlink "${liveDir}/quickshell/shell.qml";
    "quickshell/bar.qml".source =
      config.lib.file.mkOutOfStoreSymlink "${liveDir}/quickshell/bar.qml";
    "quickshell/notifications.qml".source =
      config.lib.file.mkOutOfStoreSymlink "${liveDir}/quickshell/notifications.qml";
    "quickshell/colors.js".source =
      config.lib.file.mkOutOfStoreSymlink "${liveDir}/quickshell/colors.js";
  };

  home.activation.writeQuickshellColors = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    colors_dir="$HOME/NixConfig/live/quickshell"
    mkdir -p "$colors_dir"
    cat > "$colors_dir/colors.js" << JSEOF
    // Colors generated from Stylix. Rebuild to refresh palette.
    var bg = "${c.bg}";
    var bgRaised = "${c.raisedBackground}";
    var bgSubtle = "${c.bgSubtle}";
    var border = "${c.border}";
    var fg = "${c.fg}";
    var fgMid = "${c.fgMid}";
    var fgDim = "${c.fgDim}";
    var accent = "${c.accent}";
    var teal = "${c.teal}";
    var purple = "${c.purple}";
    var green = "${c.green}";
    var yellow = "${c.yellow}";
    var red = "${c.red}";
    var orange = "${c.orange}";
    var magenta = "${c.magenta}";
    var selection = "${c.selection}";
    JSEOF
  '';
}
