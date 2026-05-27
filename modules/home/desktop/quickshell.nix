{ config, pkgs, lib, ... }:

let
  c = (import ../../../lib/stylix/semantic-colors.nix { stylixColors = config.lib.stylix.colors; }).withHash;
  liveDir = "${config.home.homeDirectory}/NixConfig/live";

  compiledShaders = pkgs.runCommand "quickshell-shaders" {
    nativeBuildInputs = [ pkgs.qt6.qtshadertools ];
  } ''
    mkdir -p $out
    cp ${../../../live/quickshell/shaders/waveform.frag} $out/waveform.frag
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
    # ── Shared components (root level) ──────────────────────────────────
    "quickshell/notifications.qml".source =
      config.lib.file.mkOutOfStoreSymlink "${liveDir}/quickshell/notifications.qml";
    "quickshell/CommandCenter.qml".source =
      config.lib.file.mkOutOfStoreSymlink "${liveDir}/quickshell/CommandCenter.qml";
    "quickshell/Colors.qml".source =
      config.lib.file.mkOutOfStoreSymlink "${liveDir}/quickshell/Colors.qml";
    "quickshell/Pill.qml".source =
      config.lib.file.mkOutOfStoreSymlink "${liveDir}/quickshell/Pill.qml";
    "quickshell/AppIcon.qml".source =
      config.lib.file.mkOutOfStoreSymlink "${liveDir}/quickshell/AppIcon.qml";
    "quickshell/ActionRow.qml".source =
      config.lib.file.mkOutOfStoreSymlink "${liveDir}/quickshell/ActionRow.qml";
    "quickshell/SliderControl.qml".source =
      config.lib.file.mkOutOfStoreSymlink "${liveDir}/quickshell/SliderControl.qml";

    # ── Shaders ─────────────────────────────────────────────────────────
    "quickshell/shaders/waveform.frag.qsb".source =
      "${compiledShaders}/waveform.frag.qsb";
    "quickshell/shaders/waveform.frag".source =
      "${compiledShaders}/waveform.frag";

    # ── Niri subdirectory ───────────────────────────────────────────────
    "quickshell/niri/shell.qml".source =
      config.lib.file.mkOutOfStoreSymlink "${liveDir}/niri/quickshell/shell.qml";
    "quickshell/niri/bar.qml".source =
      config.lib.file.mkOutOfStoreSymlink "${liveDir}/niri/quickshell/bar.qml";

    # ── Hyprland subdirectory ───────────────────────────────────────────
    "quickshell/hyprland/shell.qml".source =
      config.lib.file.mkOutOfStoreSymlink "${liveDir}/hyprland/quickshell/shell.qml";
    "quickshell/hyprland/bar.qml".source =
      config.lib.file.mkOutOfStoreSymlink "${liveDir}/hyprland/quickshell/bar.qml";

    # Quickshell's QML engine doesn't support `import "../"` so shared
    # types must be resolved via same-directory resolution instead.
    "quickshell/niri/Colors.qml".source =
      config.lib.file.mkOutOfStoreSymlink "${liveDir}/quickshell/Colors.qml";
    "quickshell/niri/Pill.qml".source =
      config.lib.file.mkOutOfStoreSymlink "${liveDir}/quickshell/Pill.qml";
    "quickshell/hyprland/Colors.qml".source =
      config.lib.file.mkOutOfStoreSymlink "${liveDir}/quickshell/Colors.qml";
    "quickshell/hyprland/Pill.qml".source =
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
