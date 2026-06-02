{
  config,
  pkgs,
  lib,
  semanticColors,
  ...
}:

let
  c = semanticColors { colors = config.lib.stylix.colors; };
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
        cp ${./shaders/circleMask.frag} $out/circleMask.frag
        qsb --qt6 $out/waveform.frag -o $out/waveform.frag.qsb
        qsb --qt6 $out/circleMask.frag -o $out/circleMask.frag.qsb
      '';

  colorsQml = ''
    pragma Singleton
    import QtQml
    import QtQuick
    QtObject {
      readonly property color bg: "${c.withHash.bg}"
      readonly property color bgRaised: "${c.withHash.raisedBackground}"
      readonly property color bgSubtle: "${c.withHash.bgSubtle}"
      readonly property color border: "${c.withHash.border}"
      readonly property color fg: "${c.withHash.fg}"
      readonly property color fgMid: "${c.withHash.fgMid}"
      readonly property color fgDim: "${c.withHash.fgDim}"
      readonly property color accent: "${c.withHash.accent}"
      readonly property color teal: "${c.withHash.teal}"
      readonly property color purple: "${c.withHash.purple}"
      readonly property color green: "${c.withHash.green}"
      readonly property color yellow: "${c.withHash.yellow}"
      readonly property color red: "${c.withHash.red}"
      readonly property color orange: "${c.withHash.orange}"
      readonly property color magenta: "${c.withHash.magenta}"
      readonly property color selection: "${c.withHash.selection}"
    }
  '';

  commonQsFiles = {
    "quickshell/notifications.qml" = "${qsDir}/notifications.qml";
    "quickshell/CommandCenter.qml" = "${qsDir}/CommandCenter.qml";
    "quickshell/Colors.qml" = "${qsDir}/Colors.qml";
    "quickshell/Pill.qml" = "${qsDir}/Pill.qml";
    "quickshell/AppIcon.qml" = "${qsDir}/AppIcon.qml";
    "quickshell/ActionRow.qml" = "${qsDir}/ActionRow.qml";
    "quickshell/SliderControl.qml" = "${qsDir}/SliderControl.qml";
    "quickshell/shaders/waveform.frag.qsb" = "${compiledShaders}/waveform.frag.qsb";
    "quickshell/shaders/waveform.frag" = "${compiledShaders}/waveform.frag";
    "quickshell/shaders/circleMask.frag.qsb" = "${compiledShaders}/circleMask.frag.qsb";
    "quickshell/shaders/circleMask.frag" = "${compiledShaders}/circleMask.frag";
  };

in
{
  programs.quickshell = {
    enable = true;
    package = pkgs.unstable.quickshell;
  };

  home.sessionVariables = {
    QML_IMPORT_PATH = "${pkgs.unstable.quickshell}/lib/qt-6/qml";
    QSG_RHI_BACKEND = "vulkan";
    QML_XHR_ALLOW_FILE_READ = "1";
  };

  xdg.configFile = lib.mapAttrs' (
    name: path:
    lib.nameValuePair name { source = config.lib.file.mkOutOfStoreSymlink path; }
  ) commonQsFiles;

  # Write Colors.qml directly into the repo checkout so the out-of-store
  # symlinks pick it up without an imperative activation script.
  home.file."NixConfig/modules/home/desktop/quickshell/Colors.qml".text = colorsQml;
}
