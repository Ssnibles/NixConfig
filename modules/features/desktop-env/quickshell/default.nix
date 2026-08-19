# =============================================================================
# Quickshell UI Engine Feature
# =============================================================================
# Quickshell widget framework setup, system activation script, and dynamic QML
# color theme singleton generated from active theme palette options.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    { pkgs, config, ... }:
    let
      inherit (config.theme.colors)
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
      config = {
        environment.systemPackages = with pkgs.unstable; [
          quickshell
        ];

        hjem.users."${config.username}" = {
          enable = true;
          files = {
            ".config/quickshell/Colors.qml" = {
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

        system.activationScripts.quickshell-config = ''
          mkdir -p /home/${config.username}/.config/quickshell
          chown -R ${config.username}:users /home/${config.username}/.config/quickshell
          ln -sfn /home/${config.username}/NixConfig/modules/features/desktop-env/quickshell/config/* /home/${config.username}/.config/quickshell/
          chown -h ${config.username}:users /home/${config.username}/.config/quickshell/
        '';
      };
    };
}
