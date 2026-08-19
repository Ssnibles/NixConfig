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
            neovim
            opencode
            antigravity
            nodejs
            playwright
            cargo
            zig
            pkg-config
            wayland
            wlroots
            wayland-protocols
            libxkbcommon
            pixman
            libinput
            gcc
            go
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
