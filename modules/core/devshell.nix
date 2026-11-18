# Developer shell for this repository.
_: {
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    {
      devenv.shells.default = {
        name = "NixConfig Developer Shell";

        # devenv.root defaults to PWD, which is empty during pure flake
        # evaluation. Fall back to the usual checkout path in that case.
        devenv.root =
          if builtins.getEnv "PWD" != "" then
            builtins.getEnv "PWD"
          else
            "${builtins.getEnv "HOME"}/NixConfig";

        packages = with pkgs; [
          deadnix
          fish
          nil
          nixfmt
          pkg-config
          statix
          self'.packages.boilerplate
          self'.packages.dev-init
        ];

        languages.nix.enable = true;
        languages.rust.enable = true;

        enterShell = ''
          if [ -z "$FISH_INIT" ] && [ -x "$(command -v fish)" ]; then
            export FISH_INIT=1
            exec fish
          fi
        '';
      };
    };
}
