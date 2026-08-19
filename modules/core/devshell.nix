# =============================================================================
# Core Developer Shell
# =============================================================================
# Development environment for working on NixConfig and related projects.
# =============================================================================
{ inputs, ... }:
{
  perSystem =
    { pkgs, self', ... }:
    let
      unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      devShells.default = pkgs.mkShell {
        buildInputs =
          with pkgs;
          [
            # Rust toolchain
            bacon
            cargo
            rust-analyzer
            rustc
            rustfmt
            clippy
            glibc
            sea-orm-cli

            # Nix language tools
            nixfmt
            nil
            alejandra

            # Shell & utilities
            unstablePkgs.fish
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
