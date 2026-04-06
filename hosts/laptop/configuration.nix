# =============================================================================
# Laptop Host Configuration
# =============================================================================
# AMD CPU laptop with integrated graphics and TLP power management.
# Contains only laptop-specific overrides; shared config lives in
# modules/nixos/common.nix.
#
# useDisko = true  → Disko manages partitioning (hardware-configuration.nix skipped)
# useDisko = false → hardware-configuration.nix provides filesystem definitions
# =============================================================================
{
  lib,
  hostProfile,
  ...
}:
{
  imports = lib.optionals (!hostProfile.useDisko) [ ./hardware-configuration.nix ] ++ [
    ../../modules/nixos/common.nix
    # No nvidia.nix – laptop uses integrated AMD graphics
  ];

  # ── Boot ─────────────────────────────────────────────────────────────────
  # Kernel modules duplicated from hardware-configuration.nix so they are
  # always present even when Disko is used (skipping that file).
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "sdhci_pci" # SD card reader
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # Intel WiFi regulatory domain and Bluetooth coexistence
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=NZ
    options iwlwifi power_save=0 bt_coex_active=0 11n_disable=8 swcrypto=1;
  '';

  # ── Power management – TLP ────────────────────────────────────────────────
  # Overrides common.nix which disables power-profiles-daemon.
  services.tlp = {
    enable = true;
    settings = {
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      # Charge thresholds extend battery lifespan
      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 85;
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "off";
      USB_AUTOSUSPEND = 1;
      AHCI_RUNTIME_PM_ON_BAT = "auto";
      RUNTIME_PM_ON_BAT = "auto";
      LAPTOP_MODE = 5;
    };
  };

  # ── Lid switch behaviour ─────────────────────────────────────────────────
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
    IgnoreInhibited = "yes";
  };

  # ── UDEV rules ───────────────────────────────────────────────────────────
  # Lower NVMe read-ahead on battery for power savings
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="block", KERNEL=="nvme*", ATTR{queue/read_ahead_kb}="1024"
  '';
}
