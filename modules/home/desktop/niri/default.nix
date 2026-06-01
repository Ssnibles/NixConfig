{
  pkgs,
  lib,
  config,
  hostProfile,
  ...
}:
let
  repoRoot = "${config.home.homeDirectory}/NixConfig";
  niriDir = "${repoRoot}/modules/home/desktop/niri";
  qsDir = "${repoRoot}/modules/home/desktop/quickshell";

  lockCmd = "${pkgs.unstable.swaylock}/bin/swaylock -f";
  niriWake = "${pkgs.niri}/bin/niri msg action wake-monitors";
  niriPowerOff = "${pkgs.niri}/bin/niri msg action power-off-monitors";
in
{
  imports = [
    ../../services/wayland.nix
    ../swaylock.nix
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
    source = config.lib.file.mkOutOfStoreSymlink "${niriDir}/config.kdl";
    force = true;
  };

  xdg.configFile."quickshell/niri/shell.qml".source =
    config.lib.file.mkOutOfStoreSymlink "${niriDir}/quickshell/shell.qml";
  xdg.configFile."quickshell/niri/bar.qml".source =
    config.lib.file.mkOutOfStoreSymlink "${niriDir}/quickshell/bar.qml";
  xdg.configFile."quickshell/niri/Colors.qml".source =
    config.lib.file.mkOutOfStoreSymlink "${qsDir}/Colors.qml";
  xdg.configFile."quickshell/niri/Pill.qml".source =
    config.lib.file.mkOutOfStoreSymlink "${qsDir}/Pill.qml";
  xdg.configFile."quickshell/niri/notifications.qml".source =
    config.lib.file.mkOutOfStoreSymlink "${qsDir}/notifications.qml";
  xdg.configFile."quickshell/niri/CommandCenter.qml".source =
    config.lib.file.mkOutOfStoreSymlink "${qsDir}/CommandCenter.qml";
  xdg.configFile."quickshell/niri/AppIcon.qml".source =
    config.lib.file.mkOutOfStoreSymlink "${qsDir}/AppIcon.qml";
  xdg.configFile."quickshell/niri/ActionRow.qml".source =
    config.lib.file.mkOutOfStoreSymlink "${qsDir}/ActionRow.qml";
  xdg.configFile."quickshell/niri/SliderControl.qml".source =
    config.lib.file.mkOutOfStoreSymlink "${qsDir}/SliderControl.qml";

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
