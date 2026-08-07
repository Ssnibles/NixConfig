{ ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.html-server = pkgs.buildGoModule {
        pname = "html-server";
        version = "0.1.0";

        src = ./.;

        # Use null only if zero external dependencies are imported.
        # Otherwise, set to lib.fakeHash first to calculate the real hash.
        vendorHash = null;

        meta = {
          description = "A small html-server with live reload";
          license = lib.licenses.mit;
          mainProgram = "html-server";
        };
      };
    };
}
