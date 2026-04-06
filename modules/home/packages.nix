# =============================================================================
# Home Manager Package List
# =============================================================================
# Packages installed at the user level via Home Manager.
# Host-conditional sets use hostProfile flags set in flake.nix.
#
# Note: system-level tools (git, vim, btop, etc.) live in nixos/common.nix.
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
      # ── Development ────────────────────────────────────────────────────
      kotlin
      jdk21
      code2prompt
      nodejs

      # ── CLI utilities ───────────────────────────────────────────────────
      quickemu
      wl-clipboard
      fzf
      fd
      ripgrep
      grc
      android-tools
      lazygit
      gitui
      yazi
      jq
      texliveBasic
      imagemagick
      zip

      # ── Fonts ───────────────────────────────────────────────────────────
      nerd-fonts.fira-code
      nerd-fonts.zed-mono
      nerd-fonts.jetbrains-mono

      # ── GUI applications ────────────────────────────────────────────────
      ghostty
      foot
      mission-center
      firefox
      zen-browser
      onlyoffice-desktopeditors
      inkscape
      modrinth-app-unwrapped

      # ── Document viewers ────────────────────────────────────────────────
      sioyek
      zathura

      # ── Notes ───────────────────────────────────────────────────────────
      trilium-desktop

      # ── Media ───────────────────────────────────────────────────────────
      spotify
      strawberry
      picard
      easytag
      pavucontrol

      # ── System / connectivity ────────────────────────────────────────────
      localsend
      impala
      bluetui
      blueman
      satty
      grim
      slurp
    ]
    # ── Desktop-only packages ─────────────────────────────────────────────
    ++ lib.optionals hostProfile.isDesktop [
      steam
      heroic
      lutris
      mangohud
      protonup-qt
    ]
    # ── Laptop-only packages ──────────────────────────────────────────────
    ++ lib.optionals hostProfile.isLaptop [
      powertop
      acpi
      brightnessctl
      wlsunset # Blue-light filter for evenings
    ];
}
