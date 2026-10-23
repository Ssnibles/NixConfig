# Laptop host settings.
# Power profiles, touchpad and Wi-Fi workarounds, firmware pin, and DFU rules.
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

      nixos.hostRole = "laptop";

      # mkForce is needed because _hardware-generated.nix also sets options.
      # List options are joined, so the old fmask and dmask values conflicted.
      fileSystems."/boot" = {
        fsType = "vfat";
        options = lib.mkForce [
          "fmask=0077"
          "dmask=0077"
          "nodev"
          "nosuid"
          "noexec"
        ];
      };

      # The NVMe driver is available, and root is not encrypted, so no extra
      # initrd modules are needed.
      boot.initrd.kernelModules = [ ];

      # ath11k_pci is loaded by udev.
      boot.kernelModules = [ ];

      # nowatchdog does not stop hardware watchdogs. sp5100_tco loads and then
      # logs watchdog errors on every reboot, so block it.
      boot.blacklistedKernelModules = [ "sp5100_tco" ];

      # Set the maximum PWM brightness for the HP EliteBook and disable panel
      # self refresh and panel replay, which cause flicker on an external screen.
      boot.kernelParams = [
        "amdgpu.dcdebugmask=0x40410"
        "pcie_aspm.policy=powersupersave"
      ];

      swapDevices = [
        {
          device = "/swapfile";
          size = 8192;
        }
      ];

      # Hibernation is not enabled yet. It needs the physical offset of
      # /swapfile, which must be read on the running laptop:
      #   sudo filefrag -v /swapfile | awk 'NR==4 {print $4}'
      # Then uncomment the lines below and rebuild. Do not set resumeDevice
      # without the offset, or the machine may write an image it cannot resume.
      # boot.resumeDevice = "/dev/disk/by-uuid/b58b4a43-9a29-463d-944d-fc52976d110c";
      # boot.kernelParams = [ "resume_offset=NNNNNNN" ];

      # Keep the Bluetooth radio off at boot to save battery.
      hardware.bluetooth.powerOnBoot = false;

      # Pin linux-firmware to 20260810 to avoid the Yellow Carp DMCUB bug in 20260910.
      nixpkgs.overlays = [
        (_: prev: {
          linux-firmware = prev.linux-firmware.overrideAttrs (_: rec {
            version = "20260810";
            src = prev.fetchFromGitLab {
              owner = "kernel-firmware";
              repo = "linux-firmware";
              tag = version;
              hash = "sha256-P/fPpqaatp8Z2GV+I/OChiWGn6AhV+8w1RMFuX/LqHc=";
            };
          });
        })
      ];

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
          WIFI_PWR_ON_BAT = "off";
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
        openocd
      ];

      services.udev.packages = [ pkgs.openocd ];

      # Rules for DFU devices and Meshtastic hardware.
      services.udev.extraRules = ''
        SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666", GROUP="dialout"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="303a", ATTRS{idProduct}=="1001", MODE="0666", GROUP="dialout"
        ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0666", GROUP="plugdev"
        ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6014", MODE="0666", GROUP="plugdev"
      '';

      system.stateVersion = "26.05";
    };
}
