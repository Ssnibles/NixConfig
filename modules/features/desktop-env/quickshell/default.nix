# =============================================================================
# Quickshell UI Engine Feature
# =============================================================================
# Quickshell widget framework setup, system activation script, and dynamic QML
# colour theme singleton generated from active theme palette options.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    { pkgs, lib, config, ... }:
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
      options.features.quickshell.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable the Quickshell UI engine (bars, command centre, lock screen, notifications).";
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = with pkgs.unstable; [
          quickshell
        ];

        hjem.users."${config.username}" = {
          enable = true;
          files = {
            ".config/quickshell/Colours.qml" = {
              text = ''
                pragma Singleton

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

        # Symlink every QML/profile file into ~/.config/quickshell. `contents`
        # mode prunes only links that point back into the source tree, so the
        # Hjem-managed Colours.qml (a /nix/store link) is left alone.
        nixos.liveLinks."quickshell-config" = {
          source = "${config.nixos.configRepo}/modules/features/desktop-env/quickshell/config";
          target = ".config/quickshell";
          contents = true;
        };
      };
    };
}
