# Command line tools, Git, and Jujutsu.
{ inputs, ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      config,
      ...
    }:
    {
      # Provides command-not-found suggestions and nix-locate.
      imports = [
        inputs.nix-index-database.nixosModules.default
      ];

      config = {
        environment.systemPackages = with pkgs; [
          bat
          btop
          chafa # Terminal image viewer with Sixel support.
          microfetch
          fd
          file
          fzf
          git
          gh
          gh-dash
          gnupg
          libnotify
          libsecret
          ripgrep
          usbutils
          wget
          zip
          unzip
          typst
        ];

        programs.git.enable = true;

        programs.gnupg.agent = {
          enable = true;
          enableSSHSupport = true;
        };

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

              [includeIf "gitdir/i:~/AndroidStudioProjects/"]
                path = ~/.config/git/config-uni
            '';
          };

          # Jujutsu reads its global config from ~/.config/jj/config.toml.
          # Per-repository identity is set with jj config set --repo.
          ".config/jj/config.toml" = {
            clobber = true;
            text = ''
              [user]
              name = "Ssnibles"
              email = "joshua.breite@gmail.com"

              [ui]
              editor = "nvim"
              default-command = "log"
              pager = { command = ["less", "-FRX"], env = {} }
              diff-editor = ":builtin"

              [snapshot]
              max-new-file-size = "10MiB"

              [git]
              # Create local bookmarks when remote branches are tracked.
              auto-track-bookmarks = true

              [revsets]
              # Keep jj log fast and focused on trunk, bookmarks, and recent work.
              log = "present(@) | ancestors(immutable_heads().., 2) | present(trunk())"

              [aliases]
              pull = ["git", "fetch"]
              up = ["new", "trunk()"]
              # Shortcuts.
              l = ["log"]
              d = ["diff"]
              s = ["status"]
            '';
          };

          # jjui uses bright black for both dimmed text and selected
          # backgrounds, which is hard to read on a dark terminal. Set both
          # cases explicitly.
          ".config/jjui/config.toml" = {
            clobber = true;
            text =
              let
                c = config.theme.colours;
              in
              ''
                [colors]
                # Dimmed text. fgDim is a readable muted grey.
                "revset completion dimmed"         = { fg = "#${c.fgDim}" }
                "revset completion selected dimmed" = { fg = "#${c.fgDim}" }
                "revisions details selected dimmed" = { fg = "#${c.fgDim}" }
                "picker dimmed"                    = { fg = "#${c.fgDim}" }
                "confirmation dimmed"              = { fg = "#${c.fgDim}" }

                # Selection backgrounds. bgSubtle is dark and subtle.
                "revisions details selected"       = { bg = "#${c.bgSubtle}", bold = true }
                "revset completion selected"       = { bg = "#${c.bgSubtle}", bold = true }
                "picker selected"                  = { bg = "#${c.bgSubtle}", bold = true }
                "menu selected"                    = { bg = "#${c.bgSubtle}", bold = true }
                "confirmation selected"            = { bg = "#${c.bgSubtle}", bold = true }
              '';
          };
        };

        programs.nix-index.package =
          inputs.nix-index-database.packages.${pkgs.stdenv.hostPlatform.system}.nix-index-with-small-db;
      };
    };
}
