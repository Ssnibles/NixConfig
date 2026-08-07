{ ... }:
let
  mkInstrumentSerif =
    pkgs:
    let
      variants = {
        regular = pkgs.fetchurl {
          url = "https://fonts.gstatic.com/s/instrumentserif/v5/jizBRFtNs2ka5fXjeivQ4LroWlx-2zI.ttf";
          hash = "sha256-qZ49tQB2ICcTgS7VQf7rI//uu2HbH6axz0j+WQ037xg=";
        };
        italic = pkgs.fetchurl {
          url = "https://fonts.gstatic.com/s/instrumentserif/v5/jizHRFtNs2ka5fXjeivQ4LroWlx-6zATiw.ttf";
          hash = "sha256-/s9IYdUgJAW4vUXGg4WLaHBkKgJnhP4Nv4j/Vd7e6KA=";
        };
      };
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "instrument-serif";
      version = "5.0.0";

      dontUnpack = true;

      installPhase = ''
        runHook preInstall

        mkdir -p $out/share/fonts/truetype
        cp ${variants.regular} $out/share/fonts/truetype/InstrumentSerif-Regular.ttf
        cp ${variants.italic} $out/share/fonts/truetype/InstrumentSerif-Italic.ttf

        runHook postInstall
      '';

      meta = with pkgs.lib; {
        description = "Instrument Serif font family";
        homepage = "https://fonts.google.com/specimen/Instrument+Serif";
        license = licenses.ofl;
        platforms = platforms.all;
      };
    };
in
{
  perSystem = { pkgs, ... }: {
    packages.instrument-serif = mkInstrumentSerif pkgs;
  };

  nixos.modules.shared = { pkgs, ... }: {
    fonts.packages = [ (mkInstrumentSerif pkgs) ];
  };
}
