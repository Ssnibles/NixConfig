# Interactive shell setup.
{ ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      config,
      ...
    }:
    let
      c = config.theme.colours;
    in
    {
      users.users."${config.username}".shell = pkgs.fish;

      environment.systemPackages = with pkgs; [
        any-nix-shell
        fishPlugins.fzf-fish
        fishPlugins.autopair
        fishPlugins.bass
      ];

      programs.zoxide = {
        enable = true;
        enableFishIntegration = true;
      };

      hjem.users.${config.username}.files = {

        ".config/fish/config.fish" = {
          clobber = true;
          text = ''
            set -g fish_color_autosuggestion '#${c.fgDim}'
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
              --preview-window=right:50%:wrap
              --preview='
                if test -f {}
                  if file --mime-type {} | grep -q image/
                    chafa --format=sixel --size=\"\$FZF_PREVIEW_COLUMNS\"x\"\$FZF_PREVIEW_LINES\" {}
                  else
                    bat --style=numbers --color=always --line-range :500 --wrap=auto {}
                  end
                else if test -d {}
                  eza --long --all --git --group-directories-first --color=always {}
                else
                  echo {} | bat --language=bash --style=plain --color=always --wrap=auto --terminal-width=\"\$FZF_PREVIEW_COLUMNS\"
                end
              '
              "

            set -gx FZF_DEFAULT_COMMAND 'fish -c "__fzf_cache_fd file"'
            set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
            set -gx FZF_ALT_C_COMMAND 'fish -c "__fzf_cache_fd dir"'
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

                set -l cache_dir
                if test -n "$XDG_RUNTIME_DIR"
                    set cache_dir "$XDG_RUNTIME_DIR/fzf_fd_cache"
                else
                    set cache_dir "/tmp/fzf_fd_cache_$USER"
                end
                command mkdir -p $cache_dir

                set -l pwd_hash (pwd | sha256sum | string sub -l 16)
                set -l cache_file "$cache_dir/$pwd_hash"
                if test "$mode" = "dir"
                    set cache_file "$cache_file.dir"
                end

                set -l max_age 300
                set -l needs_refresh 1

                if test -f "$cache_file"
                    set -l file_age (math (date +%s) - (stat -c %Y "$cache_file"))
                    if test $file_age -lt $max_age
                        set needs_refresh 0
                    end
                end

                if test $needs_refresh -eq 1
                    set -l tmp_file "$cache_file.tmp.$fish_pid"
                    if test "$mode" = "dir"
                        fd --type d --strip-cwd-prefix --hidden --exclude .git > "$tmp_file" 2>/dev/null
                    else
                        fd --type f --strip-cwd-prefix --hidden --exclude .git > "$tmp_file" 2>/dev/null
                    end
                    if test -s "$tmp_file" -o $status -eq 0
                        command mv -f "$tmp_file" "$cache_file"
                    else
                        command rm -f "$tmp_file"
                    end
                end

                command cat "$cache_file"
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
                    jj log --limit 5
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
                    jj git fetch
                    set -l overrides
                    if test -d "$HOME/mango/.git"
                        set -a overrides --override-input mangowc-local "git+file://$HOME/mango"
                    end
                    if test -d "$HOME/ytplay/.git"
                        set -a overrides --override-input ytplay "git+file://$HOME/ytplay"
                    end
                    if test (count $overrides) -gt 0
                        nh os switch -- $overrides
                    else
                        nh os switch
                    end
                else
                    echo "NixConfig not found at $repo" >&2
                    return 1
                end
            end
          '';
        };

        # The function is defined here. The key binding is set below.
        ".config/fish/functions/navi-pick.fish" = {
          text = ''
            function navi-pick --description "Fuzzy search cheatsheets and insert into command line"
                set -l cmd (navi --print)
                if test -n "$cmd"
                    commandline -r -- $cmd
                end
                commandline -f repaint
            end
          '';
        };

        ".config/fish/functions/man.fish" = {
          text = ''
            function man --description "Show a tldr page, falling back to the real man page"
                tldr -q $argv 2>/dev/null
                or command man $argv
            end
          '';
        };

        ".config/fish/functions/ping.fish" = {
          text = ''
            function ping --description "Graph pings with gping, keeping ping's own flags"
                # gping reads -c as a colour and has no timeout or interval
                # flags, so hand those invocations to the real ping.
                if string match -qr -- '^-(c|W|w|i|I|s|t|n|q)' $argv
                    command ping $argv
                else
                    gping $argv
                end
            end
          '';
        };
      };

      environment.shellAliases =
        let
          eza = "eza --group-directories-first";
          ezaLong = "${eza} --long --git --time-style=long-iso";
        in
        {
          # eza stands in for ls. Deliberately separate aliases so extra flags
          # can be added without making the short listing noisy.
          ls = eza;
          l = "${ezaLong} --all";
          ll = ezaLong;
          la = "${ezaLong} --all";
          lt = "${ezaLong} --sort=modified --reverse";
          tree = "eza --tree --group-directories-first";

          # bat stands in for cat. Plain style and no pager keep cat semantics.
          cat = "bat --style=plain --paging=never";

          # Flags differ from the originals in places, so `command <tool>` is
          # the escape hatch when a real GNU utility is needed.
          grep = "rg";
          find = "fd";
          du = "dust";
          df = "duf";
          ps = "procs";
          diff = "difft";
          xxd = "hexyl";

          j = "jj";
          jl = "jj log";
          jd = "jj diff";
          js = "jj status";
          jc = "jj commit";
          jn = "jj new";
          je = "jj edit";
          jb = "jj bookmark";
          jp = "jj git push";
          jf = "jj git fetch";
          jup = "jj new 'trunk()'";
          jpull = "jj git fetch && jj new 'trunk()'";
          n = "nvim";
          t = "tmux";
          imv = "imv-dir";
          build-nixconf = "$HOME/NixConfig/build.sh";
        };

      # man and ping are fish functions rather than aliases: both need to fall
      # back to the real utility instead of breaking common invocations.
      environment.sessionVariables = {
        MANPAGER = "sh -c 'col -bx | bat -l man -p'";
        # The ansi theme follows the terminal palette, so bat matches the theme.
        BAT_THEME = "ansi";
        EZA_ICONS_AUTO = "1";
      };

      programs.fish = {
        enable = true;
        package = pkgs.fish;
        generateCompletions = false;

        shellAbbrs = {
          y = "yazi";
          nixclean = "sudo nix-collect-garbage --delete-older-than 30d";
        };

        interactiveShellInit = ''
          set -g fish_greeting
          stty -ixon 2>/dev/null

          # Cheatsheet picker.
          bind \cp navi-pick
          bind -M insert \cp navi-pick

          # Alt+Z opens the zoxide directory picker.
          bind \ez zi
          bind -M insert \ez zi

          # Ctrl+L clears the screen and redraws the prompt.
          bind \cl 'clear; commandline -f repaint'

          # Ctrl+Backspace deletes the previous word.
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

      programs.starship = {
        enable = true;
        package = pkgs.starship;
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
}
