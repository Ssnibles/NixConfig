{ inputs, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.tuxedo = pkgs.rustPlatform.buildRustPackage {
        pname = "tuxedo";
        version = "v2026.7.1";

        src = inputs.tuxedo;
        cargoLock.lockFile = "${inputs.tuxedo}/Cargo.lock";
        doCheck = false;

        nativeBuildInputs = [ pkgs.makeWrapper ];

        meta = {
          description = "A todo.txt frontend built in Rust";
          license = lib.licenses.mit;
          mainProgram = "tuxedo";
        };
      };
    };

  nixos.modules.shared =
    { pkgs, ... }:
    let
      tuxedo = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.tuxedo;
    in
    {
      environment.systemPackages = [ tuxedo ];
    };
}
