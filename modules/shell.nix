{ ... }:
{
  perSystem =
    { pkgs, self', ... }:
    {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          bacon
          cargo
          rust-analyzer
          rustc
          rustfmt
          clippy
          glibc
          sea-orm-cli
          nixfmt
          nil
          alejandra
          fish
          self'.packages.boilerplate
        ];
        nativeBuildInputs = [ pkgs.pkg-config ];
        env.RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
        shellHook = ''
          if [ -z "$FISH_INIT" ] && [ -x "$(command -v fish)" ]; then
            export FISH_INIT=1
            exec fish
          fi
        '';
      };
    };
}
