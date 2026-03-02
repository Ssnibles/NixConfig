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
    # Core
    kotlin
    kotlin-language-server
    jdk
    nixd
    nixpkgs-fmt
    lua-language-server
    code2prompt
    wl-clipboard
    libnotify
    brightnessctl

    # UI & Shell
    swww
    swaynotificationcenter
    ghostty
    yazi
    ripgrep
    mission-center
    grc
    nerd-fonts.fira-code

    # Media & Apps
    picard
    beets
    strawberry
    easytag
    firefox
    localsend
    android-tools
    impala
    bluetui
    blueman

    # Other
    flatpak
  ];

  home.sessionVariables = {
    SHELL = "${pkgs.fish}/bin/fish";
  };

  xdg.configFile."ghostty/config".text = ''
    command = ${pkgs.fish}/bin/fish
  '';

  programs.home-manager.enable = true;
}
