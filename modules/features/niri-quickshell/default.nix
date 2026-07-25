{ self, inputs, ... }:
{
  flake.nixosModules.niri-quickshell =
    { pkgs, config, ... }:
    {
      config = {
        environment.systemPackages = with pkgs.unstable; [
          quickshell
        ];

        hjem.users."${config.username}" = {
          enable = true;
          files.".config/quickshell/niri-bar.qml".source = ./config/bar.qml;
        };
      };
    };
}
