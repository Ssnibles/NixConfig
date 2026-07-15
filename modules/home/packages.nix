{
  pkgs,
  lib,
  hostProfile,
  inputs,
  ...
}:
let
  unstable = pkgs.unstable;

  # Helper for flake packages — just add the input to flake.nix and reference it here.
  flakePkg = name: inputs.${name}.packages.${pkgs.stdenv.hostPlatform.system}.default;

  development = [
    unstable.kotlin
    unstable.openjdk25
    unstable.code2prompt
    unstable.nodejs
    unstable.dotnet-sdk_9
    unstable.roslyn
    unstable.gnumake
  ];

  cli = [
    unstable.git-lfs
    unstable.github-copilot-cli
    unstable.opencode
    unstable.wl-clipboard
    unstable.sshfs
    unstable.sshpass
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
    pkgs.age
    (flakePkg "agenix")
  ];

  fonts = [
    unstable.nerd-fonts.fira-code
    unstable.nerd-fonts.zed-mono
    unstable.nerd-fonts.jetbrains-mono
    unstable.texlivePackages.opensans
    unstable.alice
    pkgs.instrument-serif
  ];

  gui = [
    unstable.foot
    unstable.onlyoffice-desktopeditors
    unstable.vesktop
    unstable.neovide
    unstable.android-studio
    (flakePkg "helium-browser")
  ];

  media = [
    unstable.mpv
    unstable.imv
    unstable.pavucontrol
  ];

  connectivity = [
    unstable.localsend
    unstable.impala
    unstable.bluetui
    unstable.blueman
    unstable.satty
    unstable.grimblast
  ];

  perHost =
    lib.optionals hostProfile.isDesktop [
      pkgs.ddcutil
      unstable.blender
      unstable.via
      unstable.prismlauncher
      unstable.calibre
    ]
    ++ lib.optionals hostProfile.isLaptop [
      unstable.powertop
      unstable.acpi
      unstable.brightnessctl
    ];

in
{
  home.packages = [
    (flakePkg "pomodoro")
    unstable.awww
    (flakePkg "solaar")
  ]
  ++ development
  ++ cli
  ++ fonts
  ++ gui
  ++ media
  ++ connectivity
  ++ perHost;
}
