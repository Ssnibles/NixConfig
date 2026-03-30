# =============================================================================
# Home Manager Package Configuration
# =============================================================================
# User packages installed via Home Manager.
# This is a Home Manager module - only import in home.nix, NOT in NixOS configs.
# =============================================================================
{
  pkgs,
  lib,
  hostProfile,
  ...
}:
{
  home.packages =
    with pkgs;
    [
      # Development
      kotlin
      jdk21
      code2prompt
      nodejs
      # CLI
      wl-clipboard
      fzf
      fd
      ripgrep
      grc
      android-tools
      lazygit
      gitui
      btop
      yazi
      jq
      texliveBasic
      imagemagick
      zip
      # Fonts
      nerd-fonts.fira-code
      nerd-fonts.zed-mono
      nerd-fonts.jetbrains-mono
      # GUI
      ghostty
      foot
      mission-center
      firefox
      zen-browser
      onlyoffice-desktopeditors
      inkscape
      # PDF
      sioyek
      zathura
      # Notes
      trilium-desktop
      # Media
      spotify
      strawberry
      picard
      easytag
      pavucontrol
      # System
      localsend
      impala
      bluetui
      blueman
      satty
      grim
      slurp
      # iwd removed - now in environment.systemPackages
    ]
    ++ lib.optionals hostProfile.isDesktop [
      modrinth-app-unwrapped
      steam
      heroic
      lutris
      mangohud
      gamemode
      protonup-qt
      quickemu
    ]
    ++ lib.optionals hostProfile.isLaptop [
      powertop
      acpi
      brightnessctl
      wlsunset
    ];
}
