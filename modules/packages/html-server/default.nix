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

        nativeBuildInputs = [ pkgs.makeWrapper ];

        postInstall = ''
          wrapProgram $out/bin/html-server \
            --prefix PATH : ${lib.makeBinPath [ pkgs.xdg-utils ]}
        '';

        meta = {
          description = "A small html-server with live reload";
          license = lib.licenses.mit;
          mainProgram = "html-server";
        };
      };
    };
}
