{ ... }:
{
  nixos.modules.shared =
    { pkgs, lib, ... }:
    {
      # Bootloader
      boot.loader.limine.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      # Use latest kernel.
      boot.kernelPackages = pkgs.linuxPackages_latest;

      boot.initrd.systemd.enable = true;
      boot.initrd.compressor = "zstd";
      boot.initrd.compressorArgs = [ "-1" ];

      boot.kernelParams = [
        "mitigations=off"
        "8250.nr_uarts=0"
        "noatime"
      ];
      boot.kernel.sysctl = {
        "vm.swappiness" = 10;
        "vm.vfs_cache_pressure" = 200;
      };

      # Limit journal size to 100M
      services.journald.extraConfig = ''
        SystemMaxUse=100M
      '';

      services.upower.enable = true;

      # Enable ly for login management
      services.displayManager.ly.enable = true;
      security.pam.services.ly.enableGnomeKeyring = true;
      services.gnome.gnome-keyring.enable = true;

      # Swap Caps Lock and Escape via udev hwdb (kernel-level, no daemon needed)
      services.udev.extraHwdb = ''
        evdev:atkbd:dmi:bvn*:bvr*:bd*:svn*:pn*:pvr*
         KEYBOARD_KEY_3a=esc
         KEYBOARD_KEY_01=capslock
        evdev:input:b*v*
         KEYBOARD_KEY_70039=esc
         KEYBOARD_KEY_70029=capslock
      '';

      networking.hostName = "nixos";

      # Reduce writes with noatime
      fileSystems."/" = {
        options = [ "noatime" ];
      };

      swapDevices = [
        {
          device = "/swapfile";
          size = 8192;
        }
      ];

      # Don't block boot on network online
      systemd.services.NetworkManager-wait-online.enable = false;

      # Don't let random-seed refresh block sysinit.target — run it async
      systemd.services.systemd-boot-random-seed = {
        unitConfig.Before = lib.mkForce [ ];
      };

      # Prevent dbus/dbus-broker from restarting during rebuilds and killing GUI apps
      systemd.services.dbus-broker.restartIfChanged = false;
      systemd.user.services.dbus-broker.restartIfChanged = false;
      systemd.services.dbus.restartIfChanged = false;
      systemd.user.services.dbus.restartIfChanged = false;

      systemd.services.dbus-broker.restartTriggers = lib.mkForce [ ];
      systemd.user.services.dbus-broker.restartTriggers = lib.mkForce [ ];
      systemd.services.dbus.restartTriggers = lib.mkForce [ ];
      systemd.user.services.dbus.restartTriggers = lib.mkForce [ ];
    };
}
