{
  pkgs,
  lib,
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
    "vm.swappiness" = 180;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.page-cluster" = 0;
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 3;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_expire_centisecs" = 1500;
    "vm.dirty_writeback_centisecs" = 300;
    "vm.compaction_proactiveness" = 0;
    "vm.stat_interval" = 10;
    "kernel.nmi_watchdog" = 0;
    "kernel.split_lock_mitigate" = 0;
    "kernel.sched_autogroup_enabled" = 1;
    "kernel.sched_min_granularity_ns" = 10000000;
    "kernel.sched_wakeup_granularity_ns" = 1500000;
    "kernel.sched_migration_cost_ns" = 5000000;
    "net.core.netdev_max_backlog" = 16384;
    "net.core.somaxconn" = 8192;
    "net.ipv4.tcp_fastopen" = 3;
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  hardware.enableRedistributableFirmware = true;
}
