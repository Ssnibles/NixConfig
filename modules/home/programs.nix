# =============================================================================
# Miscellaneous Program Configuration
# =============================================================================
# Configured Home Manager programs that don't warrant their own file.
# Currently: spotify-player (TUI client) and Java runtime.
# =============================================================================
{
  config,
  lib,
  pkgs,
  ...
}:
let
  spotifyIdFile = ../../secrets/spotify-id.age;
  spotifySecretFile = ../../secrets/spotify-secret.age;
  spotifySecretsAvailable =
    builtins.pathExists spotifyIdFile && builtins.pathExists spotifySecretFile;
in
{
  # Spotify Player (TUI client)
  programs.spotify-player = {
    enable = spotifySecretsAvailable;
    settings = {
      # Credentials are provisioned by agenix at runtime.
      client_id_command = "cat /run/agenix/spotify-id";
      client_secret_command = "cat /run/agenix/spotify-secret";
      device = {
        name = "Terminal";
        device_type = "computer";
      };
    };
  };

  warnings = lib.optional (!spotifySecretsAvailable) ''
    Spotify credentials are not configured.
    Add secrets/spotify-id.age and secrets/spotify-secret.age to enable spotify-player.
  '';

  # Direnv (Nix integration for shell environments)
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  xdg.configFile."pet/snippet.toml".text = ''
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
      command = "gh pr create --fill --base <base=main> --head <head=$(git branch --show-current)>"
      tag = ["git", "github", "pr"]
      output = ""

    [[snippets]]
      description = "Git find commit introducing line"
      command = "git blame -L <line=1>,<line=1> <file=path/to/file>"
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
      description = "Check SSL cert expiry"
      command = "echo | openssl s_client -connect <host=example.com>:443 2>/dev/null | openssl x509 -noout -dates"
      tag = ["network", "ssl", "debug"]
      output = ""

    [[snippets]]
      description = "List top 20 largest files"
      command = "du -ah <path=.> | sort -hr | head -n <n=20>"
      tag = ["disk", "debug"]
      output = ""

    [[snippets]]
      description = "Extract archive by extension"
      command = "file=<archive=archive.tar.gz>; case \"$file\" in *.tar.gz|*.tgz) tar -xzf \"$file\" ;; *.tar.xz) tar -xJf \"$file\" ;; *.zip) unzip \"$file\" ;; *) echo 'unsupported archive' >&2; exit 1 ;; esac"
      tag = ["archive", "utility"]
      output = ""

    [[snippets]]
      description = "Docker clean stopped and dangling"
      command = "docker container prune -f && docker image prune -f"
      tag = ["docker", "cleanup"]
      output = ""

    [[snippets]]
      description = "Kubernetes watch pods in namespace"
      command = "kubectl get pods -n <namespace=default> -w"
      tag = ["k8s", "ops"]
      output = ""

    [[snippets]]
      description = "Generate SSH key ed25519"
      command = "ssh-keygen -t ed25519 -C '<email=you@example.com>' -f ~/.ssh/<name=id_ed25519>"
      tag = ["ssh", "security"]
      output = ""

    [[snippets]]
      description = "Restart user service and view logs"
      command = "systemctl --user restart <service=waybar.service> && journalctl --user -u <service=waybar.service> -n <lines=100> --no-pager"
      tag = ["systemd", "debug"]
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

  '';

  xdg.configFile."pet/config.toml".text = ''
    [General]
      snippetfile = "${config.xdg.configHome}/pet/snippet.toml"
      editor = "${pkgs.neovim}/bin/nvim"
      selectcmd = "fzf --ansi --layout=reverse --height=40%"
      color = true
      sortby = "recency"
  '';
}
