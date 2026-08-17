{ ... }:
{
  nixos.modules.laptop =
    {
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        ./_hardware-generated.nix
      ]
      ++ lib.optional (builtins.pathExists ./_installer-options.nix) ./_installer-options.nix;

      # Mount /boot on-demand via fstab to prevent systemd-gpt-auto-generator from
      # creating its own boot.mount, which deadlocks dbus-broker during early boot
      # (dbus-broker's ProtectSystem=full namespace setup triggers the automount,
      #  blocking it while PID 1 waits for dbus's READY notification — ~8.8s stall)
      fileSystems."/boot" = {
        fsType = "vfat";
        options = lib.mkForce [
          "noauto"
          "x-systemd.automount"
          "x-systemd.idle-timeout=120"
          "fmask=0177"
          "dmask=0077"
          "nodev"
          "nosuid"
          "noexec"
        ];
      };

      # Laptop-specific kernel adjustments (HP EliteBook 865 G9 AMDGPU)
      boot.kernelParams = [
        "amdgpu.dcdebugmask=0x40000"
      ];

      # Load critical drivers early in initrd:
      # - tpm_crb: TPM ready before userspace
      # - nvme: root disk available immediately (instead of on-demand probe)
      # - amdgpu: GPU initialized during initrd so Plymouth uses real framebuffer
      #   and userspace doesn't wait for late GPU init (~15s → immediate)
      boot.initrd.kernelModules = [ "tpm_crb" "nvme" "amdgpu" ];

      boot.extraModprobeConfig = ''
        options rtw89_pci disable_aspm_l1=y disable_aspm_l1ss=y
        options rtw89_core disable_ps_mode=y
      '';

      networking.networkmanager = {
        wifi = {
          scanRandMacAddress = false; # avoid scan-triggered disconnects on rtw89
          powersave = false;
        };
        dispatcherScripts = [
          {
            source = pkgs.writeShellScript "wifi-powersave-off" ''
              if [ "$2" = "up" ] && ${pkgs.iw}/bin/iw dev "$1" info >/dev/null 2>&1; then
                ${pkgs.iw}/bin/iw dev "$1" set power_save off
              fi
            '';
            type = "basic";
          }
        ];
      };

      # rtw89-specific quirks for the laptop's Realtek Wi-Fi.
      networking.wireless.iwd.settings = {
        General.DisableANQP = true; # firmware stumbles on ANQP queries
        DriverQuirks.PowerSaveDisable = "rtw89*"; # disable Wi-Fi power save
      };

      services.tlp = {
        enable = true;
        settings = {
          CPU_BOOST_ON_AC = 1;
          CPU_BOOST_ON_BAT = 0;
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
          WIFI_PWR_ON_AC = "off";
          WIFI_PWR_ON_BAT = "off";
          USB_AUTOSUSPEND = 1;
          AHCI_RUNTIME_PM_ON_BAT = "auto";
          RUNTIME_PM_ON_BAT = "auto";
          RUNTIME_PM_ON_AC = "auto";
          PCIE_ASPM_ON_AC = "performance";
          PCIE_ASPM_ON_BAT = "powersave";
        };
      };

      environment.systemPackages = with pkgs.unstable; [
        dfu-util
        gowall
        openocd
      ];

      services.udev.packages = [ pkgs.openocd ];
      users.extraGroups.plugdev = {};

      # Define udev rules for DFU devices
      services.udev.extraRules = ''
        # Generic DFU rule (for meshtastic thingy)
        SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666", GROUP="dialout"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="303a", ATTRS{idProduct}=="1001", MODE="0666", GROUP="dialout"
        ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0666", GROUP="plugdev"
        ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6014", MODE="0666", GROUP="plugdev"
      '';

      system.stateVersion = "25.05";
    };
}
