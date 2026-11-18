_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.dev-init = pkgs.stdenvNoCC.mkDerivation {
        pname = "dev-init";
        version = "0.1.0";

        src = ./.;

        dontConfigure = true;
        dontBuild = true;

        installPhase = ''
          runHook preInstall

          install -Dm755 dev-init.py $out/bin/dev-init
          substituteInPlace $out/bin/dev-init \
            --replace-fail "#!/usr/bin/env python3" "#!${pkgs.python3}/bin/python3"

          install -d $out/share/dev-init
          cp -r _templates $out/share/dev-init/templates

          runHook postInstall
        '';

        meta = {
          description = "Create a devenv project for Python, Rust, Go, web, or C";
          license = lib.licenses.mit;
          mainProgram = "dev-init";
        };
      };
    };
}
