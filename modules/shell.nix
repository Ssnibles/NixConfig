{ ... }:
{
  perSystem =
    { pkgs, self', ... }:
    let
      fishInit = pkgs.writeText "fish-init" ''
        if status is-interactive
          # Syntax highlighting theme
          type -q fish_config; and fish_config theme choose "Rosepine" 2>/dev/null; or true
        end
        set -gx EDITOR nvim
        fish_vi_key_bindings 2>/dev/null
      '';
    in
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
            exec fish --init-file ${fishInit}
          fi
        '';
      };
    };
}
