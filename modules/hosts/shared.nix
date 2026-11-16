# Settings shared by every host.
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
    let
      cfg = config.services.dbus;

      # NixOS lists the same D-Bus service files in session.conf and in the
      # system profile, and some packages are added twice. dbus-broker scans
      # every listed directory, so the repeats produce duplicate name warnings.
      dbusConf = pkgs.makeDBusConf.override {
        inherit (cfg) apparmor;
        dbus = cfg.dbusPackage;
        suidHelper = "${config.security.wrapperDir}/dbus-daemon-launch-helper";
        serviceDirectories = cfg.packages;
      };
    in
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

      boot.kernelPackages = pkgs.linuxPackages_latest;

      boot.initrd.compressor = "zstd";
      boot.initrd.compressorArgs = [ "-1" ];

      boot.consoleLogLevel = 0;
      boot.kernelParams = [
        "8250.nr_uarts=0"
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

      # User units ignore LogFilterPatterns, and dbus-broker writes straight
      # to the journal socket, so a stderr filter cannot work either. Remove
      # the duplicate service directories from the session config instead.
      environment.etc."dbus-1".source = lib.mkForce (
        pkgs.runCommand "dbus-1" { preferLocalBuild = true; } ''
          export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.gnused pkgs.gawk ]}

          cp -r ${dbusConf} $out
          chmod -R u+w $out

          session=$out/session.conf
          services=${config.system.path}/share/dbus-1/services

          # Put every directive on its own line so they can be filtered.
          sed -e 's#</servicedir>#</servicedir>\n#g' \
              -e 's#</includedir>#</includedir>\n#g' \
              "$session" > "$session.split"

          # Keep only the first copy of each directive.
          awk '!seen[$0]++' "$session.split" > "$session.unique"

          : > "$session.filtered"
          while IFS= read -r line; do
            case "$line" in
              *'<servicedir>'*)
                dir=$(printf '%s\n' "$line" | sed -n 's#.*<servicedir>\([^<]*\)</servicedir>.*#\1#p')
                keep=0
                for file in "$dir"/*.service; do
                  [ -e "$file" ] || continue
                  [ -e "$services/$(basename "$file")" ] || {
                    keep=1
                    break
                  }
                done
                if [ "$keep" -eq 1 ]; then
                  printf '%s\n' "$line" >> "$session.filtered"
                fi
                ;;
              *)
                printf '%s\n' "$line" >> "$session.filtered"
                ;;
            esac
          done < "$session.unique"

          mv "$session.filtered" "$session"
          rm -f "$session.split" "$session.unique"
        ''
      );

      systemd.services.dbus.serviceConfig.LogFilterPatterns = map (
        p: "~${p}"
      ) config.nixos.journalNoisePatterns;
      systemd.services.dbus-broker.serviceConfig.LogFilterPatterns = map (
        p: "~${p}"
      ) config.nixos.journalNoisePatterns;
      systemd.services.display-manager.serviceConfig.LogFilterPatterns = map (
        p: "~${p}"
      ) config.nixos.journalNoisePatterns;
    };
}
