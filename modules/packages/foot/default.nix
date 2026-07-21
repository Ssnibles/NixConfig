{ self, inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.foot = pkgs.symlinkJoin {
        name = "foot";
        buildInputs = [ pkgs.makeWrapper ];
        paths = [ pkgs.foot ];
        postBuild = ''
          wrapProgram $out/bin/foot \
            --append-flags "-c ${./foot.ini}"
        '';
      };
    };
}
