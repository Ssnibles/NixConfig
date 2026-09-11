# =============================================================================
# Command-Line Tools, Git & Jujutsu (jj) Integration
# =============================================================================
# Common CLI tools (bat, btop, fzf, ripgrep), nix-index-database, and Git/jj
# user profiles.
# =============================================================================
{ inputs, ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      config,
      ...
    }:
    {
      # Nix-index database provides command-not-found package suggestions & `nix-locate`
      imports = [
        inputs.nix-index-database.nixosModules.default
      ];

      config = {
        environment.systemPackages = with pkgs; [
          bat
          btop
          chafa # Terminal image viewer with Sixel support
          microfetch
          fd
          file
          fzf
          git
          gh
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
          mermaid-cli
        ];

        programs.git.enable = true;

        # ── Git Identity & Conditional Includes ───────────────────────────────
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

          # ── Jujutsu Identity & Config ──────────────────────────────────────
          # jj reads its global config from ~/.config/jj/config.toml.
          # Conditional identity per repo-root is handled via per-repo config
          # (.jj/repo/config.toml) or by running `jj config set --repo` once
          # inside a workspace. The global identity mirrors the git identity.
          ".config/jj/config.toml" = {
            clobber = true;
            text = ''
              [user]
              name = "Ssnibles"
              email = "joshua.breite@gmail.com"

              [ui]
              default-command = "log"
              pager = { command = ["less", "-FRX"], env = {} }
              diff-editor = ":builtin"
            '';
          };

          # ── jjui Theme Overrides ────────────────────────────────────────────
          # jjui defaults use "bright black" for both dimmed text AND selection
          # highlight backgrounds — a conflict on dark terminals. We override
          # each use-case independently with explicit theme hex values.
          ".config/jjui/config.toml" = {
            clobber = true;
            text =
              let
                c = config.theme.colors;
              in
              ''
                [colors]
                # Dimmed / secondary text — use fgDim: readable muted grey
                "revset completion dimmed"         = { fg = "#${c.fgDim}" }
                "revset completion selected dimmed" = { fg = "#${c.fgDim}" }
                "revisions details selected dimmed" = { fg = "#${c.fgDim}" }
                "picker dimmed"                    = { fg = "#${c.fgDim}" }
                "confirmation dimmed"              = { fg = "#${c.fgDim}" }

                # Selection highlight backgrounds — use bgSubtle: dark & subtle
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
