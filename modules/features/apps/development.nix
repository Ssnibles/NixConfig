# Development tools.
# Neovim is configured in apps/neovim.nix.
{
  self,
  ...
}:
{
  flake.nixosModules.shared =
    {
      pkgs,
      ...
    }:
    {
      config = {
        environment.systemPackages = with pkgs; [
          dbeaver-bin

          nodejs
          zig
          gcc
          go

          # Rust. The nixpkgs cargo wrapper carries its own rustc, but
          # rustfmt and clippy are only reachable as cargo subcommands when
          # they are on PATH. sccache stays inert until RUSTC_WRAPPER=sccache.
          cargo
          rustc
          rustfmt
          clippy
          rust-analyzer
          bacon
          cargo-nextest
          cargo-edit
          cargo-expand
          cargo-outdated
          cargo-audit
          cargo-deny
          sccache
          sea-orm-cli
          rustfinity

          # Wayland build headers.
          pkg-config
          wayland
          wlroots
          wayland-protocols
          libxkbcommon
          pixman
          libinput

          # Embedded development.
          arduino-cli
          esptool

          # Command line tools.
          devenv
          jujutsu
          jjui
          rclone
          fuse
          sshpass
          sqlite
          self.packages.${pkgs.stdenv.hostPlatform.system}.plsfail
          antigravity-cli
        ];
      };
    };
}
