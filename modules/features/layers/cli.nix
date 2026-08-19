{ inputs, ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      # Weekly-updated nix-index database + nix-index wrapper. Makes shells
      # suggest the nix package that provides a missing command, and installs `nix-locate`.
      imports = [
        inputs.nix-index-database.nixosModules.default
      ];

      config = {
        environment.systemPackages = with pkgs; [
          bat
          btop
          chafa # Terminal image viewer (Sixel enabled)
          microfetch
          fd
          file
          fzf
          git
          gnupg
          libnotify
          libsecret
          ripgrep
          usbutils
          vim
          wget
          zip
          unzip
          croc
        ];

        programs.git.enable = true;

        hjem.users.${config.username}.files = {
          ".config/git/config-uni" = {
            text = ''
              [user]
                name = jb878
                email = jb878@students.waikato.ac.nz
            '';
          };
          ".gitconfig" = {
            clobber = true;
            text = ''
              [user]
                name = Ssnibles
                email = joshua.breite@gmail.com

              [includeIf "gitdir/i:~/StudioProjects/"]
                path = ~/.config/git/config-uni
            '';
          };
        };

        programs.nix-index.package =
          inputs.nix-index-database.packages.${pkgs.stdenv.hostPlatform.system}.nix-index-with-small-db;
      };
    };
}
