# =============================================================================
# Miscellaneous Program Configuration
# =============================================================================
# Configured Home Manager programs that don't warrant their own file.
# Currently: spicetify, spotify-player (TUI client), and misc programs.
# =============================================================================
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  spotifyIdFile = ../../secrets/spotify-id.age;
  spotifySecretFile = ../../secrets/spotify-secret.age;
  spotifySecretsAvailable =
    builtins.pathExists spotifyIdFile && builtins.pathExists spotifySecretFile;
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};
  c = import ../../lib/stylix/semantic-colors.nix { stylixColors = config.lib.stylix.colors; };
  spicetifyStylixScheme = {
    # Spicetify base keys
    text = c.fg;
    subtext = c.fgMid;
    main = c.bg;
    "main-elevated" = c.bgRaised;
    highlight = c.bgSubtle;
    "highlight-elevated" = config.lib.stylix.colors.base03;
    sidebar = c.bgRaised;
    player = c.bg;
    card = c.bgRaised;
    shadow = c.bg;
    "selected-row" = c.bgSubtle;
    button = c.accent;
    "button-active" = c.accent;
    "button-disabled" = c.fgDim;
    "tab-active" = c.bgSubtle;
    notification = c.bgRaised;
    "notification-error" = c.red;
    equalizer = c.accent;
    misc = c.bgSubtle;

    # Catppuccin variables used by the catppuccin Spicetify theme
    crust = config.lib.stylix.colors.base00;
    mantle = config.lib.stylix.colors.base01;
    base = c.bg;
    surface0 = c.bgRaised;
    surface1 = c.bgSubtle;
    surface2 = config.lib.stylix.colors.base03;
    overlay0 = config.lib.stylix.colors.base03;
    overlay1 = config.lib.stylix.colors.base04;
    overlay2 = config.lib.stylix.colors.base05;
    rosewater = config.lib.stylix.colors.base07;
    flamingo = c.magenta;
    pink = c.purple;
    maroon = c.red;
    red = c.red;
    peach = c.orange;
    yellow = c.yellow;
    green = c.green;
    teal = c.teal;
    sapphire = c.tealBright;
    blue = c.accent;
    sky = c.teal;
    mauve = c.purple;
    lavender = config.lib.stylix.colors.base06;
  };
in
{
  programs.spicetify = {
    enable = true;
    enabledExtensions = with spicePkgs.extensions; [
      adblockify
      hidePodcasts
    ];
    enabledSnippets = [
      ''
        /* Flatten now-playing side panel overlays for consistent colors. */
        .main-nowPlayingView-contextItemInfo::before,
        .main-nowPlayingView-coverArtContainer::before,
        .main-nowPlayingView-coverArtContainer::after {
          background: none !important;
          background-image: none !important;
        }

        .main-nowPlayingView-contextItemInfo {
          background: var(--spice-main) !important;
        }

        /* Remove dynamic playlist/album header gradients that clash with text. */
        .main-entityHeader-backgroundColor,
        .main-actionBarBackground-background {
          background: var(--spice-main) !important;
        }

        .main-entityHeader-background.main-entityHeader-gradient,
        .main-entityHeader-background.main-entityHeader-overlay {
          opacity: 0 !important;
        }

        .main-entityHeader-title,
        .main-entityHeader-titleButton,
        .main-entityHeader-subtitle,
        .main-entityHeader-metaData {
          color: var(--spice-text) !important;
        }
      ''
    ];
    theme = spicePkgs.themes.catppuccin;
    colorScheme = "custom";
    customColorScheme = spicetifyStylixScheme;
  };

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

  # Zen Browser is packaged from an external flake; configure it via the
  # Home Manager Firefox module by swapping the package.
  programs.firefox = {
    enable = true;
    package = pkgs.zen-browser;
    # Home Manager's Firefox module defaults to ~/.mozilla/firefox.
    # Zen Browser expects profiles under ~/.zen.
    configPath = ".zen";
    profiles.josh = {
      isDefault = true;
      preConfig = builtins.readFile "${inputs.betterfox}/user.js";
      settings = {
        "browser.startup.homepage" = "https://startpage.com";
        "browser.tabs.unloadOnLowMemory" = true;
        "zen.view.compact.show-sidebar-and-toolbar-on-hover" = true;
        "browser.sessionstore.interval" = 600000;
      };
      # These need to come after Betterfox so they always win.
      extraConfig = ''
        user_pref("zen.theme.content-element-separation", 0);
        user_pref("zen.theme.border-radius", 0);
        user_pref("widget.gtk.rounded-bottom-corners.enabled", false);
      '';
    };
  };

  programs.quickshell = {
    enable = true;
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
