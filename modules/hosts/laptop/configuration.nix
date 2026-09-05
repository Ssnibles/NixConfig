# =============================================================================
# Laptop Host Specific Configuration
# =============================================================================
# Hardware definitions, TLP battery power optimization profiles, i2c_hid ACPI
# touchpad polling workarounds, ath11k Wi-Fi kernel modules, and DFU udev rules.
# =============================================================================
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

      # Standard mount options for /boot (no automount to avoid dbus-broker ProtectSystem=full deadlocks)
      fileSystems."/boot" = {
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
          "nodev"
          "nosuid"
          "noexec"
        ];
      };

      # NVMe is in availableKernelModules; TPM modules removed from initrd as root is unencrypted
      boot.initrd.kernelModules = [ ];

      # Pre-load Wi-Fi driver & firmware early
      boot.kernelModules = [
        "ath11k_pci"
      ];

      # Set max PWM brightness for HP elitebook (0x40000), disable PSR (0x10) & Panel Replay (0x400) to fix external monitor flicker/resets, & fix ELAN touchpad spam
      boot.kernelParams = [
        "amdgpu.dcdebugmask=0x40410"
        "i2c_hid.polling_mode=1"
        "i2c_hid_acpi.polling_mode=1"
      ];

      # ── TLP Power Management Profiles ─────────────────────────────────────
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

      # Hardware tools & microcontrollers (OpenOCD, DFU utilities)
      environment.systemPackages = with pkgs.unstable; [
        dfu-util
        gowall
        openocd
      ];

      services.udev.packages = [ pkgs.openocd ];

      # Define udev rules for DFU devices & Meshtastic hardware
      services.udev.extraRules = ''
        SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666", GROUP="dialout"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="303a", ATTRS{idProduct}=="1001", MODE="0666", GROUP="dialout"
        ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0666", GROUP="plugdev"
        ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6014", MODE="0666", GROUP="plugdev"
      '';

      # ── Desktop Environment Features ───────────────────────────────────────
      features.dwl.enable = true;
      features.hyprland.enable = false;
      features.mangowc.enable = true;
      features.niri.enable = false;

      system.stateVersion = "25.05";
    };
}
