{ config, pkgs, ... }: {
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
    ripgrep
    android-tools
    grc

    # UI & Shell
    ghostty
    yazi
    mission-center
    btop
    nerd-fonts.fira-code
    nerd-fonts.zed-mono
    nerd-fonts.jetbrains-mono

    # Media & Apps
    picard
    # beets
    strawberry
    easytag
    spotify
    firefox
    localsend
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
