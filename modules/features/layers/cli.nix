{ self, inputs, ... }:
{
  flake.nixosModules.cli =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      config = {
        environment.systemPackages = with pkgs; [
          bat
          btop
          fastfetch
          fd
          fzf
          git
          gnupg
          libsecret
          ripgrep
          usbutils
          vim
          wget
          zip
          unzip
        ];

        programs.zoxide = {
          enable = true;
          enableZshIntegration = true;
          enableFishIntegration = true;
        };
        programs.git = {
          enable = true;
          config = [
            {
              includeIf."gitdir:~/AndroidStudioProjects/".path = "~/.config/git/config-uni";
            }
            {
              user = {
                name = "Ssnibles";
                email = "joshua.breite@gmail.com";
              };
            }
          ];
        };
        # make ZSH shut up about zshrc
        hjem.users.${config.username}.files =
          let
            c = config.theme.colors;
          in
          {
            ".zshrc" = {
              text = "";
            };
            ".config/git/config-uni" = {
              text = ''
                [user]
                  name = jb878
                  email = jb878@students.waikato.ac.nz
              '';
            };
            ".config/fish/config.fish" = {
              clobber = true;
              text = ''
                set -gx FZF_DEFAULT_OPTS "
                  --height=60%
                  --layout=reverse
                  --border=rounded
                  --border-label=""
                  --info=inline
                  --prompt=\"❯ \"
                  --pointer=\"▶\"
                  --marker=\"✓\"
                  --header=\"╱\"
                  --padding=1,2
                  --margin=0,1
                  --scrollbar=\"│\"
                  --preview-window=right,50%,border-left
                  --bind=ctrl-/:toggle-preview
                  --bind=ctrl-j:down,ctrl-k:up
                  --bind=ctrl-f:page-down,ctrl-b:page-up
                  --bind=ctrl-a:select-all,ctrl-d:deselect-all
                  --bind=ctrl-y:accept
                  --cycle
                  --no-mouse
                  --color=fg:#${c.fg},bg:#${c.bg},hl:#${c.accent}
                  --color=fg+:#${c.fg},bg+:#${c.bgSubtle},hl+:#${c.accent}
                  --color=info:#${c.purple},prompt:#${c.accent},pointer:#${c.accent}
                  --color=marker:#${c.green},spinner:#${c.purple},header:#${c.fgDim}
                  --color=border:#${c.fgDim}
                  --color=selected-bg:#${c.bgSubtle},selected-fg:#${c.fg}
                  --color=gutter:#${c.bg}
                "
              '';
            };
          };
        programs.zsh = {
          enable = true;

          enableCompletion = true;
          enableAutosuggestions = true;
          syntaxHighlighting.enable = true;

          oh-my-zsh = {
            enable = true;
            plugins = [
              "git"
              "direnv"
              "z"
            ];
            theme = "robbyrussell";
          };

          histSize = 10000;
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
            build-nixconf = "$HOME/NixConfig/build.sh";
          };

          shellAbbrs = {
            lg = "lazygit";
            y = "yazi";
            nixup = "sudo nixos-rebuild switch --flake .";
            nixclean = "sudo nix-collect-garbage --delete-older-than 30d";
          };

          interactiveShellInit = ''
            set -g fish_greeting
            set -gx EDITOR nvim
            set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
            fzf --fish | source
          '';
        };

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
