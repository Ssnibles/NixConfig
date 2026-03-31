# =============================================================================
# Laptop Host Configuration
# =============================================================================
# Production laptop with TLP power management.
# This file contains ONLY laptop-specific overrides.
# All shared configuration is imported from modules/common.nix.
#
# When useDisko = true: Disko handles partitioning (hardware-configuration.nix skipped)
# When useDisko = false: hardware-configuration.nix provides filesystem definitions
# =============================================================================
{
  config,
  pkgs,
  lib,
  hostProfile,
  ...
}:
{
  # ── Module Imports ───────────────────────────────────────────────────────
  # Only import hardware-configuration.nix for test hosts (useDisko = false).
  # Production hosts use Disko for partitioning.
  imports =
    lib.optionals (!hostProfile.useDisko) [
      ./hardware-configuration.nix
    ]
    ++ [
      # Import shared configuration from common.nix
      ../../modules/common.nix
      # No NVIDIA module for laptop (uses integrated graphics)
    ];

  # ── Boot Kernel Modules ──────────────────────────────────────────────────
  # Hardware-specific modules from generated hardware-configuration.nix.
  # Safe to keep even when using Disko.
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "sdhci_pci" # SD card reader (laptop-specific)
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # ── WiFi Kernel Module Options ───────────────────────────────────────────
  # Intel WiFi region and power settings (laptop-specific)
  boot.extraModprobeConfig = ''
    # Set WiFi regulatory domain to New Zealand
    options cfg80211 ieee80211_regdom=NZ
    # Enable Bluetooth coexistence and disable power saving
    options iwlwifi bt_coex_active=1 11n_disable=0
  '';

  # ── Power Management (TLP) ───────────────────────────────────────────────
  # Override common.nix: Laptop uses TLP instead of performance governor
  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
    settings = {
      # CPU boost only on AC power
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
      # CPU scaling governors
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      # Battery charge thresholds (extend battery lifespan)
      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 85;
      # WiFi power saving
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "off";
      # USB and SATA power management
      USB_AUTOSUSPEND = 1;
      AHCI_RUNTIME_PM_ON_BAT = "auto";
      RUNTIME_PM_ON_BAT = "auto";
      # Enable laptop mode for aggressive power saving on battery
      LAPTOP_MODE = 5;
    };
  };

  # ── Lid Switch Behavior ──────────────────────────────────────────────────
  services.logind.settings = {
    Login = {
      # Suspend when lid closed on battery
      HandleLidSwitch = "suspend";
      # Ignore lid switch when on external power
      HandleLidSwitchExternalPower = "ignore";
      # Ignore lid switch when docked
      HandleLidSwitchDocked = "ignore";
      # Don't block suspend if an app inhibits it
      IgnoreInhibited = "yes";
    };
  };

  # ── UDEV Rules ───────────────────────────────────────────────────────────
  # Laptop-specific NVMe power settings (lower read-ahead for battery life)
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="block", KERNEL=="nvme*", ATTR{queue/read_ahead_kb}="1024"
  '';

  # ── Laptop-Specific Packages ─────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Power management and monitoring tools
    powertop
    acpi
    brightnessctl
    wlsunset # Blue light filter for nighttime
  ];
}
