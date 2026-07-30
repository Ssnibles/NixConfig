{ ... }:
{
  flake.nixosModules.communications =
    { pkgs, lib, ... }:
    {
      config = {
        environment.systemPackages = with pkgs.unstable; [
          vesktop
          mumble
        ];
      };

    };
}
