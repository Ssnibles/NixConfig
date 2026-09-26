{ ... }:
{
  perSystem = { pkgs, ... }: {
    packages.pet = pkgs.pet;
  };

  nixos.modules.shared =
    {
      pkgs,
      config,
      ...
    }:
    {
      environment.systemPackages = [ pkgs.pet ];

      hjem.users."${config.username}" = {
        files = {
          ".config/pet/config.toml" = {
            text = ''
              [General]
              snippetfile = "/home/${config.username}/.config/pet/snippet.toml"
              editor = "nvim"
              column = 40
              selectcmd = "fzf"
              backend = "gist"
            '';
          };

          ".config/pet/snippet.toml" = {
            text = ''
              [[snippets]]
              description = "NixOS rebuild current host"
              command = "nh os switch"
              tag = ["nix", "system", "rebuild"]
              output = ""

              [[snippets]]
              description = "Nix flake update all inputs"
              command = "cd ~/NixConfig && nix flake update"
              tag = ["nix", "flake", "update"]
              output = ""

              [[snippets]]
              description = "Nix flake update single input"
              command = "cd ~/NixConfig && nix flake lock --update-input <input=nixpkgs-unstable>"
              tag = ["nix", "flake", "update"]
              output = ""

              [[snippets]]
              description = "Nix eval desktop system build"
              command = "cd ~/NixConfig && nix eval .#nixosConfigurations.<host=desktop>.config.system.build.toplevel"
              tag = ["nix", "debug", "eval"]
              output = ""

              [[snippets]]
              description = "Git clean branch from latest main"
              command = "git fetch origin && git switch main && git pull --ff-only && git switch -c <branch=feat/my-change>"
              tag = ["git", "workflow"]
              output = ""

              [[snippets]]
              description = "Git open pull request with body"
              command = "gh pr create --fill --base <base=main> --head <head=''$(git branch --show-current)>"
              tag = ["git", "github", "pr"]
              output = ""

              [[snippets]]
              description = "Git find commit introducing line"
              command = "git blame -L <line=1>,<line=1> <file=path/to/file>"
              tag = ["git", "debug"]
              output = ""

              [[snippets]]
              description = "Git clone via SSH"
              command = "git clone git@github.com:<username>/<repo_name>.git"
              tag = ["git", "debug"]
              output = ""

              [[snippets]]
              description = "Search TODO/FIXME excluding .git"
              command = "rg -n --hidden --glob '!.git' '<query=TODO|FIXME|HACK>' <path=.>"
              tag = ["search", "ripgrep"]
              output = ""

              [[snippets]]
              description = "Find file then preview with bat"
              command = "fd <name=default.nix> <path=.> | fzf | xargs -r bat --style=plain --paging=never"
              tag = ["search", "fd", "fzf"]
              output = ""

              [[snippets]]
              description = "Curl JSON API with jq pretty print"
              command = "curl -sS <url=https://api.github.com/repos/NixOS/nixpkgs> | jq ."
              tag = ["http", "json", "api"]
              output = ""

              [[snippets]]
              description = "List top 20 largest files"
              command = "du -ah <path=.> | sort -hr | head -n <n=20>"
              tag = ["disk", "debug"]
              output = ""

              [[snippets]]
              description = "Extract archive by extension"
              command = "file=<archive=archive.tar.gz>; case \"''$file\" in *.tar.gz|*.tgz) tar -xzf \"''$file\" ;; *.tar.xz) tar -xJf \"''$file\" ;; *.zip) unzip \"''$file\" ;; *) echo 'unsupported archive' >&2; exit 1 ;; esac"
              tag = ["archive", "utility"]
              output = ""

              [[snippets]]
              description = "Generate SSH key ed25519"
              command = "ssh-keygen -t ed25519 -C '<email=you@example.com>' -f ~/.ssh/<name=id_ed25519>"
              tag = ["ssh", "security"]
              output = ""

              [[snippets]]
              description = "Reload Quickshell UI in-place"
              command = "qs -c default ipc call quickshell reload all"
              tag = ["quickshell", "ui", "reload"]
              output = ""

              [[snippets]]
              description = "Pet add previous shell command"
              command = "pet new `history | tail -n 2 | head -n 1 | sed 's/^ *[0-9]\\+ *//'`"
              tag = ["pet", "snippet"]
              output = ""

              [[snippets]]
              description = "Set remote git URL to SSH (Manual)"
              command = "git remote set-url origin \"git@github.com:<username>/<repo_name>.git\""
              tag = ["git", "ssh"]
              output = ""

              [[snippets]]
              description = "Start new named tmux session"
              command = "tmux new -s <session=dev>"
              tag = ["tmux", "session"]
              output = ""

              [[snippets]]
              description = "Tmux attach to session (fuzzy select)"
              command = "tmux attach -t ''$(tmux list-sessions -F '#{session_name}' | fzf)"
              tag = ["tmux", "session", "fzf"]
              output = ""

              [[snippets]]
              description = "Tmux list all sessions"
              command = "tmux list-sessions"
              tag = ["tmux", "session"]
              output = ""

              [[snippets]]
              description = "Tmux switch to session (fuzzy select)"
              command = "tmux switch-client -t ''$(tmux list-sessions -F '#{session_name}' | fzf)"
              tag = ["tmux", "session", "fzf"]
              output = ""

              [[snippets]]
              description = "Tmux kill session"
              command = "tmux kill-session -t <session=dev>"
              tag = ["tmux", "session"]
              output = ""

              [[snippets]]
              description = "Tmux kill all sessions except current"
              command = "tmux kill-session -a -t ''$(tmux display-message -p '#{session_name}')"
              tag = ["tmux", "session", "cleanup"]
              output = ""

              [[snippets]]
              description = "Tmux reload config"
              command = "tmux source-file ~/.config/tmux/tmux.conf"
              tag = ["tmux", "config", "reload"]
              output = ""

              [[snippets]]
              description = "Tmux capture pane to file"
              command = "tmux capture-pane -t <pane=0> -p -S -<lines=500> > <output=pane.txt>"
              tag = ["tmux", "capture", "log"]
              output = ""

              [[snippets]]
              description = "Tmux split window and run command"
              command = "tmux split-window -t <session=dev> '<command=htop>'"
              tag = ["tmux", "pane", "split"]
              output = ""

              [[snippets]]
              description = "Tmux rename current window"
              command = "tmux rename-window '<name=editor>'"
              tag = ["tmux", "window"]
              output = ""

              [[snippets]]
              description = "Tmux move pane to new window"
              command = "tmux break-pane -t <session=dev> -s <pane=0>"
              tag = ["tmux", "pane", "window"]
              output = ""

              [[snippets]]
              description = "Nix garbage collect all generations"
              command = "sudo nix-collect-garbage -d"
              tag = ["nix", "cleanup", "gc"]
              output = ""

              [[snippets]]
              description = "Nix search for package"
              command = "nix search nixpkgs <query=neovim>"
              tag = ["nix", "search", "package"]
              output = ""

              [[snippets]]
              description = "Nix why-depends check"
              command = "cd ~/NixConfig && nix why-depends .#nixosConfigurations.''$(hostname).config.system.build.toplevel 'nixpkgs#<package=neovim>'"
              tag = ["nix", "debug", "dependency"]
              output = ""

              [[snippets]]
              description = "Nix build package without installing"
              command = "nix build nixpkgs#<package=neovim> --no-link --print-out-paths"
              tag = ["nix", "build", "package"]
              output = ""

              [[snippets]]
              description = "Git interactive rebase last N commits"
              command = "git rebase -i HEAD~<n=5>"
              tag = ["git", "rebase", "interactive"]
              output = ""

              [[snippets]]
              description = "Git log graph all branches"
              command = "git log --all --oneline --graph --decorate -n <n=30>"
              tag = ["git", "log", "graph"]
              output = ""

              [[snippets]]
              description = "Git diff between branches"
              command = "git diff <base=main>..<head=''$(git branch --show-current)> --stat"
              tag = ["git", "diff", "branch"]
              output = ""

              [[snippets]]
              description = "Git stash with message"
              command = "git stash push -m '<message=WIP>'"
              tag = ["git", "stash"]
              output = ""

              [[snippets]]
              description = "Find and replace in files"
              command = "rg -l '<search=old_text>' <path=.> | xargs sed -i 's/<search=old_text>/<replace=new_text>/g'"
              tag = ["search", "replace", "sed"]
              output = ""

              [[snippets]]
              description = "Find process using port"
              command = "ss -tlnp | grep ':<port=8080>'"
              tag = ["network", "port", "debug"]
              output = ""

              [[snippets]]
              description = "Quick HTTP file server"
              command = "python3 -m http.server <port=8080> -d <dir=.>"
              tag = ["http", "server", "utility"]
              output = ""

              [[snippets]]
              description = "Compress directory to tar.gz"
              command = "tar -czf <output=archive.tar.gz> -C <dir=.> ."
              tag = ["archive", "compress", "utility"]
              output = ""

              [[snippets]]
              description = "Count lines of code (excl. blank/comments)"
              command = "nix-shell -p tokei --run 'tokei <path=.>'"
              tag = ["code", "stats", "utility"]
              output = ""

              [[snippets]]
              description = "Journalctl for service since boot"
              command = "journalctl -u <service=ssh> -b --no-pager -n <lines=50>"
              tag = ["systemd", "log", "debug"]
              output = ""

              [[snippets]]
              description = "Copy files modified today to directory"
              command = "fd -e <ext=jpg> --changed-after \"''$(date +%F)\" <dir=.> -x cp -t <dest=~/Pictures/Car\\ Show>"
              tag = ["fd", "file", "copy"]
              output = ""

              [[snippets]]
              description = "Copy files modified within date range"
              command = "fd -e <ext=jpg> --changed-after '<after=2026-09-01>' --changed-before '<before=2026-09-20>' <dir=.> -x cp -t <dest=~/Pictures/Car\\ Show>"
              tag = ["fd", "file", "copy", "range"]
              output = ""

              [[snippets]]
              description = "Copy files modified on a custom day"
              command = "target='<date=2026-09-15>'; next=''$(date -I -d \"''$target + 1 day\"); fd -e <ext=jpg> --changed-after \"''$target\" --changed-before \"''$next\" <dir=.> -x cp -t <dest=~/Pictures/Car\\ Show>"
              tag = ["fd", "file", "copy", "date"]
              output = ""

              [[snippets]]
              description = "Mango get all clients"
              command = "nix-shell -p jq --run 'mmsg get all-clients | jq'"
              tag = ["mango", "api", "clients"]
              output = ""

              [[snippets]]
              description = "Mango get all layers"
              command = "nix-shell -p jq --run 'mmsg get all-layers | jq'"
              tag = ["mango", "api", "layers"]
              output = ""

              [[snippets]]
              description = "Flash a USB/ISO image (on-demand)"
              command = "nix-shell -p caligula --run 'caligula'"
              tag = ["nix", "on-demand", "usb", "flash"]
              output = ""

              [[snippets]]
              description = "Send files between machines (on-demand)"
              command = "nix-shell -p croc --run 'croc'"
              tag = ["nix", "on-demand", "file", "transfer"]
              output = ""

              [[snippets]]
              description = "Render mermaid diagrams (on-demand)"
              command = "nix-shell -p mermaid-cli --run 'mmdc'"
              tag = ["nix", "on-demand", "diagram", "mermaid"]
              output = ""

              [[snippets]]
              description = "Convert wallpaper image format (on-demand)"
              command = "nix-shell -p gowall --run 'gowall'"
              tag = ["nix", "on-demand", "wallpaper", "image"]
              output = ""

              [[snippets]]
              description = "Update / install Proton-GE for Steam (on-demand)"
              command = "nix-shell -p protonup-ng --run 'protonup'"
              tag = ["nix", "on-demand", "gaming", "steam", "proton"]
              output = ""

              [[snippets]]
              description = "Flash / query USB DFU device firmware (on-demand)"
              command = "nix-shell -p dfu-util --run 'dfu-util <args=-l>'"
              tag = ["nix", "on-demand", "firmware", "usb", "flash"]
              output = ""
            '';
          };
        };
      };
    };
}
