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
  shellName = "default";
  wallpaper = toString (import ../../../../lib/stylix/themes.nix).wallpaper;

  reloadQuickshellScript = pkgs.writeShellScriptBin "qs-reload" ''
    echo "Reloading quickshell..."
    if ! ${pkgs.unstable.quickshell}/bin/qs -c default ipc call quickshell reload all 2>/dev/null; then
      echo "Quickshell not running, starting..."
      ${pkgs.unstable.quickshell}/bin/qs -c default &
      disown
    fi
    echo "Quickshell reloaded"
  '';

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
      readonly property string wallpaper: "file://${wallpaper}"
    }
  '';

  qsFiles = {
    "quickshell/${shellName}/shell.qml" = "${qsDir}/shell.qml";
    "quickshell/${shellName}/bar.qml" = "${qsDir}/bar.qml";
    "quickshell/${shellName}/notifications.qml" = "${qsDir}/notifications.qml";
    "quickshell/${shellName}/CommandCenter.qml" = "${qsDir}/CommandCenter.qml";
    "quickshell/${shellName}/LockScreen.qml" = "${qsDir}/LockScreen.qml";
    "quickshell/${shellName}/Colors.qml" = "${qsDir}/Colors.qml";
    "quickshell/${shellName}/Pill.qml" = "${qsDir}/Pill.qml";
    "quickshell/${shellName}/AppIcon.qml" = "${qsDir}/AppIcon.qml";
    "quickshell/${shellName}/ActionRow.qml" = "${qsDir}/ActionRow.qml";
    "quickshell/${shellName}/SliderControl.qml" = "${qsDir}/SliderControl.qml";
  };

in
{
  programs.quickshell = {
    enable = true;
    package = pkgs.unstable.quickshell;
  };

  home.packages = [ reloadQuickshellScript ];

  home.sessionVariables = {
    QML_IMPORT_PATH = "${pkgs.unstable.quickshell}/lib/qt-6/qml";
    QSG_RHI_BACKEND = "vulkan";
    QML_XHR_ALLOW_FILE_READ = "1";
  };

  xdg.configFile = lib.mapAttrs' (
    name: path: lib.nameValuePair name { source = config.lib.file.mkOutOfStoreSymlink path; }
  ) qsFiles;

  # Write Colors.qml directly into the repo checkout so the out-of-store
  # symlinks pick it up without an imperative activation script.
  home.file."NixConfig/modules/home/desktop/quickshell/Colors.qml" = {
    text = colorsQml;
    force = true;
  };

  # Reload quickshell after a home-manager switch so Stylix color changes
  # and regenerated Colors.qml are picked up immediately.
  home.activation.reloadQuickshell = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    ${pkgs.runtimeShell} -c '
      if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        ${pkgs.procps}/bin/pkill -f "quickshell" || true
        sleep 0.5
        ${pkgs.unstable.quickshell}/bin/qs -c default &
        disown
      fi
    '
  '';

  # The QML files used to be symlinked directly into ~/.config/quickshell/ and
  # again into ~/.config/quickshell/hyprland/. Now everything lives under the
  # default shell directory, so remove any stale symlinks/directories left
  # behind by earlier generations.
  home.activation.cleanupOldQuickshellFiles = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    ${pkgs.coreutils}/bin/rm -f \
      "${config.xdg.configHome}/quickshell/notifications.qml" \
      "${config.xdg.configHome}/quickshell/CommandCenter.qml" \
      "${config.xdg.configHome}/quickshell/Colors.qml" \
      "${config.xdg.configHome}/quickshell/Pill.qml" \
      "${config.xdg.configHome}/quickshell/AppIcon.qml" \
      "${config.xdg.configHome}/quickshell/ActionRow.qml" \
      "${config.xdg.configHome}/quickshell/SliderControl.qml" \
      2>/dev/null || true
    ${pkgs.coreutils}/bin/rm -rf "${config.xdg.configHome}/quickshell/hyprland" 2>/dev/null || true
  '';

  # Watch the repository QML sources (the actual targets of the out-of-store
  # symlinks) and restart quickshell whenever a .qml file changes.
  systemd.user.services.quickshell-reload-watcher = {
    Unit = {
      Description = "Watch Quickshell QML sources and restart on changes";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = toString (
        pkgs.writeShellScript "quickshell-reload-watcher" ''
          set -euo pipefail
          WATCH_DIRS=("${qsDir}")

          for dir in "''${WATCH_DIRS[@]}"; do
            if [ ! -d "$dir" ]; then
              echo "Watch directory does not exist: $dir" >&2
              exit 1
            fi
          done

          ${pkgs.inotify-tools}/bin/inotifywait -m \
            -e close_write,move,create,delete \
            -r \
            --include '.*\.qml$' \
            "''${WATCH_DIRS[@]}" \
            2>/dev/null | while read -r _directory _event _filename; do
            # Debounce: keep consuming events while they arrive within 500 ms,
            # then restart once after the burst ends.
            while ${pkgs.coreutils}/bin/timeout 0.5 read -r _directory _event _filename 2>/dev/null; do
              :
            done
            echo "QML files changed, reloading quickshell..."
            if ! ${pkgs.unstable.quickshell}/bin/qs -c default ipc call quickshell reload all 2>/dev/null; then
              ${pkgs.unstable.quickshell}/bin/qs -c default &
              disown
            fi
          done
        ''
      );
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
