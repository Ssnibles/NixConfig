{ ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.dualsense-pair = pkgs.stdenvNoCC.mkDerivation {
        pname = "dualsense-pair";
        version = "0.1.0";

        src = ./.;

        dontConfigure = true;
        dontBuild = true;

        installPhase = ''
          runHook preInstall

          substituteInPlace dualsense-pair.sh \
            --replace-fail '#!/usr/bin/env bash' '#!${pkgs.bash}/bin/bash'
          install -Dm755 dualsense-pair.sh "$out/bin/dualsense-pair"

          runHook postInstall
        '';

        meta = {
          description = "Pair or re-pair a PlayStation 5 DualSense controller over Bluetooth";
          license = lib.licenses.mit;
          mainProgram = "dualsense-pair";
        };
      };
    };
}
