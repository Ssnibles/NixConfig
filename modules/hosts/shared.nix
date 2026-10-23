# Shared host settings.
# Bootloader, graphics, login manager, keyboard remaps, swap, and systemd tuning.
{ ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      nixpkgs.hostPlatform = "x86_64-linux";

      boot.loader.limine.enable = true;
      boot.loader.limine.maxGenerations = 10;
      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.timeout = 5;

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      hardware.keyboard.qmk.enable = true;

      boot.kernelPackages = pkgs.unstable.linuxPackages_latest;

      boot.initrd.systemd.enable = true;
      boot.initrd.compressor = "zstd";
      boot.initrd.compressorArgs = [ "-1" ];

      boot.consoleLogLevel = 0;
      boot.initrd.verbose = false;
      boot.kernelParams = [
        "mitigations=off"
        "8250.nr_uarts=0"
        "nowatchdog"
        "quiet"
        "loglevel=3"
        "rd.systemd.show_status=false"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
      ];
      boot.kernel.sysctl = {
        "vm.swappiness" = 10;
        "vm.vfs_cache_pressure" = 50;
        # Games/Proton, some JVM and Android tooling.
        "vm.max_map_count" = 2147483642;
        # File-watcher headroom for LSPs, cargo-watch, vite and syncthing.
        "fs.inotify.max_user_watches" = 524288;
        "fs.inotify.max_user_instances" = 1024;
      };

      # Force Chromium and Electron applications to use Wayland natively.
      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
      };

      services.journald.settings.Journal = {
        SystemMaxUse = "50M";
        SystemMaxFileSize = "10M";
        RateLimitIntervalSec = "30s";
        RateLimitBurst = 1000;
      };

      services.upower.enable = true;

      services.displayManager.ly.enable = true;
      security.pam.services.ly.enableGnomeKeyring = true;
      services.gnome.gnome-keyring.enable = true;

      # Show asterisks while typing a sudo password.
      security.sudo.extraConfig = "Defaults pwfeedback";
      security.apparmor.enable = true;

      # Swap Caps Lock and Escape at kernel level.
      services.udev.extraHwdb = ''
        evdev:atkbd:dmi:bvn*:bvr*:bd*:svn*:pn*:pvr*
         KEYBOARD_KEY_3a=esc
         KEYBOARD_KEY_01=capslock
        evdev:input:b*v*
         KEYBOARD_KEY_70039=esc
         KEYBOARD_KEY_70029=capslock
      '';

      networking.hostName = "nixos";

      fileSystems."/" = {
        options = [ "noatime" ];
      };

      # In-memory compressed swap avoids SSD wear and NVMe wakeups.
      zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = 50;
        priority = 100;
      };

      # Systemd boot and service tuning.
      systemd.services.NetworkManager-wait-online.enable = false;

      # Limine is used, so the systemd-boot random seed service is not needed.
      systemd.services.systemd-boot-random-seed.enable = false;

      # Keep GUI applications alive across nixos-rebuild.
      systemd.services.dbus-broker.restartIfChanged = false;
      systemd.user.services.dbus-broker.restartIfChanged = false;
      systemd.services.dbus.restartIfChanged = false;
      systemd.user.services.dbus.restartIfChanged = false;

      systemd.services.dbus-broker.restartTriggers = lib.mkForce [ ];
      systemd.user.services.dbus-broker.restartTriggers = lib.mkForce [ ];
      systemd.services.dbus.restartTriggers = lib.mkForce [ ];
      systemd.user.services.dbus.restartTriggers = lib.mkForce [ ];

      # NixOS lists each D-Bus service twice, which makes dbus-broker log a
      # duplicate name warning about 50 times per login. Filter it on the system
      # bus with LogFilterPatterns and on the user bus by cleaning stderr.
      systemd.services.dbus.serviceConfig.LogFilterPatterns = [ "~Ignoring.*" ];
      systemd.services.dbus-broker.serviceConfig.LogFilterPatterns = [ "~Ignoring.*" ];
      systemd.user.services.dbus-broker.serviceConfig.ExecStart =
        lib.mkIf (config.services.dbus.implementation == "broker")
          (
            lib.mkForce [
              # An empty first element replaces the packaged ExecStart instead
              # of adding a second launcher.
              ""
              "${pkgs.bash}/bin/bash -c 'exec ${config.services.dbus.brokerPackage}/bin/dbus-broker-launch --scope user 2> >(${pkgs.gnugrep}/bin/grep --line-buffered -v \"Ignoring duplicate name\" >&2)'"
            ]
          );
      systemd.services.display-manager.serviceConfig.LogFilterPatterns = [
        "~gkr-pam: unable to locate daemon control file"
      ];
    };
}
