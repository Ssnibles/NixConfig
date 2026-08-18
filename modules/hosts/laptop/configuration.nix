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

      # Load critical drivers early in initrd:
      # - tpm_crb: TPM ready before userspace
      # - nvme: root disk available immediately (instead of on-demand probe)
      boot.initrd.kernelModules = [
        "tpm_crb"
        "nvme"
      ];
      # Set max PWM brightness for HP elitebook
      boot.kernelParams = [
        "amdgpu.dcdebugmask=0x40000"
      ];

      networking.networkmanager = {
        wifi = {
          scanRandMacAddress = false; # avoid scan-triggered disconnects on rtw89
        };
      };

      # rtw89-specific quirks for the laptop's Realtek Wi-Fi.
      networking.wireless.iwd.settings = {
        General.DisableANQP = true; # firmware stumbles on ANQP queries
      };

      # Automated runtime power tuning
      powerManagement.powertop.enable = true;

      services.tlp = {
        enable = true;
        settings = {
          CPU_BOOST_ON_AC = 1;
          CPU_BOOST_ON_BAT = 0;
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
          CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
          CPU_MAX_PERF_ON_BAT = 70;
          WIFI_PWR_ON_AC = "off";
          WIFI_PWR_ON_BAT = "on";
          USB_AUTOSUSPEND = 1;
          AHCI_RUNTIME_PM_ON_BAT = "auto";
          RUNTIME_PM_ON_BAT = "auto";
          RUNTIME_PM_ON_AC = "auto";
          PCIE_ASPM_ON_AC = "performance";
          PCIE_ASPM_ON_BAT = "powersupersave";
          AMDGPU_ABM_LEVEL_ON_BAT = 3;
          SOUND_POWER_SAVE_ON_BAT = 1;
          SOUND_POWER_SAVE_CONTROLLER = "Y";
        };
      };

      environment.systemPackages = with pkgs.unstable; [
        dfu-util
        gowall
        openocd
      ];

      services.udev.packages = [ pkgs.openocd ];

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
