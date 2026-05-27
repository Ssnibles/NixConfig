{
  config,
  pkgs,
  lib,
  ...
}:

let
  c =
    (import ../../../../lib/stylix/semantic-colors.nix { stylixColors = config.lib.stylix.colors; })
    .withHash;
  repoRoot = "${config.home.homeDirectory}/NixConfig";
  qsDir = "${repoRoot}/modules/home/desktop/quickshell";

  compiledShaders =
    pkgs.runCommand "quickshell-shaders"
      {
        nativeBuildInputs = [ pkgs.qt6.qtshadertools ];
      }
      ''
        mkdir -p $out
        cp ${./shaders/waveform.frag} $out/waveform.frag
        qsb --qt6 $out/waveform.frag -o $out/waveform.frag.qsb
      '';

in
{
  programs.quickshell = {
    enable = true;
    package = pkgs.unstable.quickshell;
  };

  home.sessionVariables = {
    QML2_IMPORT_PATH = "${pkgs.unstable.quickshell}/lib/qt-6/qml";
    QSG_RENDERER = "opengl";
    QML_XHR_ALLOW_FILE_READ = "1";
  };

  xdg.configFile = {
    "quickshell/notifications.qml".source =
      config.lib.file.mkOutOfStoreSymlink "${qsDir}/notifications.qml";
    "quickshell/CommandCenter.qml".source =
      config.lib.file.mkOutOfStoreSymlink "${qsDir}/CommandCenter.qml";
    "quickshell/Colors.qml".source = config.lib.file.mkOutOfStoreSymlink "${qsDir}/Colors.qml";
    "quickshell/Pill.qml".source = config.lib.file.mkOutOfStoreSymlink "${qsDir}/Pill.qml";
    "quickshell/AppIcon.qml".source = config.lib.file.mkOutOfStoreSymlink "${qsDir}/AppIcon.qml";
    "quickshell/ActionRow.qml".source = config.lib.file.mkOutOfStoreSymlink "${qsDir}/ActionRow.qml";
    "quickshell/SliderControl.qml".source =
      config.lib.file.mkOutOfStoreSymlink "${qsDir}/SliderControl.qml";

    "quickshell/shaders/waveform.frag.qsb".source = "${compiledShaders}/waveform.frag.qsb";
    "quickshell/shaders/waveform.frag".source = "${compiledShaders}/waveform.frag";
  };

  home.activation.writeQuickshellColors = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    colors_dir="${qsDir}"
    mkdir -p "$colors_dir"
    cat > "$colors_dir/Colors.qml" << QMLEOF
    import QtQml
    import QtQuick
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
