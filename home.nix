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
    # Core & Languages
    kotlin
    kotlin-language-server
    jdk21
    nixd
    jdt-language-server
    nixpkgs-fmt
    lua-language-server
    code2prompt
    wl-clipboard
    fzf
    fd
    ripgrep
    android-tools
    grc

    # UI & Shell
    foot
    ghostty
    yazi
    mission-center
    btop
    lazygit
    nerd-fonts.fira-code
    nerd-fonts.zed-mono
    nerd-fonts.jetbrains-mono

    # Media & Apps
    picard
    strawberry
    easytag
    spotify
    firefox
    localsend
    impala
    bluetui
    blueman
    vnote
    super-productivity
    zen-browser

    # Other
    flatpak
  ];

  home.sessionVariables = {
    SHELL = "${pkgs.fish}/bin/fish";
  };

  programs.home-manager.enable = true;
}
