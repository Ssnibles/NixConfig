{
  pkgs,
  inputs,
  ...
}:
{
  home = {
    username = "josh";
    homeDirectory = "/home/josh";
    stateVersion = "26.05";
  };

  imports = [
    inputs.agenix.homeManagerModules.default
    inputs.stylix.homeModules.stylix
    inputs.nvf.homeManagerModules.default
    inputs.spicetify-nix.homeManagerModules.spicetify

    ../../modules/home
  ];

  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
  };

  programs.home-manager.enable = true;
}
