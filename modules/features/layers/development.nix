{
  self,
  inputs,
  config,
  ...
}:
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
            vim
            git
            opencode
            nodejs
            direnv
            nix-direnv
            ripgrep
            btop
            dbeaver-bin
            yazi
            lazygit
            fzf
            sshfs
            fuse
            sshpass
            self.packages.${pkgs.stdenv.hostPlatform.system}.plsfail
          ]
          ++ (with pkgs.unstable; [
            android-studio
          ]);
        programs.zoxide = {
          enable = true;
          enableZshIntegration = true;
        };
        programs.git = {
          enable = true;
          config = {
            user = {
              name = "Ssnibles";
              email = "joshua.breite@gmail.com";
            };
          };
        };
        # make ZSH shut up about zshrc
        hjem.users.${config.username}.files.".zshrc".text = "";
        programs.zsh = {
          enable = true;

          # Nice features
          enableCompletion = true;
          enableAutosuggestions = true;
          syntaxHighlighting.enable = true;

          # Optional prompt theme — Powerlevel10k is very popular
          oh-my-zsh = {
            enable = true;
            plugins = [
              "git"
              "direnv"
              "z"
            ];
            theme = "robbyrussell"; # or try "agnoster"
          };

          # HISTORY
          histSize = 10000;

          # # Extra config (this is appended at the end of .zshrc)
          # promptInit = ''
          #   # Aliases
          #   alias ll="ls -alF"
          #
          #   # Load nix-direnv if available
          #   if command -v direnv >/dev/null; then
          #     eval "$(direnv hook zsh)"
          #   fi
          #
          #   # Better Ctrl-R incremental search
          #   bindkey '^R' history-incremental-search-backward
          #
          #   # Improve cd: automatically pushd to track dirs
          #   setopt auto_pushd
          #   setopt pushd_ignore_dups
          #
          #   # Enable command correction
          #   setopt correct
          # '';
        };

        # Configure starship prompt
        programs.starship = {
          enable = true;
          settings = {
            add_newline = false;
            character = {
              success_symbol = "[➜](bold green)";
              error_symbol = "[✗](bold red)";
            };
            directory.truncate_to_repo = false;
            nix_shell = {
              disabled = false;
              symbol = "❄️ ";
              format = "[$symbol$name]($style) ";
            };
            git_branch.symbol = "🌿 ";
          };
        };
      };

    };
}
