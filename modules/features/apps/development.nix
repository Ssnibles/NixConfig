# =============================================================================
# Global Development Toolchain & Utilities
# =============================================================================
# Global developer tools, language runtimes, build utilities, and IDEs.
# Note: NVF Neovim distribution packages are defined separately in apps/neovim.nix.
# =============================================================================
{ self, inputs, ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      pomodoroPkg = lib.optional (
        inputs ? pomodoro
      ) inputs.pomodoro.packages.${pkgs.stdenv.hostPlatform.system}.default;
      unstablePkgs = import inputs.nixpkgs-unstable {
        inherit (pkgs.stdenv.hostPlatform) system;
        config = {
          allowUnfree = true;
          allowUnfreePredicate = _: true;
        };
      };
    in
    {
      config = {
        environment.systemPackages =
          with pkgs;
          [
            # Editors & AI tools
            unstablePkgs.antigravity-cli

            # Runtimes & Compilers
            nodejs
            playwright
            cargo
            zig
            gcc
            go

            # Wayland build headers
            pkg-config
            wayland
            wlroots
            wayland-protocols
            libxkbcommon
            pixman
            libinput

            # Embedded & Microcontroller Dev
            arduino-cli
            esptool

            # CLI Dev Utilities
            devenv
            yazi
            lazygit
            rclone
            fuse
            sshpass
            harlequin
            sqlite
            self.packages.${pkgs.stdenv.hostPlatform.system}.plsfail
          ]
          ++ pomodoroPkg
          ++ (with pkgs.unstable; [
            android-studio
          ]);
      };
    };
}
