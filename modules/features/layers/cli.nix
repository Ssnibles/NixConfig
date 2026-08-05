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
      # Weekly-updated nix-index database + nix-index wrapper. Makes fish
      # (and bash/zsh) suggest the nix package that provides a missing
      # command, and installs `nix-locate`.
      imports = [
        inputs.nix-index-database.nixosModules.default
      ];

      config = {
        environment.systemPackages = with pkgs; [
          bat
          btop
          fastfetch
          fd
          fzf
          git
          gnupg
          libnotify # notify-send, used by the fish "done" plugin
          libsecret
          ripgrep
          usbutils
          vim
          wget
          zip
          unzip
          # fish plugins (auto-sourced via fish vendor dirs)
          fishPlugins.fzf-fish # fzf keybindings + fuzzy search (C-r history, C-Alt-f files, ...)
          fishPlugins.autopair # auto-close quotes / brackets as you type
          fishPlugins.done    # notify when long-running commands finish
          fishPlugins.bass    # "bass" helper to source bash configs from fish
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
            ".config/fish/functions/mkcd.fish" = {
              text = ''
                function mkcd --description "Create a directory and cd into it"
                    if test (count $argv) -ne 1
                        echo "usage: mkcd <dir>" >&2
                        return 1
                    end
                    command mkdir -p $argv[1]
                    cd $argv[1]
                end
              '';
            };
            ".config/fish/functions/nixconf.fish" = {
              text = ''
                function nixconf --description "Jump to NixConfig and show repo status"
                    set -l repo "$HOME/NixConfig"
                    if test -d "$repo"
                        cd "$repo"
                        git status --short --branch
                    else
                        echo "NixConfig not found at $repo" >&2
                        return 1
                    end
                end
              '';
            };
          };
        programs.zsh = {
          enable = true;

          enableCompletion = true;
          autosuggestions.enable = true;
          syntaxHighlighting.enable = true;

          ohMyZsh = {
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

          # Generate completions from man pages for every package in
          # environment.systemPackages (enabled by default, explicit for clarity).
          generateCompletions = true;

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

            # fish plugins:
            #   fzf.fish keybindings: C-r history, C-Alt-f files, C-Alt-l git log,
            #     C-Alt-s git status, C-Alt-p processes, C-v variables
            #   autopair: auto-close quotes/brackets
            #   done: desktop notification when a command takes >= 10s
            #   bass:  `bass <bash-script>` to source bash configs

            # done tweaks
            set -g __done_min_cmd_duration 10000
            set -g __done_notification_urgency_level normal
          '';
        };

        # nix-index-database ships both a full and a bin-only index. The small
        # db is enough for command-not-found suggestions and is a fraction of
        # the size. Replace the module default (full db).
        programs.nix-index.package =
          inputs.nix-index-database.packages.${pkgs.stdenv.hostPlatform.system}.nix-index-with-small-db;

        # direnv + nix-direnv with fish integration (direnv hook fish).
        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
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
