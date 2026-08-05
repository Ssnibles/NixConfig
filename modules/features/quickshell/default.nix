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
          };
        };
      };
    };
}
