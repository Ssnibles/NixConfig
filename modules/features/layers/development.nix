{ self, ... }:
{
  flake.nixosModules.development =
    {
      pkgs,
      lib,
      config,
      ...
    }:
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
            dbeaver-bin
            yazi
            lazygit
            sshfs
            fuse
            sshpass
            zellij
            self.packages.${pkgs.stdenv.hostPlatform.system}.plsfail
          ]
          ++ (with pkgs.unstable; [
            android-studio
          ]);
      };

    };
}
