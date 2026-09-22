{ ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.ytplay = pkgs.buildGoModule {
        pname = "ytplay";
        version = "0.1.0";

        src = ./.;
        vendorHash = "sha256-RwBa81aIUBWDRpOHkExH57IWo+QgKFGO9xdOb0K7zwU=";

        nativeBuildInputs = [ pkgs.makeWrapper ];

        postInstall = ''
          wrapProgram $out/bin/ytplay \
            --prefix PATH : ${lib.makeBinPath [ pkgs.yt-dlp ]}
        '';

        meta = {
          description = "TUI YouTube search & play (Bubble Tea)";
          homepage = "https://github.com/Ssnibles/NixConfig";
          license = lib.licenses.mit;
          mainProgram = "ytplay";
        };
      };
    };
}