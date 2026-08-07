{ ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.html-server = pkgs.buildGoModule {
        pname = "html-server";
        version = "0.1.0";

        src = ./.;
        vendorHash = null;

        postUnpack = ''
          if [ ! -f "$sourceRoot/go.mod" ]; then
            echo "module html-server" > "$sourceRoot/go.mod"
          fi
        '';

        meta = {
          description = "A small html-server with live reload";
          license = lib.licenses.mit;
          mainProgram = "html-server";
        };
      };
    };
}
