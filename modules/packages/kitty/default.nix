{ self, inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.kitty = pkgs.symlinkJoin {
        name = "kitty";
        buildInputs = [ pkgs.makeWrapper ];
        paths = [ pkgs.kitty ];
        postBuild = ''
          wrapProgram $out/bin/kitty \
            --append-flags "-c ${./kitty.conf}"
        '';
      };
    };
}
