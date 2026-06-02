{
  config,
  pkgs,
  inputs,
  semanticColors,
  ...
}:
let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  s = config.lib.stylix.colors;
  c = semanticColors { colors = s; };
  spicetifyStylixScheme = {
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
    wayland = true;
    enabledExtensions = with spicePkgs.extensions; [
      adblockify
      hidePodcasts
    ];
    enabledSnippets = [
      ''
        .main-nowPlayingView-contextItemInfo::before,
        .main-nowPlayingView-coverArtContainer::before,
        .main-nowPlayingView-coverArtContainer::after {
          background: none !important;
          background-image: none !important;
        }
        .main-nowPlayingView-contextItemInfo {
          background: var(--spice-main) !important;
        }
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
}
