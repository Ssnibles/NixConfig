{
  pkgs,
  hostProfile,
  inputs,
  ...
}:
{
  home = {
    username = "josh";
    homeDirectory = "/home/josh";
    stateVersion = "25.05";
  };

  imports = [
    inputs.agenix.homeManagerModules.default
    ./modules/fish.nix
    ./modules/hyprland.nix
    ./modules/neovim.nix
    ./modules/git.nix
    ./modules/packages.nix
    ./modules/waybar.nix
    ./modules/swaync.nix
    ./modules/spotify.nix
    ./modules/scripts.nix
  ];

  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  home.sessionVariables.SHELL = "${pkgs.fish}/bin/fish";
  programs.home-manager.enable = true;
}
