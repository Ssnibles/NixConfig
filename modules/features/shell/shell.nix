# =============================================================================
# Interactive Shell Environment (Fish, Zsh, Starship, Direnv)
# =============================================================================
# Unstable Fish shell, Oh-My-Zsh setup, Starship prompt configuration,
# FZF integration script with directory caching, shell aliases, and keybindings.
# =============================================================================
{ inputs, ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      c = config.theme.colors;
    in
    {
      config = {
        users.users."${config.username}".shell = pkgs.unstable.fish;

        environment.systemPackages = with pkgs; [
          any-nix-shell
          fishPlugins.fzf-fish # FZF fuzzy search integration
          fishPlugins.autopair # Auto-close pairs (quotes, brackets)
          fishPlugins.bass # Source Bash scripts in Fish
        ];

        programs.zoxide = {
          enable = true;
          enableZshIntegration = true;
          enableFishIntegration = true;
        };

        # ── Hjem Dotfiles for Shell Configuration ────────────────────────────
        hjem.users.${config.username}.files = {
          ".zshrc" = {
            text = ''
              ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#${c.bgSubtle}"
            '';
          };

          ".config/fish/config.fish" = {
            clobber = true;
            text = ''
              set -g fish_color_autosuggestion '#${c.bgSubtle}'
              set -g fish_color_comment '#${c.bgSubtle}'

              set -gx FZF_DEFAULT_OPTS "
                --height=60%
                --layout=reverse
                --border=rounded
                --border-label=\"\"
                --info=inline
                --prompt=\"❯ \"
                --pointer=\"▶\"
                --marker=\"✓\"
                --padding=1,2
                --margin=0,1
                --scrollbar=\"│\"
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
                --color=marker:#${c.green},spinner:#${c.purple},header:#${c.fgMid}
                --color=border:#${c.fgMid}
                --color=selected-bg:#${c.bgSubtle},selected-fg:#${c.fg}
                --color=gutter:#${c.bg}
                --preview '
                  if test -f {}
                    if file --mime-type {} | grep -q image/
                      chafa --format=sixel --size=\"\$FZF_PREVIEW_COLUMNS\"x\"\$FZF_PREVIEW_LINES\" {}
                    else
                      bat --style=numbers --color=always --line-range :500 {}
                    end
                  else if test -d {}
                    ls -la {} 2>/dev/null
                  end
                '
              "

              set -gx FZF_DEFAULT_COMMAND 'fish -c "__fzf_cache_fd file"'
              set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
              set -gx FZF_ALT_C_COMMAND 'fish -c "__fzf_cache_fd dir"'

              # Bind Ctrl+Backspace (\x1f / \c_ / CSI u) to delete word
              bind \c_ backward-kill-word
              bind \x1f backward-kill-word
              bind \e\[127\;5u backward-kill-word
              bind \e\[8\;5u backward-kill-word
            '';
          };

          # Fish helper functions
          ".config/fish/functions/__fzf_cache_fd.fish" = {
            text = ''
              function __fzf_cache_fd --description "Cache fd results per directory to avoid frequent disk scanning"
                  set -l mode $argv[1]
                  if test -z "$mode"
                      set mode file
                  end

                  set -l cache_dir "/tmp/fzf_fd_cache_$USER"
                  command mkdir -p $cache_dir

                  set -l pwd_hash (pwd | sha256sum | string sub -l 16)
                  set -l cache_file "$cache_dir/$pwd_hash"
                  if test "$mode" = "dir"
                      set cache_file "$cache_file.dir"
                  end

                  # Refresh index if older than 300 seconds (5 minutes) or missing
                  set -l max_age 300
                  set -l needs_refresh 1

                  if test -f "$cache_file"
                      set -l file_age (math (date +%s) - (stat -c %Y "$cache_file"))
                      if test $file_age -lt $max_age
                          set needs_refresh 0
                      end
                  end

                  if test $needs_refresh -eq 1
                      if test "$mode" = "dir"
                          fd --type d --strip-cwd-prefix --hidden --exclude .git > "$cache_file" 2>/dev/null
                      else
                          fd --type f --strip-cwd-prefix --hidden --exclude .git > "$cache_file" 2>/dev/null
                      end
                  end

                  cat "$cache_file"
              end
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

          ".config/fish/functions/nixup.fish" = {
            text = ''
              function nixup --description "Update NixOS configuration and rebuild"
                  set -l repo "$HOME/NixConfig"
                  if test -d "$repo"
                      cd "$repo"
                      git pull
                      nh os switch
                  else
                      echo "NixConfig not found at $repo" >&2
                      return 1
                  end
              end
            '';
          };
        };

        # ── Zsh Configuration ────────────────────────────────────────────────
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

        # ── Fish Program Configuration ───────────────────────────────────────
        programs.fish = {
          enable = true;
          package = pkgs.unstable.fish;
          generateCompletions = false;

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
            t = "tmux";
            build-nixconf = "$HOME/NixConfig/build.sh";
          };

          shellAbbrs = {
            lg = "lazygit";
            y = "yazi";
            nixclean = "sudo nix-collect-garbage --delete-older-than 30d";
          };

          interactiveShellInit = ''
            set -g fish_greeting
            set -gx EDITOR nvim
            set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
            stty -ixon 2>/dev/null

            # Bind Ctrl+L to clear terminal scrollback and repaint prompt cleanly
            bind \cl 'clear; commandline -f repaint'

            # Bind Ctrl+Backspace (\c_, \x1f, CSI u) to delete previous word
            bind \c_ backward-kill-word
            bind \x1f backward-kill-word
            bind \e\[127\;5u backward-kill-word
            bind \e\[8\;5u backward-kill-word

            any-nix-shell fish | source
          '';
        };

        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
        };

        # ── Starship Prompt Configuration ────────────────────────────────────
        programs.starship = {
          enable = true;
          package = pkgs.unstable.starship;
          settings = {
            add_newline = false;

            format = "$username$directory$git_branch$git_status\n$character";
            right_format = "$nix_shell$nodejs$rust$python$battery$cmd_duration";

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
