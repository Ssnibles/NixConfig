{ ... }:
let
  mkSFPro =
    pkgs:
    let
      src = pkgs.fetchFromGitHub {
        owner = "sahibjotsaggu";
        repo = "San-Francisco-Pro-Fonts";
        rev = "8bfea09aa6f1139479f80358b2e1e5c6dc991a58";
        hash = "sha256-mAXExj8n8gFHq19HfGy4UOJYKVGPYgarGd/04kUIqX4=";
      };
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "sf-pro";
      version = "1.0.0";

      inherit src;

      installPhase = ''
        runHook preInstall

        mkdir -p $out/share/fonts/opentype
        cp *.otf $out/share/fonts/opentype/

        runHook postInstall
      '';

      meta = with pkgs.lib; {
        description = "Apple San Francisco Pro font family";
        homepage = "https://developer.apple.com/fonts/";
        license = licenses.unfree;
        platforms = platforms.all;
      };
    };
in
{
  perSystem = { pkgs, ... }: {
    packages.sf-pro = mkSFPro pkgs;
  };

  nixos.modules.shared = { pkgs, ... }: {
    fonts.packages = [ (mkSFPro pkgs) ];
  };
}
