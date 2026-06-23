{
  pkgs,
  lib,
  hostProfile,
  inputs,
  ...
}:
let
  unstable = pkgs.unstable;

  pomodoroPkg = lib.optional (
    inputs ? pomodoro && inputs.pomodoro ? packages
  ) inputs.pomodoro.packages.${pkgs.stdenv.hostPlatform.system}.default;

  development = with unstable; [
    kotlin
    openjdk25
    code2prompt
    nodejs
    dotnet-sdk_9
    roslyn
  ];

  cli = with unstable; [
    git-lfs
    github-copilot-cli
    opencode
    wl-clipboard
    sshfs
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
  ] ++ [
    pkgs.age
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  fonts = with unstable; [
    nerd-fonts.fira-code
    nerd-fonts.zed-mono
    nerd-fonts.jetbrains-mono
    texlivePackages.opensans
    alice
  ];

  gui = with unstable; [
    foot
    onlyoffice-desktopeditors
    vesktop
    neovide
  ] ++ [
    pkgs.helium-browser
  ];

  media = with unstable; [
    mpv
    imv
    pavucontrol
  ];

  connectivity = with unstable; [
    localsend
    impala
    bluetui
    blueman
    satty
    grim
    slurp
  ];

  perHost = with unstable;
    lib.optionals hostProfile.isDesktop [
      pkgs.ddcutil
      pkgs.blender
      via
      prismlauncher
      calibre
    ]
    ++ lib.optionals hostProfile.isLaptop [
      powertop
      acpi
      brightnessctl
    ];

in
{
  home.packages =
    pomodoroPkg
    ++ [ unstable.awww pkgs.solaar ]
    ++ development
    ++ cli
    ++ fonts
    ++ gui
    ++ media
    ++ connectivity
    ++ perHost;
}
