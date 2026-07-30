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
            cargo
            gcc
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
          enableFishIntegration = true;
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

        programs.fish = {
          enable = true;
          shellAliases = {
            ll = "ls -l";
            la = "ls -la";
            lt = "ls -ltr";
            g = "git";
            ga = "git add";
            gc = "git commit";
            gp = "git push";
            gl = "git log --oneline --graph";
            n = "nvim";
            cat = "bat";
          };

          shellAbbrs = {
            lg = "lazygit";
            y = "yazi";
            nixup = "sudo nixos-rebuild switch --flake .";
            nixclean = "sudo nix-collect-garbage --delete-older-than 30d";
          };

          interactiveShellInit = ''
            set -gx EDITOR nvim
            # Better man page colors
            set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
          '';
        };

        # Configure starship prompt
        programs.starship = {
          enable = true;
          package = pkgs.unstable.starship;
          settings = {
            add_newline = false;

            format = "$username$directory$git_branch$git_status$fill$nix_shell$nodejs$rust$python$battery$cmd_duration\n$character";

            character = {
              success_symbol = "[╰──>>](bold green)";
              error_symbol = "[╰──>>](bold red)";
            };

            directory.truncation_length = 3;

            username = {
              show_always = true;
              format = "[$user](bold blue) ";
            };

            git_branch.format = "[$symbol$branch]($style) ";
            git_branch.style = "bold purple";

            git_status = {
              format = "[($all_status$ahead_behind)]($style) ";
              style = "bold yellow";
              conflicted = "×";
              up_to_date = "";
              untracked = "…";
              ahead = "⇡\${count}";
              behind = "⇣\${count}";
              stashed = "\$";
              modified = "!";
              staged = "+";
              renamed = "~";
              deleted = "-";
            };

            cmd_duration = {
              min_time = 2000;
              format = "[ $duration]($style) ";
              style = "bold yellow";
            };

            nodejs = {
              format = "[ v$version]($style) ";
              style = "bold green";
              detect_files = [
                "package.json"
                "node_modules"
              ];
              detect_folders = [ "node_modules" ];
            };

            rust = {
              format = "[ v$version]($style) ";
              style = "bold red";
              detect_files = [ "Cargo.toml" ];
              detect_folders = [ "target" ];
            };

            python = {
              format = "[ v$version]($style) ";
              style = "bold yellow";
              detect_files = [
                "pyproject.toml"
                "requirements.txt"
                ".python-version"
                "setup.py"
                "Pipfile"
              ];
            };

            nix_shell = {
              format = "❄ [$state($name)]($style) ";
              style = "bold blue";
            };

            battery = {
              full_symbol = "●";
              charging_symbol = "↑";
              discharging_symbol = "↓";
              display = [
                {
                  threshold = 20;
                  style = "bold red";
                }
              ];
            };
          };

          transientPrompt = {
            enable = true;
            left = "echo -n '>> '";
            right = "";
          };
        };
      };

    };
}
