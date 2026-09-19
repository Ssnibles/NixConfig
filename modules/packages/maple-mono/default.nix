# =============================================================================
# Custom Maple Mono Font Package
# =============================================================================
# Custom built Maple Mono fonts configured with narrow width and frozen
# stylistic features (cv01, cv02, cv31-37, ss03, ss08-11), including Nerd Font icons.
# =============================================================================
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
