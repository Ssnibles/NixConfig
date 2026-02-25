{ config, pkgs, ... }:

{
  home.username = "josh";
  home.homeDirectory = "/home/josh";
  home.stateVersion = "25.05";

  imports = [
    ./modules/fish.nix
    ./modules/hyprland.nix
    ./modules/neovim.nix
    ./modules/git.nix
    ./modules/other.nix
  ];

  home.packages = with pkgs; [
    picard
    beets
    strawberry
    easytag
    localsend
    android-tools
    nixd
    nixpkgs-fmt
    lua-language-server
    code2prompt
    wl-clipboard
    firefox
    ghostty
    yazi
    mission-center
    ripgrep
    nerd-fonts.fira-code
    grc
  ];

  home.sessionVariables = {
    SHELL = "${pkgs.fish}/bin/fish";
  };

  xdg.configFile."ghostty/config".text = ''
    command = ${pkgs.fish}/bin/fish
  '';

  programs.home-manager.enable = true;
}
