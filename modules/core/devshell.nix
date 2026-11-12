# Developer shell for this repository.
{ ... }:
{
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
          || (type == "regular" && lib.hasSuffix ".nix" (toString path) && !(lib.hasPrefix "_" name));
      };
    in
    {
      formatter = pkgs.nixfmt;

      checks.nixfmt = pkgs.runCommand "nixfmt-check" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
        find ${nixSources} -name '*.nix' -print0 | xargs -0 nixfmt --check
        touch $out
      '';

      checks.deadnix = pkgs.runCommand "deadnix-check" { nativeBuildInputs = [ pkgs.deadnix ]; } ''
        deadnix --fail ${nixSources}/modules ${nixSources}/flake.nix ${nixSources}/templates
        touch $out
      '';

      devenv.shells.default = {
        name = "NixConfig Developer Shell";
        # devenv.root defaults to the PWD environment variable, which is empty
        # during pure flake evaluation. Without a real path, nix develop fails
        # its root check and cannot write the task cache. Fall back to the
        # checkout path; the normal devenv command still uses PWD.
        devenv.root =
          if builtins.getEnv "PWD" != "" then
            builtins.getEnv "PWD"
          else
            "${builtins.getEnv "HOME"}/NixConfig";

        packages = with pkgs; [
          # Rust extras (toolchain managed by languages.rust)
          bacon
          sea-orm-cli

          # Nix language tools
          nixfmt
          nil

          # Shell tools.
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
