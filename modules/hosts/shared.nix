# =============================================================================
# Shared Host Base Configuration
# =============================================================================
# Core hardware tuning, bootloader (Limine), graphics acceleration, login manager (Ly),
# udev kernel remaps (Caps/Esc swap), swap, and systemd service optimisations.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    { pkgs, lib, config, ... }:
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

      # Force Chromium & Electron applications to run natively under Wayland
      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
      };

      # ── System Journal & Power Management ─────────────────────────────────
      features.foot.enable = false;

      services.journald.settings.Journal = {
        SystemMaxUse = "50M";
        SystemMaxFileSize = "10M";
        RateLimitIntervalSec = "30s";
        RateLimitBurst = 1000;
      };

      services.upower.enable = true;

      # ── Display Manager & Authentication ─────────────────────────────────
      services.displayManager.ly.enable = true;
      security.pam.services.ly.enableGnomeKeyring = true;
      services.gnome.gnome-keyring.enable = true;

      # ── Security Hardening ────────────────────────────────────────────────
      # Show asterisks while typing a sudo password.
      security.sudo.extraConfig = "Defaults pwfeedback";
      # Default AppArmor profile set (kernel LSM, no user-space daemon).
      security.apparmor.enable = true;

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

      # Compressed in-memory swap to avoid SSD write wear and NVMe PCIe wakeups
      zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = 50;
        priority = 100;
      };

      # ── Systemd Boot & Service Optimisations ──────────────────────────────
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

      # ── D-Bus duplicate-service-name log spam ────────────────────────────
      # NixOS' generated /etc/dbus-1/{session,system}.conf lists both
      # <standard_session_servicedirs/> (which resolves $XDG_DATA_DIRS, including
      # /run/current-system/sw/share where every package's dbus-1/services is
      # symlinked) and an explicit <servicedir> per package. dbus-broker-launch
      # therefore sees each service twice and logs
      #   "Ignoring duplicate name '…' in service file '…'"
      # (~50 lines per login). LogFilterPatterns= cannot suppress those on the
      # *user* bus -- systemd documents it as "only available in system
      # services" -- so the system bus relies on LogFilterPatterns and the user
      # bus sends the launcher's log stream through a filter. dbus-broker only
      # writes to the journal socket while stderr *is* that socket; handing it a
      # pipe makes it fall back to stderr, which grep cleans before journald
      # ever records the line.
      systemd.services.dbus.serviceConfig.LogFilterPatterns = [ "~Ignoring.*" ];
      systemd.services.dbus-broker.serviceConfig.LogFilterPatterns = [ "~Ignoring.*" ];
      systemd.user.services.dbus-broker.serviceConfig.ExecStart = lib.mkIf (
        config.services.dbus.implementation == "broker"
      ) (lib.mkForce [
        # Leading empty element resets the packaged unit's ExecStart so this
        # replaces it instead of appending a second launcher.
        ""
        "${pkgs.bash}/bin/bash -c 'exec ${config.services.dbus.brokerPackage}/bin/dbus-broker-launch --scope user 2> >(${pkgs.gnugrep}/bin/grep --line-buffered -v \"Ignoring duplicate name\" >&2)'"
      ]);
      systemd.services.display-manager.serviceConfig.LogFilterPatterns = [
        "~gkr-pam: unable to locate daemon control file"
      ];
    };
}
