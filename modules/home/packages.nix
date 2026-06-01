# =============================================================================
# Home Manager Package List
# =============================================================================
# Packages installed at the user level via Home Manager.
# Host-conditional sets use hostProfile flags set in flake.nix.
#
# Note: system-level tools (git, vim, etc.) live in nixos/common.nix.
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
    pkgs.unstable.awww # From nixpkgs-unstable
    pkgs.solaar
    inputs.pomodoro.packages.${pkgs.system}.default
  ]
  ++ (with pkgs.unstable; [
    # ── Development ────────────────────────────────────────────────────
    kotlin
    openjdk25
    code2prompt
    nodejs
    dotnet-sdk_9
    roslyn

    # ── CLI utilities ───────────────────────────────────────────────────
    quickemu
    git-lfs
    github-copilot-cli
    opencode
    wl-clipboard
    pkgs.age
    inputs.agenix.packages.${pkgs.system}.default
    fd
    ripgrep
    ripgrep-all
    grc
    eza
    dust
    duf
    procs
    zoxide
    tlrc
    hyperfine
    sd
    choose
    just
    watchexec
    xh
    android-tools
    pet
    jq
    nix-tree
    nix-output-monitor
    deadnix
    statix
    texliveBasic
    imagemagick
    zip
    btop
    microfetch
    gh-dash

    # ── Fonts ───────────────────────────────────────────────────────────
    nerd-fonts.fira-code
    nerd-fonts.zed-mono
    nerd-fonts.jetbrains-mono
    alice

    # ── GUI applications ────────────────────────────────────────────────
    foot
    onlyoffice-desktopeditors
    vesktop
    qownnotes
    neovide

    # ── Document viewers ────────────────────────────────────────────────
    sioyek

    # ── Media ───────────────────────────────────────────────────────────
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
      pkgs.ddcutil
      blender
      via
      prismlauncher
      google-chrome
      calibre
    ]
  )
  # ── Laptop-only packages ──────────────────────────────────────────────
  ++ lib.optionals hostProfile.isLaptop (
    with pkgs.unstable;
    [
      powertop
      acpi
      brightnessctl
    ]
  );
}
