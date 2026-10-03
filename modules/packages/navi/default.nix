{ ... }:
{
  perSystem = { pkgs, ... }: {
    packages.navi = pkgs.navi;
  };

  nixos.modules.shared =
    {
      pkgs,
      config,
      ...
    }:
    let
      lib = pkgs.lib;

      naviDir = "/home/${config.username}/.config/navi";
      cheatsDir = "${naviDir}/cheats";

      # Cheats are declared as typed Nix data and rendered to navi `.cheat`
      # files. pet's `<name=default>` placeholders are translated to navi's
      # `<name>` variables plus a `$ name: ...` suggestion line, so the old
      # defaults still show up pre-selected in the picker.
      #
      # The generated files are read-only store symlinks; this module is the
      # source of truth, so add snippets here and rebuild.
      mk = description: command: tag: {
        inherit description command tag;
        extraSuggestions = [ ];
      };

      # Same as `mk`, but with raw navi `$ name: ...` suggestion lines, used for
      # dependent defaults (e.g. making the binary name follow the package).
      mkSuggestions = extraSuggestions: description: command: tag: {
        inherit
          description
          command
          tag
          extraSuggestions
          ;
      };

      # --- navi cheat rendering -------------------------------------------
      # Splits a command on `<...>` placeholders. Returns a list where a
      # placeholder's inner text is a single-element list and literal text is a
      # string. `builtins.split` includes only capture groups, so the group
      # captures everything between the angle brackets.
      splitOnVars = command: builtins.split "<([^>]*)>" command;
      varInner = m: builtins.elemAt m 0;

      # `name=default` -> { name, default }; `name` -> { name, default = null }.
      parseVar =
        inner:
        let
          m = builtins.match "([^=]*)=(.*)" inner;
        in
        if m == null then
          {
            name = inner;
            default = null;
          }
        else
          {
            name = builtins.elemAt m 0;
            default = builtins.elemAt m 1;
          };

      # Rewrites `<name=default>` to navi's `<name>`.
      renderCommand =
        command:
        lib.concatStringsSep "" (
          map (part: if builtins.isList part then "<${(parseVar (varInner part)).name}>" else part) (
            splitOnVars command
          )
        );

      # Unique variables in first-seen order, each with its default.
      paramVars =
        command:
        let
          matches = builtins.filter builtins.isList (splitOnVars command);
          vars = map (m: parseVar (varInner m)) matches;
          names = lib.unique (map (v: v.name) vars);
        in
        map (
          n:
          lib.findFirst (v: v.name == n) {
            name = n;
            default = null;
          } vars
        ) names;

      # navi suggestion line for a variable, or null when it has no default.
      suggestion =
        v:
        if v.default == null then
          null
        else if lib.hasPrefix "$(" v.default && lib.hasSuffix ")" v.default then
          # The old default was itself a shell command, e.g.
          # `$(git branch --show-current)`: let navi run it for suggestions.
          "$ ${v.name}: ${lib.removeSuffix ")" (lib.removePrefix "$(" v.default)}"
        else
          "$ ${v.name}: echo ${lib.escapeShellArg v.default}";

      renderCheat =
        s:
        let
          suggestions =
            builtins.filter (x: x != null) (map suggestion (paramVars s.command)) ++ s.extraSuggestions;
        in
        lib.concatStringsSep "\n" (
          [
            "% ${lib.concatStringsSep ", " s.tag}"
            ""
            "# ${s.description}"
            (renderCommand s.command)
          ]
          ++ suggestions
          ++ [ "" ]
        );

      renderCheats = snippets: lib.concatMapStringsSep "\n" renderCheat snippets;

      # Core snippets (rendered to their own core.cheat).
      core = [
        (mk "NixOS rebuild current host" "nh os switch" [
          "nix"
          "system"
          "rebuild"
        ])
        (mk "Nix flake update all inputs" "cd ~/NixConfig && nix flake update" [
          "nix"
          "flake"
          "update"
        ])
        (mk "Nix clean old generations" "nh clean all --keep <n=10>" [
          "nix"
          "cleanup"
          "gc"
        ])
        (mk "Nix update and rebuild (jj fetch + nh switch)" "cd ~/NixConfig && jj git fetch && nh os switch"
          [
            "nix"
            "jj"
            "rebuild"
          ]
        )
      ];

      # Everything else is grouped by topic; each attr becomes cheats/<name>.cheat.
      snippets = {
        nix = [
          (mk "Nix flake update single input" "cd ~/NixConfig && nix flake update <input=nixpkgs-unstable>" [
            "nix"
            "flake"
            "update"
          ])
          (mk "Nix flake check" "cd ~/NixConfig && nix flake check" [
            "nix"
            "flake"
            "check"
          ])
          (mk "Nix eval host system toplevel"
            "cd ~/NixConfig && nix eval .#nixosConfigurations.<host=desktop>.config.system.build.toplevel"
            [
              "nix"
              "debug"
              "eval"
            ]
          )
          (mk "Nix why-depends check"
            "cd ~/NixConfig && nix why-depends .#nixosConfigurations.$(hostname).config.system.build.toplevel 'nixpkgs#<package=neovim>'"
            [
              "nix"
              "debug"
              "dependency"
            ]
          )
          (mk "Nix build package without installing"
            "nix build nixpkgs#<package=neovim> --no-link --print-out-paths"
            [
              "nix"
              "build"
              "package"
            ]
          )
          (mk "Nix search package by name" "nix search nixpkgs <query=neovim>" [
            "nix"
            "search"
            "package"
          ])
          (mk "Nix locate binary in nixpkgs (nix-index)" "nix-locate --whole-name bin/<name=neovim>" [
            "nix"
            "search"
            "nix-index"
          ])
          (mk "Enter dev shell for a flake" "nix develop <path=.>" [
            "nix"
            "dev"
            "shell"
          ])
          (mk "Run a package without installing" "nix run nixpkgs#<package=cowsay>" [
            "nix"
            "run"
            "on-demand"
          ])
        ];

        git = [
          (mk "Git clean branch from latest main"
            "git fetch origin && git switch main && git pull --ff-only && git switch -c <branch=feat/my-change>"
            [
              "git"
              "workflow"
            ]
          )
          (mk "Git open pull request with body" "gh pr create --fill --base <base=main>" [
            "git"
            "github"
            "pr"
          ])
          (mk "Git find commit introducing line" "git blame -L <start=1>,<end=1> <file=path/to/file>" [
            "git"
            "debug"
          ])
          (mk "Git clone via SSH" "git clone git@github.com:<username>/<repo>.git" [
            "git"
            "ssh"
            "clone"
          ])
          (mk "Set remote origin to SSH" "git remote set-url origin \"git@github.com:<username>/<repo>.git\""
            [
              "git"
              "ssh"
            ]
          )
          (mk "Git interactive rebase last N commits" "git rebase -i HEAD~<n=5>" [
            "git"
            "rebase"
          ])
          (mk "Git log graph all branches" "git log --all --oneline --graph --decorate -n <n=30>" [
            "git"
            "log"
          ])
          (mk "Git diff between branches" "git diff <base=main>..<head=HEAD> --stat" [
            "git"
            "diff"
          ])
          (mk "Git stash with message" "git stash push -m '<message=WIP>'" [
            "git"
            "stash"
          ])
          (mk "Git switch to previous branch" "git switch -" [
            "git"
            "workflow"
          ])
          (mk "Git fixup then autosquash"
            "git commit --fixup=<target=HEAD~1> && git rebase -i --autosquash <base=main>"
            [
              "git"
              "rebase"
              "workflow"
            ]
          )
          (mk "Git add worktree" "git worktree add <path=../worktree> -b <branch=feat/wt>" [
            "git"
            "worktree"
          ])
          (mk "GitHub checkout pull request" "gh pr checkout <number=1>" [
            "git"
            "github"
            "pr"
          ])
          (mk "GitHub watch latest workflow run" "gh run watch" [
            "git"
            "github"
            "ci"
          ])
        ];

        jj = [
          (mk "jj commit with current date" "jj commit -m \"$(date)\"" [
            "jj"
            "commit"
          ])
          (mk "jj new on trunk" "jj new 'trunk()'" [
            "jj"
            "workflow"
          ])
          (mk "jj log recent changes" "jj log -n <n=20>" [
            "jj"
            "log"
          ])
          (mk "jj describe current change" "jj describe -m '<message=WIP>'" [
            "jj"
            "describe"
          ])
          (mk "jj rebase onto destination" "jj rebase -d <destination=main>" [
            "jj"
            "rebase"
          ])
          (mk "jj undo last operation" "jj undo" [
            "jj"
            "undo"
          ])
          (mk "jj git push" "jj git push" [
            "jj"
            "git"
            "push"
          ])
          (mk "jj abandon current change" "jj abandon" [
            "jj"
            "cleanup"
          ])
        ];

        tmux = [
          (mk "Start new named tmux session" "tmux new -s <session=dev>" [
            "tmux"
            "session"
          ])
          (mk "Tmux attach to session (fuzzy select)"
            "tmux attach -t $(tmux list-sessions -F '#{session_name}' | fzf)"
            [
              "tmux"
              "session"
              "fzf"
            ]
          )
          (mk "Tmux switch to session (fuzzy select)"
            "tmux switch-client -t $(tmux list-sessions -F '#{session_name}' | fzf)"
            [
              "tmux"
              "session"
              "fzf"
            ]
          )
          (mk "Tmux kill all sessions except current"
            "tmux kill-session -a -t $(tmux display-message -p '#{session_name}')"
            [
              "tmux"
              "session"
              "cleanup"
            ]
          )
          (mk "Tmux reload config" "tmux source-file ~/.config/tmux/tmux.conf" [
            "tmux"
            "config"
            "reload"
          ])
          (mk "Tmux capture pane to file"
            "tmux capture-pane -t <pane=0> -p -S -<lines=500> > <output=pane.txt>"
            [
              "tmux"
              "capture"
              "log"
            ]
          )
          (mk "Tmux move pane to new window" "tmux break-pane -t <session=dev> -s <pane=0>" [
            "tmux"
            "pane"
            "window"
          ])
          (mk "Sesh session picker" "sesh picker" [
            "tmux"
            "session"
            "sesh"
          ])
        ];

        files = [
          (mk "Search TODO/FIXME excluding .git"
            "rg -n --hidden --glob '!.git' '<query=TODO|FIXME|HACK>' <path=.>"
            [
              "files"
              "search"
              "ripgrep"
            ]
          )
          (mk "Find file then preview with bat"
            "fd <name=default.nix> <path=.> | fzf | xargs -r bat --style=plain --paging=never"
            [
              "files"
              "fd"
              "fzf"
            ]
          )
          (mk "Open file in nvim (fuzzy select)" "rg --files | fzf | xargs -r nvim" [
            "files"
            "fzf"
            "nvim"
          ])
          (mk "List top 20 largest files" "du -ah <path=.> | sort -hr | head -n <n=20>" [
            "files"
            "disk"
            "debug"
          ])
          (mk "Extract archive (auto-detect format)" "tar -xf <archive=archive.tar.gz>" [
            "files"
            "archive"
          ])
          (mk "Compress directory to tar.gz" "tar -czf <output=archive.tar.gz> -C <dir=.> ." [
            "files"
            "archive"
            "compress"
          ])
          (mk "Zip a directory (recursive)" "zip -r <output=archive.zip> <target=.>" [
            "files"
            "archive"
            "zip"
          ])
          (mk "Unzip an archive" "unzip <archive=archive.zip> -d <dest=.>" [
            "files"
            "archive"
            "unzip"
          ])
          (mk "List zip contents" "unzip -l <archive=archive.zip>" [
            "files"
            "archive"
            "unzip"
          ])
          (mk "Extract a single file from a zip"
            "unzip <archive=archive.zip> <member=path/in/zip> -d <dest=.>"
            [
              "files"
              "archive"
              "unzip"
            ]
          )
          (mk "Find and replace in files"
            "rg -l '<search=old_text>' <path=.> | xargs sed -i 's/<search=old_text>/<replace=new_text>/g'"
            [
              "files"
              "search"
              "replace"
            ]
          )
          (mk "Copy files modified today"
            "fd -e <ext=jpg> --changed-after \"$(date +%F)\" <dir=.> -x cp -t <dest=~/Pictures/Car\\ Show>"
            [
              "files"
              "fd"
              "copy"
            ]
          )
          (mk "Copy files modified within date range"
            "fd -e <ext=jpg> --changed-after '<after=2026-09-01>' --changed-before '<before=2026-09-20>' <dir=.> -x cp -t <dest=~/Pictures/Car\\ Show>"
            [
              "files"
              "fd"
              "copy"
            ]
          )
          (mk "Copy files modified on a custom day"
            "next=$(date -I -d '<date=2026-09-15> + 1 day'); fd -e <ext=jpg> --changed-after '<date=2026-09-15>' --changed-before $next <dir=.> -x cp -t <dest=~/Pictures/Car\\ Show>"
            [
              "files"
              "fd"
              "copy"
            ]
          )
          (mk "Curl JSON API with jq pretty print"
            "curl -sS <url=https://api.github.com/repos/NixOS/nixpkgs> | jq ."
            [
              "files"
              "http"
              "json"
            ]
          )
          (mk "Quick HTTP file server (localhost)"
            "python3 -m http.server <port=8080> --bind 127.0.0.1 -d <dir=.>"
            [
              "files"
              "http"
              "server"
            ]
          )
          (mk "Count lines of code (tokei)" "nix shell nixpkgs#tokei -c tokei <path=.>" [
            "files"
            "code"
            "stats"
          ])
          (mk "Yazi in directory" "yazi <dir=.>" [
            "files"
            "yazi"
          ])
        ];

        system = [
          (mk "Find process using port" "ss -tlnp | grep ':<port=8080>'" [
            "system"
            "network"
            "port"
          ])
          (mk "Journalctl for service since boot" "journalctl -u <service=ssh> -b --no-pager -n <lines=50>" [
            "system"
            "systemd"
            "log"
          ])
          (mk "Restart service and follow logs"
            "sudo systemctl restart <unit=ssh> && journalctl -u <unit=ssh> -f"
            [
              "system"
              "systemd"
              "debug"
            ]
          )
          (mk "Generate SSH key ed25519"
            "ssh-keygen -t ed25519 -C '<email=you@example.com>' -f ~/.ssh/<name=id_ed25519>"
            [
              "system"
              "ssh"
              "security"
            ]
          )
          (mk "Reload Quickshell UI in-place" "qs -c default ipc call quickshell reload all" [
            "system"
            "quickshell"
            "reload"
          ])
          (mk "Allow direnv in current directory" "direnv allow" [
            "system"
            "direnv"
          ])
        ];

        mango = [
          (mk "Mango get all clients" "mmsg get all-clients | nix shell nixpkgs#jq -c jq" [
            "mango"
            "api"
            "clients"
          ])
          (mk "Mango get all layers" "mmsg get all-layers | nix shell nixpkgs#jq -c jq" [
            "mango"
            "api"
            "layers"
          ])
        ];

        on-demand = [
          (mk "Flash a USB/ISO image (on-demand)" "nix shell nixpkgs#caligula -c caligula" [
            "on-demand"
            "nix"
            "usb"
            "flash"
          ])
          (mk "Send files between machines (croc)" "nix shell nixpkgs#croc -c croc" [
            "on-demand"
            "nix"
            "file"
            "transfer"
          ])
          (mk "Render mermaid diagrams (mmdc)" "nix shell nixpkgs#mermaid-cli -c mmdc" [
            "on-demand"
            "nix"
            "diagram"
            "mermaid"
          ])
          (mk "Convert wallpaper image format (gowall)" "nix shell nixpkgs#gowall -c gowall" [
            "on-demand"
            "nix"
            "wallpaper"
            "image"
          ])
          (mk "Update/install Proton-GE for Steam (protonup)" "nix shell nixpkgs#protonup-ng -c protonup" [
            "on-demand"
            "nix"
            "gaming"
            "steam"
            "proton"
          ])
          (mk "Flash/query USB DFU device firmware (dfu-util)"
            "nix shell nixpkgs#dfu-util -c dfu-util <args=-l>"
            [
              "on-demand"
              "nix"
              "firmware"
              "usb"
              "flash"
            ]
          )
          (mkSuggestions [ "$ command: echo '<package>'" ] "Run a package on-demand with args (nix shell)"
            "nix shell nixpkgs#<package=dust> -c <command> <args=./>"
            [
              "on-demand"
              "nix"
              "run"
            ]
          )
          (mk "Run a package's default command (nix run)" "nix run nixpkgs#<package=dust> -- <args=./>" [
            "on-demand"
            "nix"
            "run"
          ])
        ];
      };

      allSnippets = {
        core = core;
      }
      // snippets;

      cheatFiles = lib.mapAttrs' (
        name: value:
        lib.nameValuePair ".config/navi/cheats/${name}.cheat" {
          text = renderCheats value;
        }
      ) allSnippets;
    in
    {
      environment.systemPackages = [ pkgs.navi ];

      hjem.users."${config.username}" = {
        files = {
          ".config/navi/config.yaml" = {
            text = ''
              cheats:
                paths:
                  - ${cheatsDir}
              finder:
                command: fzf
                # navi already runs `navi preview {}`; this widens the pane,
                # wraps long commands, and toggles it with Ctrl-/.
                overrides: --preview-window 'right:55%:wrap' --bind 'ctrl-/:toggle-preview'
            '';
          };
        }
        // cheatFiles;
      };
    };
}
