{ self, inputs, ... }:
{
  flake.nixosModules.communications =
    { pkgs, lib, ... }:
    {
      config = {
        environment.systemPackages = with pkgs; [
          signal-desktop
        ];
      };

    };
}
