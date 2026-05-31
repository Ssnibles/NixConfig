{ config, pkgs, ... }:
let
  c = import ../../../lib/stylix/semantic-colors.nix { stylixColors = config.lib.stylix.colors; };
  wallpaper = toString (import ../../../lib/stylix/themes.nix).wallpaper;
in
{
  programs.swaylock = {
    enable = true;
    package = pkgs.unstable.swaylock;
    settings = {
      "ignore-empty-password" = true;
      font = "JetBrains Mono";
      "font-size" = 14;
      screenshots = true;
      clock = true;
      "indicator-idle-visible" = true;
      "indicator-radius" = 100;
      "indicator-thickness" = 10;
      "line-color" = c.accent;
      "ring-color" = c.border;
      "inside-color" = c.bg;
      "key-hl-color" = c.accent;
      "separator-color" = c.border;
      "text-color" = c.fg;
      "text-clear-color" = c.fg;
      "text-caps-lock-color" = c.yellow;
      "text-ver-color" = c.fg;
      "text-wrong-color" = c.red;
      "inside-clear-color" = c.bg;
      "inside-ver-color" = c.bg;
      "inside-wrong-color" = c.bg;
      "ring-clear-color" = c.accent;
      "ring-ver-color" = c.accent;
      "ring-wrong-color" = c.red;
      "bs-hl-color" = c.red;
      "caps-lock-key-hl-color" = c.yellow;
      "layout-bg-color" = c.bg;
      "layout-border-color" = c.border;
      "layout-text-color" = c.fg;
    };
  };
}
