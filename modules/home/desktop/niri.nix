{
  pkgs,
  lib,
  config,
  hostProfile,
  ...
}:
let
  liveDir = "${config.home.homeDirectory}/NixConfig/live";

  lockCmd = "${pkgs.unstable.swaylock}/bin/swaylock -f";
  niriWake = "${pkgs.niri}/bin/niri msg action wake-monitors";
  niriPowerOff = "${pkgs.niri}/bin/niri msg action power-off-monitors";
in
{
  imports = [
    ../services/wayland.nix
    ./swaylock.nix
  ];

  home.packages = with pkgs; [
    libnotify
    networkmanagerapplet
    playerctl
    adwaita-icon-theme
    swayidle
  ];

  services.swayidle = {
    enable = true;
    package = pkgs.swayidle;
    events = [
      {
        event = "before-sleep";
        command = lockCmd;
      }
      {
        event = "after-resume";
        command = niriWake;
      }
      {
        event = "lock";
        command = lockCmd;
      }
    ];
    timeouts = [
      {
        timeout = 300;
        command = lockCmd;
      }
      {
        timeout = 600;
        command = niriPowerOff;
        resumeCommand = niriWake;
      }
    ]
    ++ lib.optionals hostProfile.isLaptop [
      {
        timeout = 1200;
        command = "${pkgs.systemd}/bin/systemctl suspend";
      }
    ];
  };

  systemd.user.services.swayidle = {
    Unit = {
      PartOf = lib.mkForce [ "niri.target" ];
      After = lib.mkForce [ "niri.target" ];
    };
    Install.WantedBy = lib.mkForce [ "niri.target" ];
  };

  xdg.configFile."niri/config.kdl" = {
    source = config.lib.file.mkOutOfStoreSymlink "${liveDir}/niri/config.kdl";
    force = true;
  };

  programs.vicinae = {
    enable = true;
    settings = {
      search_files_in_root = false;
      pixmap_cache_mb = 128;
      launcher_window = {
        opacity = 1.0;
        blur.enabled = false;
        dim_around = false;
      };
    };
  };
  xdg.configFile."vicinae/vicinae.json".force = true;
}
