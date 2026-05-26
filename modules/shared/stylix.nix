{
  pkgs,
  ...
}:
let
  themeName = import ../../lib/stylix/current-theme.nix;
  themesFile = import ../../lib/stylix/themes.nix;
  wallpaper = themesFile.wallpaper;
  themes = themesFile.themes;
  selectedTheme =
    if builtins.hasAttr themeName themes then
      themes.${themeName}
    else
      {
        scheme = "catppuccin-mocha.yaml";
        polarity = "dark";
      };
in
{
  assertions = [
    {
      assertion = builtins.hasAttr themeName themes;
      message = ''
        Stylix theme "${themeName}" is not defined in lib/stylix/themes.nix.
      '';
    }
  ];

  stylix = {
    enable = true;
    autoEnable = false;
    image = wallpaper;
    base16Scheme =
      if builtins.isAttrs selectedTheme.scheme then
        selectedTheme.scheme
      else
        "${pkgs.base16-schemes}/share/themes/${selectedTheme.scheme}";
    polarity = selectedTheme.polarity;
  };
}
