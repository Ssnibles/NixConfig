{
  pkgs,
  lib,
  hostProfile,
  ...
}:

{
  system.stateVersion = "24.05";

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
      consoleMode = "max";
    };
    efi.canTouchEfiVariables = true;
    timeout = 1;
  };

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_zen;
  boot.kernelModules = [ "uinput" ];
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=NZ
  '';

  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.dirty_ratio" = 15;
    "vm.dirty_background_ratio" = 5;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_expire_centisecs" = 3000;
    "vm.dirty_writeback_centisecs" = 500;
    "kernel.nmi_watchdog" = 0;
    "kernel.split_lock_mitigate" = 0;
  };

  hardware.enableRedistributableFirmware = true;
}
