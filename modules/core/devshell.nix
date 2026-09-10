# =============================================================================
# Core Developer Shell
# =============================================================================
# Development environment for working on NixConfig and related projects.
# =============================================================================
{ ... }:
{
  perSystem =
    { pkgs, self', ... }:
    {
      devenv.shells.default = {
        name = "NixConfig Developer Shell";

        packages = with pkgs; [
          # Rust extras (toolchain managed by languages.rust)
          bacon
          sea-orm-cli

          # Nix language tools
          nixfmt
          nil

          # Shell & utilities
          pkg-config
          fish
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
