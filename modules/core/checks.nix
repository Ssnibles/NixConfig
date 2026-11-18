# Formatting, dead code, and lint checks.
_: {
  perSystem =
    {
      lib,
      pkgs,
      self',
      ...
    }:
    let
      # The Nix sources that the checks below scan. Generated files such as
      # _hardware-generated.nix are excluded.
      nixSources = lib.cleanSourceWith {
        src = ../..;
        filter =
          path: type:
          let
            name = baseNameOf (toString path);
          in
          (
            type == "directory"
            && !(builtins.elem name [
              ".git"
              ".jj"
              ".devenv"
            ])
          )
          || (
            type == "regular"
            && (lib.hasSuffix ".nix" (toString path) || name == "statix.toml")
            && !(lib.hasPrefix "_" name)
          );
      };
    in
    {
      formatter = pkgs.nixfmt;

      checks = {
        nixfmt = pkgs.runCommand "nixfmt-check" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
          find ${nixSources} -name '*.nix' -print0 | xargs -0 nixfmt --check
          touch $out
        '';

        deadnix = pkgs.runCommand "deadnix-check" { nativeBuildInputs = [ pkgs.deadnix ]; } ''
          deadnix --fail ${nixSources}/modules ${nixSources}/flake.nix ${nixSources}/templates
          touch $out
        '';

        statix = pkgs.runCommand "statix-check" { nativeBuildInputs = [ pkgs.statix ]; } ''
          cd ${nixSources}
          statix check modules
          touch $out
        '';

        dev-init =
          pkgs.runCommand "dev-init-check"
            {
              nativeBuildInputs = [
                self'.packages.dev-init
                pkgs.devenv
                pkgs.nix
              ];
            }
            ''
              set -euo pipefail
              export HOME=$(mktemp -d)
              export XDG_CACHE_HOME=$HOME/.cache
              export XDG_CONFIG_HOME=$HOME/.config
              export XDG_DATA_HOME=$HOME/.local/share
              work=$(mktemp -d)
              for language in python rust go web c; do
                dev-init "$work/$language" -l "$language" >/dev/null
                nix-instantiate --parse "$work/$language/devenv.nix" >/dev/null
              done
              touch $out
            '';
      };
    };
}
