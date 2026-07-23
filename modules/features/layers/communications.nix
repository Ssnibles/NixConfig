{ self, inputs, ... }:
{
  flake.nixosModules.communications =
    { pkgs, lib, ... }:
    {
      config = {
        environment.systemPackages = with pkgs.unstable; [
          vesktop
          (element-desktop.override {
            commandLineArgs = "--password-store=gnome-libsecret";
          })
        ];
      };

    };
}
