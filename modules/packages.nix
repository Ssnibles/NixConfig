{ pkgs, hostProfile, ... }:

{
  home.packages =
    with pkgs;
    [
      # ── Dev ────────────────────────────────────────────────────────────────
      kotlin
      jdk21
      code2prompt

      # ── CLI utilities ───────────────────────────────────────────────────────
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

      # ── Fonts ───────────────────────────────────────────────────────────────
      nerd-fonts.fira-code
      nerd-fonts.zed-mono
      nerd-fonts.jetbrains-mono

      # ── GUI apps ────────────────────────────────────────────────────────────
      ghostty
      foot
      mission-center
      firefox
      zen-browser
      onlyoffice-desktopeditors
      libreoffice

      # ── PDF viewers ─────────────────────────────────────────────────────────
      sioyek
      zathura
      kdePackages.okular

      # ── Notes ───────────────────────────────────────────────────────────────
      trilium-desktop

      # ── Media ───────────────────────────────────────────────────────────────
      spotify
      strawberry
      picard
      easytag
      pavucontrol

      # ── System / networking ─────────────────────────────────────────────────
      localsend
      impala
      bluetui
      blueman
    ]
    ++ pkgs.lib.optionals hostProfile.isDesktop [
      # Gaming
      steam
      heroic
      lutris
      mangohud
      gamemode
      protonup-qt

      # Virtualisation
      virt-manager
    ]
    ++ pkgs.lib.optionals hostProfile.isLaptop [
      powertop
      acpi
      brightnessctl
      wlsunset
    ];
}
