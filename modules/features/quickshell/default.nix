{ ... }:
{
  nixos.modules.shared =
    { pkgs, config, ... }:
    {
      config = {
        environment.systemPackages = with pkgs.unstable; [
          quickshell
        ];

        hjem.users."${config.username}" = {
          enable = true;
          files = {
            ".config/quickshell/shell.qml" = {
              source = ./config/shell.qml;
            };
            ".config/quickshell/mangowc-bar.qml" = {
              source = ./config/mangowc-bar.qml;
            };
            ".config/quickshell/niri-bar.qml" = {
              source = ./config/niri-bar.qml;
            };
            ".config/quickshell/NotificationOverlay.qml" = {
              source = ./config/NotificationOverlay.qml;
            };
            ".config/quickshell/Utils.js" = {
              source = ./config/Utils.js;
            };
            ".config/quickshell/Pill.qml" = {
              source = ./config/Pill.qml;
            };
            ".config/quickshell/Tooltip.qml" = {
              source = ./config/Tooltip.qml;
            };
            ".config/quickshell/Colors.qml" = {
              text = ''
                pragma Singleton
                import QtQuick

                QtObject {
                  readonly property color bg: "#${config.theme.colors.bg}"
                  readonly property color bgRaised: "#${config.theme.colors.bgRaised}"
                  readonly property color bgSubtle: "#${config.theme.colors.bgSubtle}"
                  readonly property color border: "#${config.theme.colors.border}"
                  readonly property color fg: "#${config.theme.colors.fg}"
                  readonly property color fgMid: "#${config.theme.colors.fgMid}"
                  readonly property color fgDim: "#${config.theme.colors.fgDim}"
                  readonly property color accent: "#${config.theme.colors.accent}"
                  readonly property color teal: "#${config.theme.colors.teal}"
                  readonly property color purple: "#${config.theme.colors.purple}"
                  readonly property color green: "#${config.theme.colors.green}"
                  readonly property color yellow: "#${config.theme.colors.yellow}"
                  readonly property color red: "#${config.theme.colors.red}"
                  readonly property color orange: "#${config.theme.colors.orange}"
                }
              '';
            };
          };
        };
      };
    };
}
