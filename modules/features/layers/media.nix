{ self, inputs, ... }:
{
  flake.nixosModules.media =
    { pkgs, lib, ... }:
    {
      config = {
        environment.systemPackages = with pkgs.unstable; [
          spotify
          zathura
        ];
      };

    };
}
