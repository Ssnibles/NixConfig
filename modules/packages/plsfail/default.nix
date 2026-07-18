{ self, inputs, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.plsfail = pkgs.stdenvNoCC.mkDerivation {
        pname = "plsfail";
        version = "0.1.0";

        src = ./.;

        dontConfigure = true;
        dontBuild = true;

        installPhase = ''
          runHook preInstall

          substituteInPlace plsfail.py \
            --replace-fail '#!/usr/bin/env python3' '#!${pkgs.python3}/bin/python3'
          install -Dm755 plsfail.py "$out/bin/plsfail"

          runHook postInstall
        '';

        meta = {
          description = "Run a command until it fails";
          license = lib.licenses.mit;
          mainProgram = "plsfail";
        };
      };
    };
}
