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
  inputs,
  ...
}:
{
  home.packages = [
    pkgs.zen-browser # From flake overlay
    pkgs.awww # From flake overlay
  ]
  ++ (with pkgs.unstable; [
    # ── Development ────────────────────────────────────────────────────
    kotlin
    openjdk25
    code2prompt
    nodejs
    dotnet-sdk_10
    roslyn

    # ── CLI utilities ───────────────────────────────────────────────────
    quickemu
    gemini-cli
    github-copilot-cli
    wl-clipboard
    pkgs.age
    inputs.agenix.packages.${pkgs.system}.default
    fzf
    fd
    ripgrep
    ripgrep-all
    grc
    bat
    eza
    dust
    duf
    procs
    zoxide
    tlrc
    delta
    hyperfine
    sd
    choose
    just
    watchexec
    xh
    android-tools
    lazygit
    gitui
    pet
    yazi
    jq
    nix-tree
    nix-output-monitor
    deadnix
    statix
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
    kdePackages.dolphin
    firefox
    via
    onlyoffice-desktopeditors
    inkscape
    prismlauncher

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
  ])
  # ── Desktop-only packages ─────────────────────────────────────────────
  ++ lib.optionals hostProfile.isDesktop (
    with pkgs.unstable;
    [
      steam
      heroic
      lutris
      mangohud
      protonup-qt
    ]
  )
  # ── Laptop-only packages ──────────────────────────────────────────────
  ++ lib.optionals hostProfile.isLaptop (
    with pkgs.unstable;
    [
      powertop
      acpi
      brightnessctl
      wlsunset # Blue-light filter for evenings
    ]
  );
}
