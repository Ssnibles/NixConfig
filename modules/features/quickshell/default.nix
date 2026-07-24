{ self, inputs, ... }:
{
  flake.nixosModules.quickshell =
    { pkgs, config, ... }:
    {
      config = {
        environment.systemPackages = with pkgs.unstable; [
          quickshell
        ];

        hjem.users."${config.username}" = {
          enable = true;
          files = {
            ".config/quickshell/shell.qml".source = ./config/shell.qml;
          };
        };
      };
    };
}
