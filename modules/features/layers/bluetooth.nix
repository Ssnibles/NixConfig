{ self, inputs, ... }:
{
  flake.nixosModules.bluetooth =
    { pkgs, lib, ... }:
    {
      environment.systemPackages = with pkgs; [
        blueman
      ];

      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings.General = {
          FastConnectable = true;
          Experimental = true;
        };
      };

      services.blueman.enable = true;
    };
}
