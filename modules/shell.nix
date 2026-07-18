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
          self'.packages.boilerplate
        ];
        nativeBuildInputs = [ pkgs.pkg-config ];
        env.RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
      };
    };
}
