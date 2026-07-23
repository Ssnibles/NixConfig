{ self, inputs, ... }:
{
  flake.nixosModules.quickshell =
    { pkgs, lib, config, ... }:
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
