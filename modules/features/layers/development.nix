{ self, inputs, ... }:
{
  flake.nixosModules.development =
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
            nodejs
            cargo
            gcc
            direnv
            nix-direnv
            yazi
            lazygit
            rclone
            fuse
            sshpass
            zellij
            self.packages.${pkgs.stdenv.hostPlatform.system}.plsfail
          ]
          ++ pomodoroPkg
          ++ (with pkgs.unstable; [
            android-studio
          ]);
      };
    };
}
