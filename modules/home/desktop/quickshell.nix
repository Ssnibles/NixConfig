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
    "quickshell/Colors.qml".source =
      config.lib.file.mkOutOfStoreSymlink "${liveDir}/quickshell/Colors.qml";
    "quickshell/Pill.qml".source =
      config.lib.file.mkOutOfStoreSymlink "${liveDir}/quickshell/Pill.qml";
  };

  home.activation.writeQuickshellColors = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    colors_dir="$HOME/NixConfig/live/quickshell"
    mkdir -p "$colors_dir"
    cat > "$colors_dir/Colors.qml" << QMLEOF
    import QtQml
    import QtQuick
    // Colors generated from Stylix. Rebuild to refresh palette.
    QtObject {
      readonly property color bg: "${c.bg}"
      readonly property color bgRaised: "${c.raisedBackground}"
      readonly property color bgSubtle: "${c.bgSubtle}"
      readonly property color border: "${c.border}"
      readonly property color fg: "${c.fg}"
      readonly property color fgMid: "${c.fgMid}"
      readonly property color fgDim: "${c.fgDim}"
      readonly property color accent: "${c.accent}"
      readonly property color teal: "${c.teal}"
      readonly property color purple: "${c.purple}"
      readonly property color green: "${c.green}"
      readonly property color yellow: "${c.yellow}"
      readonly property color red: "${c.red}"
      readonly property color orange: "${c.orange}"
      readonly property color magenta: "${c.magenta}"
      readonly property color selection: "${c.selection}"
    }
    QMLEOF
  '';
}
