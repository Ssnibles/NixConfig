{ self, inputs, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.boilerplate = pkgs.stdenvNoCC.mkDerivation {
        pname = "boilerplate";
        version = "0.1.0";

        src = ./.;

        dontConfigure = true;
        dontBuild = true;

        installPhase = ''
          runHook preInstall

          substituteInPlace boilerplate.py \
            --replace-fail '#!/usr/bin/env python3' '#!${pkgs.python3}/bin/python3'
          install -Dm755 boilerplate.py "$out/bin/boilerplate"

          runHook postInstall
        '';

        meta = {
          description = "Generate boilerplate Nix modules";
          license = lib.licenses.mit;
          mainProgram = "boilerplate";
        };
      };
    };
}
