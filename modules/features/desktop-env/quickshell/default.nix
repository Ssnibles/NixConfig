# Quickshell.
_: {
  flake.nixosModules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.features.quickshell;

      inherit (config.theme.colours)
        bg
        bgRaised
        bgSubtle
        border
        fg
        fgMid
        fgDim
        accent
        teal
        purple
        green
        yellow
        red
        orange
        ;
    in
    {
      options.features.quickshell.enable = lib.mkEnableOption "the Quickshell UI engine (bars, command centre, lock screen, notifications)";

      config = lib.mkIf cfg.enable {
        environment.systemPackages = with pkgs; [
          quickshell

          # Restart helper. A script rather than an inline command because
          # keybinds and navi entries run through `sh -c`, so their own command
          # line holds "quickshell" and pkill would kill the wrapper first.
          (writeShellScriptBin "qs-restart" ''
            set -eu

            # Nothing to kill still leaves a fresh instance behind, so a failed
            # match is not an error.
            ${pkgs.procps}/bin/pkill -f quickshell || true
            ${pkgs.util-linux}/bin/setsid quickshell >/dev/null 2>&1 &
          '')
        ];

        hjem.users."${config.username}" = {
          enable = true;
          files = {
            ".config/quickshell/Colours.qml" = {
              text = ''
                pragma Singleton
                pragma ComponentBehavior: Bound

                import Quickshell
                import QtQuick

                Singleton {
                  readonly property string monoFont: "${config.theme.fonts.monospace}"
                  readonly property string sansFont: "${config.theme.fonts.sans}"
                  readonly property string serifFont: "${config.theme.fonts.serif}"

                  readonly property color bg:       "#${bg}"
                  readonly property color bgRaised: "#${bgRaised}"
                  readonly property color bgSubtle: "#${bgSubtle}"
                  readonly property color border:   "#${border}"
                  readonly property color fg:       "#${fg}"
                  readonly property color fgMid:    "#${fgMid}"
                  readonly property color fgDim:    "#${fgDim}"
                  readonly property color accent:   "#${accent}"
                  readonly property color teal:     "#${teal}"
                  readonly property color purple:   "#${purple}"
                  readonly property color green:    "#${green}"
                  readonly property color yellow:   "#${yellow}"
                  readonly property color red:      "#${red}"
                  readonly property color orange:   "#${orange}"
                }
              '';
            };
          };
        };

        # Link the QML files into ~/.config/quickshell. Only links back into the
        # source tree are pruned, so the Hjem managed Colours.qml is left alone.
        nixos.liveLinks."quickshell-config" = {
          source = "${config.nixos.configRepo}/modules/features/desktop-env/quickshell/config";
          target = ".config/quickshell";
          contents = true;
        };
      };
    };
}
