{
  pkgs,
  lib,
  config,
  user,
  ...
}:
let
  enableUnsupportedProgramExample = false;
in
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
    };
  };

  xdg.configFile = lib.mkMerge [
    # Take ownership of pre-existing configs on first Stylix migration.
    {
      "lazygit/config.yml".force = true;
    }

    # Example for unsupported programs: render a config file using current
    # Stylix colors. Set enableUnsupportedProgramExample = true to try it.
    (lib.mkIf enableUnsupportedProgramExample {
      "example-app/config.toml".text = ''
        # Example config for apps without a Stylix target
        [theme]
        mode = "${config.lib.stylix.colors.variant}"
        background = "#${config.lib.stylix.colors.base00}"
        foreground = "#${config.lib.stylix.colors.base05}"
        accent = "#${config.lib.stylix.colors.base0D}"
      '';
    })
  ];

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
