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
let
  heliumPackage =
    if hostProfile.hasNvidia then
      pkgs.symlinkJoin {
        name = "helium-stable";
        paths = [ pkgs.helium ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          rm -f "$out/bin/helium"
          # Chromium/Wayland + NVIDIA can become severely janky over time.
          # Launch Helium through XWayland on NVIDIA hosts for stable input/rendering.
          makeWrapper ${pkgs.helium}/bin/helium "$out/bin/helium" \
            --add-flags "--ozone-platform=x11"
        '';
      }
    else
      pkgs.helium;
in
{
  home.packages = [
    heliumPackage # From flake overlay (NVIDIA hosts use an XWayland wrapper)
    pkgs.unstable.awww # From nixpkgs-unstable
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
    github-copilot-cli
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
    matugen
    zip

    # ── Fonts ───────────────────────────────────────────────────────────
    nerd-fonts.fira-code
    nerd-fonts.zed-mono
    nerd-fonts.jetbrains-mono

    # ── GUI applications ────────────────────────────────────────────────
    foot
    mission-center
    kdePackages.dolphin
    gnome-pomodoro
    via
    onlyoffice-desktopeditors
    prismlauncher

    # ── Document viewers ────────────────────────────────────────────────
    sioyek

    # ── Notes ───────────────────────────────────────────────────────────
    trilium-desktop

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
      steam
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
