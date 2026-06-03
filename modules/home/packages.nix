{
  pkgs,
  lib,
  hostProfile,
  inputs,
  ...
}:
let
  unstable = pkgs.unstable;
in
{
  home.packages = [
    unstable.awww
    pkgs.solaar
  ]
  ++ lib.optional (
    inputs ? pomodoro && inputs.pomodoro ? packages
  ) inputs.pomodoro.packages.${pkgs.stdenv.hostPlatform.system}.default
  ++ [
    # ── Development ────────────────────────────────────────────────────
    unstable.kotlin
    unstable.openjdk25
    unstable.code2prompt
    unstable.nodejs
    unstable.dotnet-sdk_9
    unstable.roslyn

    # ── CLI utilities ───────────────────────────────────────────────────
    unstable.quickemu
    unstable.git-lfs
    unstable.github-copilot-cli
    unstable.opencode
    unstable.wl-clipboard
    pkgs.age
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    unstable.fd
    unstable.ripgrep
    unstable.ripgrep-all
    unstable.grc
    unstable.eza
    unstable.dust
    unstable.duf
    unstable.procs
    unstable.zoxide
    unstable.tlrc
    unstable.hyperfine
    unstable.sd
    unstable.choose
    unstable.just
    unstable.watchexec
    unstable.xh
    unstable.android-tools
    unstable.pet
    unstable.jq
    unstable.nix-tree
    unstable.nix-output-monitor
    unstable.deadnix
    unstable.statix
    unstable.texliveBasic
    unstable.imagemagick
    unstable.zip
    unstable.btop
    unstable.microfetch
    unstable.gh-dash

    # ── Fonts ───────────────────────────────────────────────────────────
    unstable.nerd-fonts.fira-code
    unstable.nerd-fonts.zed-mono
    unstable.nerd-fonts.jetbrains-mono
    unstable.alice

    # ── GUI applications ────────────────────────────────────────────────
    unstable.foot
    unstable.onlyoffice-desktopeditors
    unstable.vesktop
    unstable.neovide

    # ── Document viewers ────────────────────────────────────────────────
    unstable.sioyek

    # ── Media ─────────────────────────────────────────────────────────────
    unstable.mpv
    unstable.imv
    unstable.picard
    unstable.easytag
    unstable.pavucontrol

    # ── System / connectivity ────────────────────────────────────────────
    unstable.localsend
    unstable.impala
    unstable.bluetui
    unstable.blueman
    unstable.satty
    unstable.grim
    unstable.slurp
  ]
  ++ lib.optionals hostProfile.isDesktop [
    pkgs.ddcutil
    unstable.blender
    unstable.via
    unstable.prismlauncher
    unstable.google-chrome
    unstable.calibre
  ]
  ++ lib.optionals hostProfile.isLaptop [
    unstable.powertop
    unstable.acpi
    unstable.brightnessctl
  ];
}
