{
  self,
  inputs,
  config,
  ...
}:
{
  flake.nixosModules.development =
    { pkgs, lib, ... }:
    {
      config = {
        environment.systemPackages = with pkgs; [
          vim
          git
          zed-editor
          opencode
          opencode-desktop
          direnv
          nix-direnv
          htop
          dbeaver-bin
          zellij
          self.packages.${pkgs.stdenv.hostPlatform.system}.ralph
          self.packages.${pkgs.stdenv.hostPlatform.system}.t3code
          self.packages.${pkgs.stdenv.hostPlatform.system}.plsfail
        ];
        programs.zoxide = {
          enable = true;
          enableZshIntegration = true;
        };
        # enable Docker
        virtualisation.docker = {
          enable = true;
          rootless = {
            enable = true;
            setSocketVariable = true;
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

          # Extra config (this is appended at the end of .zshrc)
          promptInit = ''
            # Aliases
            alias ll="ls -alF"

            # Load nix-direnv if available
            if command -v direnv >/dev/null; then
              eval "$(direnv hook zsh)"
            fi

            # Better Ctrl-R incremental search
            bindkey '^R' history-incremental-search-backward

            # Improve cd: automatically pushd to track dirs
            setopt auto_pushd
            setopt pushd_ignore_dups

            # Enable command correction
            setopt correct
          '';
        };

        # Configure starship prompt
        programs.starship = {
          enable = true;
          # enableZshIntegration = true;
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
