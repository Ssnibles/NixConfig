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
    name: path: lib.nameValuePair name { source = config.lib.file.mkOutOfStoreSymlink path; }
  ) commonQsFiles;

  # Write Colors.qml directly into the repo checkout so the out-of-store
  # symlinks pick it up without an imperative activation script.
  home.file."NixConfig/modules/home/desktop/quickshell/Colors.qml" = {
    text = colorsQml;
    force = true;
  };

  # Reload quickshell after a home-manager switch so Stylix color changes
  # and regenerated Colors.qml are picked up immediately.
  home.activation.reloadQuickshell = lib.hm.dag.entryAfter ["linkGeneration"] ''
    ${pkgs.runtimeShell} -c '${pkgs.unstable.quickshell}/bin/qs -c hyprland ipc call quickshell reload all >/dev/null 2>&1 || true'
  '';

  # Watch the repository QML sources (the actual targets of the out-of-store
  # symlinks) and reload quickshell whenever a .qml file changes.
  systemd.user.services.quickshell-reload-watcher = {
    Unit = {
      Description = "Watch Quickshell QML sources and reload on changes";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = toString (pkgs.writeShellScript "quickshell-reload-watcher" ''
        set -euo pipefail
        WATCH_DIRS=("${qsDir}" "${repoRoot}/modules/home/desktop/hyprland/quickshell")
        RELOAD_CMD="${pkgs.unstable.quickshell}/bin/qs -c hyprland ipc call quickshell reload all"

        ${pkgs.inotify-tools}/bin/inotifywait -m \
          -e modify,move,create,delete \
          -r \
          --include '.*\.qml$' \
          "''${WATCH_DIRS[@]}" \
          2>/dev/null | while read -r _directory _event _filename; do
          # Debounce: keep consuming events while they arrive within 300 ms,
          # then reload once after the burst ends.
          while ${pkgs.coreutils}/bin/timeout 0.3 read -r _directory _event _filename 2>/dev/null; do
            :
          done
          ''${RELOAD_CMD} >/dev/null 2>&1 || true
        done
      '');
      Restart = "always";
      RestartSec = 5;
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };
}
