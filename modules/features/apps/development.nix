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
    in
    {
      config = {
        environment.systemPackages =
          with pkgs;
          [
            # Editors & AI tools
            opencode
            antigravity

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

            # CLI Dev Utilities
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
