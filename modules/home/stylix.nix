{
  pkgs,
  user,
  ...
}:
let
  unstableProg = pkg: { enable = true; package = pkg; };
in
{
  imports = [ ../shared/stylix.nix ];

  # Enable HM program modules so Stylix targets can actually theme them.
  programs = {
    bat = unstableProg pkgs.unstable.bat;
    fzf = unstableProg pkgs.unstable.fzf;
    lazygit = unstableProg pkgs.unstable.lazygit;
    yazi = unstableProg pkgs.unstable.yazi // {
      shellWrapperName = "yy";
    };
    zathura = unstableProg pkgs.unstable.zathura // {
      options = {
        synctex = true;
        synctex-editor-command = "nvr --remote-send \"<C-\\><C-n>:edit %{input}<CR>:%{line}<CR>\"";
      };
    };
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
