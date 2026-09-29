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
        # `devenv.root` defaults to `builtins.getEnv "PWD"`, which is empty under
        # pure flake evaluation, so `nix develop` fails the root assertion and
        # then cannot write its task cache to the read-only store path. Fall back
        # to the checkout path (matching the `path:` inputs in flake.nix); the
        # impure devenv CLI still sees the real $PWD.
        devenv.root =
          if builtins.getEnv "PWD" != "" then builtins.getEnv "PWD" else "/home/josh/NixConfig";

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
