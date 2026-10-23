# Developer shell for this repository.
{ ... }:
{
  perSystem =
    { pkgs, self', ... }:
    {
      devenv.shells.default = {
        name = "NixConfig Developer Shell";
        # devenv.root defaults to the PWD environment variable, which is empty
        # during pure flake evaluation. Without a real path, nix develop fails
        # its root check and cannot write the task cache. Fall back to the
        # checkout path; the normal devenv command still uses PWD.
        devenv.root = if builtins.getEnv "PWD" != "" then builtins.getEnv "PWD" else "/home/josh/NixConfig";

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
