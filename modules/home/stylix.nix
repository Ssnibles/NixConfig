{
  pkgs,
  user,
  ...
}:
{
  imports = [ ../shared/stylix.nix ];

  # Enable HM program modules so Stylix targets can actually theme them.
  programs = {
    bat = {
      enable = true;
      package = pkgs.unstable.bat;
    };
    fzf = {
      enable = true;
      package = pkgs.unstable.fzf;
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
      options = {
        synctex = true;
        synctex-editor-command = "nvr --remote-send \"<C-\\><C-n>:edit %{input}<CR>:%{line}<CR>\"";
      };
    };
  };

  xdg.configFile = {
    "lazygit/config.yml".force = true;
  };

  stylix.targets = {
    bat.enable = true;
    firefox = {
      enable = true;
      profileNames = [ user ];
      colorTheme.enable = true;
    };
    fzf.enable = true;
    gtk.enable = true;
    lazygit.enable = true;
    qt.enable = true;
    spotify-player.enable = true;
    vicinae.enable = true;
    yazi.enable = true;
    zathura.enable = true;
  };
}
