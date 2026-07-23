{ self, inputs, ... }:
{
  flake.nixosModules.quickshell =
    { pkgs, config, ... }:
    {
      config = {
        environment.systemPackages = with pkgs.unstable; [
          quickshell
        ];

        system.activationScripts.quickshell-config = ''
          mkdir -p /home/${config.username}/.config/quickshell
          ln -sfn /home/${config.username}/NixConfig/modules/features/quickshell/config/shell.qml /home/${config.username}/.config/quickshell/shell.qml
        '';
      };
    };
}
