# =============================================================================
# Shared Host Base Configuration
# =============================================================================
# Core hardware tuning, bootloader (Limine), graphics acceleration, login manager (Ly),
# udev kernel remaps (Caps/Esc swap), swap, and systemd service optimizations.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    { pkgs, lib, ... }:
    {
      nixpkgs.hostPlatform = "x86_64-linux";

      # ── Bootloader & Firmware ──────────────────────────────────────────────
      boot.loader.limine.enable = true;
      boot.loader.limine.maxGenerations = 10;
      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.timeout = 5;

      # ── Hardware Graphics Acceleration (Mesa / Vulkan) ────────────────────
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      hardware.keyboard.qmk.enable = true;

      # ── Kernel & Performance Tuning ───────────────────────────────────────
      boot.kernelPackages = pkgs.linuxPackages_latest;

      boot.initrd.systemd.enable = true;
      boot.initrd.compressor = "zstd";
      boot.initrd.compressorArgs = [ "-1" ];

      boot.kernelParams = [
        "mitigations=off"
        "8250.nr_uarts=0"
        "nowatchdog"
      ];
      boot.kernel.sysctl = {
        "vm.swappiness" = 10;
        "vm.vfs_cache_pressure" = 200;
      };

      # ── System Journal & Power Management ─────────────────────────────────
      services.journald.extraConfig = ''
        SystemMaxUse=100M
      '';

      services.upower.enable = true;

      # ── Display Manager & Authentication ─────────────────────────────────
      services.displayManager.ly.enable = true;
      security.pam.services.ly.enableGnomeKeyring = true;
      services.gnome.gnome-keyring.enable = true;

      # ── Kernel-level Keyboard Mapping (Caps Lock <-> Escape Swap) ─────────
      services.udev.extraHwdb = ''
        evdev:atkbd:dmi:bvn*:bvr*:bd*:svn*:pn*:pvr*
         KEYBOARD_KEY_3a=esc
         KEYBOARD_KEY_01=capslock
        evdev:input:b*v*
         KEYBOARD_KEY_70039=esc
         KEYBOARD_KEY_70029=capslock
      '';

      # ── Networking & Filesystems ──────────────────────────────────────────
      networking.hostName = "nixos";

      fileSystems."/" = {
        options = [ "noatime" ];
      };

      swapDevices = [
        {
          device = "/swapfile";
          size = 8192;
        }
      ];

      # ── Systemd Boot & Service Optimizations ──────────────────────────────
      systemd.services.NetworkManager-wait-online.enable = false;

      # Disable systemd-boot random seed update since Limine is used (saves ~8.9s on boot)
      systemd.services.systemd-boot-random-seed.enable = false;

      # Prevent DBus restart triggers during nixos-rebuild to keep GUI apps running
      systemd.services.dbus-broker.restartIfChanged = false;
      systemd.user.services.dbus-broker.restartIfChanged = false;
      systemd.services.dbus.restartIfChanged = false;
      systemd.user.services.dbus.restartIfChanged = false;

      systemd.services.dbus-broker.restartTriggers = lib.mkForce [ ];
      systemd.user.services.dbus-broker.restartTriggers = lib.mkForce [ ];
      systemd.services.dbus.restartTriggers = lib.mkForce [ ];
      systemd.user.services.dbus.restartTriggers = lib.mkForce [ ];

      # Suppress benign log spam in systemd journal
      systemd.services.dbus.serviceConfig.LogFilterPatterns = [ "~Ignoring.*" ];
      systemd.user.services.dbus.serviceConfig.LogFilterPatterns = [ "~Ignoring.*" ];
      systemd.services.dbus-broker.serviceConfig.LogFilterPatterns = [ "~Ignoring.*" ];
      systemd.user.services.dbus-broker.serviceConfig.LogFilterPatterns = [ "~Ignoring.*" ];
      systemd.services.display-manager.serviceConfig.LogFilterPatterns = [
        "~gkr-pam: unable to locate daemon control file"
      ];
    };
}
