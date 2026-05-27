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
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  s = config.lib.stylix.colors;
  c = import ../../lib/stylix/semantic-colors.nix { stylixColors = s; };
  spicetifyStylixScheme = {
    # Spicetify keys, mapped by their intended UI role.
    text = c.fg;
    subtext = c.fgMid;
    main = c.bg;
    "main-elevated" = c.bgRaised;
    highlight = c.bgSubtle;
    "highlight-elevated" = s.base03;
    sidebar = c.bgRaised;
    player = c.bgRaised;
    card = c.bgSubtle;
    shadow = c.bg;
    "selected-row" = c.fgMid;
    button = c.accent;
    "button-active" = c.teal;
    "button-disabled" = c.fgDim;
    "tab-active" = c.bgSubtle;
    notification = c.bgRaised;
    "notification-error" = c.red;
    equalizer = c.green;
    misc = s.base03;

    # Catppuccin variables used by the catppuccin Spicetify theme
    crust = s.base00;
    mantle = s.base01;
    base = c.bg;
    surface0 = c.bgRaised;
    surface1 = c.bgSubtle;
    surface2 = s.base03;
    overlay0 = s.base03;
    overlay1 = s.base04;
    overlay2 = s.base04;
    rosewater = s.base07;
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
    lavender = s.base06;
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
        extensions = {
          packages = with pkgs.nur.repos.rycee.firefox-addons; [
            ublock-origin
            bitwarden
          ];
        };
        extensions.force = true;
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

  xdg.configFile."pet/snippet.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/NixConfig/live/pet/snippet.toml";
  xdg.configFile."pet/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/NixConfig/live/pet/config.toml";
}
