# =============================================================================
# Package Configuration
# =============================================================================
# Defines the set of packages installed for the user.
# Uses hostProfile to differentiate between desktop and laptop needs.
# =============================================================================
{
  pkgs,
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
      # CLI utilities
      wl-clipboard
      fzf
      fd
      ripgrep
      grc
      android-tools
      lazygit
      btop
      yazi
      jq
      # Fonts
      nerd-fonts.fira-code
      nerd-fonts.zed-mono
      nerd-fonts.jetbrains-mono
      # GUI applications
      ghostty
      foot
      mission-center
      firefox
      zen-browser
      onlyoffice-desktopeditors
      # PDF viewers
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
      # System / networking
      localsend
      impala
      bluetui
      blueman
      satty
      grim
      slurp
    ]
    ++ pkgs.lib.optionals hostProfile.isDesktop [
      # Gaming
      steam
      steam-run
      heroic
      lutris
      mangohud
      gamemode
      protonup-qt
      # Virtualization
      quickemu
    ]
    ++ pkgs.lib.optionals hostProfile.isLaptop [
      iwd
      powertop
      acpi
      brightnessctl
      wlsunset
    ];
}
