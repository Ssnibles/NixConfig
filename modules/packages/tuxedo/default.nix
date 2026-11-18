{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.tuxedo = inputs.tuxedo.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };

  flake.nixosModules.shared =
    { pkgs, ... }:
    let
      tuxedo = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.tuxedo;
    in
    {
      environment.systemPackages = [ tuxedo ];
    };
}
