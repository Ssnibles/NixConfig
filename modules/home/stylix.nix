{
  pkgs,
  ...
}:
let
  themeName = import ../../lib/stylix/current-theme.nix;
  themes = import ../../lib/stylix/themes.nix;
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
  # Enable HM program modules so Stylix targets can actually theme them.
  programs = {
    bat = {
      enable = true;
      package = pkgs.unstable.bat;
    };
    btop = {
      enable = true;
      package = pkgs.unstable.btop;
    };
    fzf = {
      enable = true;
      package = pkgs.unstable.fzf;
    };
    gitui = {
      enable = true;
      package = pkgs.unstable.gitui;
    };
    lazygit = {
      enable = true;
      package = pkgs.unstable.lazygit;
    };
    yazi = {
      enable = true;
      package = pkgs.unstable.yazi;
    };
    zathura = {
      enable = true;
      package = pkgs.unstable.zathura;
    };
  };

  # Take ownership of pre-existing configs on first Stylix migration.
  xdg.configFile."btop/btop.conf".force = true;
  xdg.configFile."lazygit/config.yml".force = true;

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
    base16Scheme =
      if builtins.isAttrs selectedTheme.scheme then
        selectedTheme.scheme
      else
        "${pkgs.base16-schemes}/share/themes/${selectedTheme.scheme}";
    polarity = selectedTheme.polarity;

    # Programs in this repo that should follow the currently selected Stylix
    # theme automatically.
    targets = {
      bat.enable = true;
      btop.enable = true;
      fzf.enable = true;
      gitui.enable = true;
      gtk.enable = true;
      lazygit.enable = true;
      qt.enable = true;
      spotify-player.enable = true;
      vicinae.enable = true;
      yazi.enable = true;
      zathura.enable = true;
      "zen-browser".enable = true;
    };
  };
}
