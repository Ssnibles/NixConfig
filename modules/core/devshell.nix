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
      devenv.shells.default = {
        devenv.root = let
          pwd = builtins.getEnv "PWD";
        in if pwd != "" then pwd else "${inputs.self}";
        name = "NixConfig Developer Shell";

        packages = with pkgs; [
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
          pkg-config
          unstablePkgs.fish
          self'.packages.boilerplate
        ];

        languages.rust.enable = true;
        languages.nix.enable = true;

        enterShell = ''
          if [ -z "$FISH_INIT" ] && [ -x "$(command -v fish)" ]; then
            export FISH_INIT=1
            exec fish
          fi
        '';
      };
    };
}
