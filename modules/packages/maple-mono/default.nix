# Maple Mono font with Nerd Font icons and the selected stylistic features.
{ ... }:
let
  mkMapleMono =
    pkgs:
    pkgs.stdenvNoCC.mkDerivation {
      pname = "maple-mono-custom";
      version = "7.9.0";

      src = ./fonts;

      installPhase = ''
        runHook preInstall

        mkdir -p $out/share/fonts/truetype
        cp *.ttf $out/share/fonts/truetype/

        runHook postInstall
      '';

      meta = with pkgs.lib; {
        description = "Custom built Maple Mono font with narrow width and frozen OpenType features";
        homepage = "https://github.com/subframe7536/Maple-font";
        license = licenses.ofl;
        platforms = platforms.all;
      };
    };
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.maple-mono-custom = mkMapleMono pkgs;
    };

  nixos.modules.shared =
    { pkgs, ... }:
    {
      fonts.packages = [ (mkMapleMono pkgs) ];
    };
}
