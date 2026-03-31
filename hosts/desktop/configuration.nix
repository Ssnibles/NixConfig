# =============================================================================
# Desktop Host Configuration
# =============================================================================
# Production desktop with NVIDIA GPU.
# This file contains ONLY desktop-specific overrides.
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
  stablePkgs,
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
      # NVIDIA drivers (only for desktop)
      ../../modules/nvidia.nix
    ];

  # ── Boot Kernel Modules ──────────────────────────────────────────────────
  # Hardware-specific modules from generated hardware-configuration.nix.
  # Safe to keep even when using Disko.
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # ── Boot Kernel Parameters ───────────────────────────────────────────────
  # Prevent USB autosuspend (fixes keyboard/mouse sleep issues)
  boot.kernelParams = [ "usbcore.autosuspend=-1" ];

  # ── Power Management ─────────────────────────────────────────────────────
  # Override common.nix: Desktop uses performance governor (no TLP needed)
  powerManagement.cpuFreqGovernor = "performance";

  # ── UDEV Rules ───────────────────────────────────────────────────────────
  # Hardware-specific power and performance rules
  services.udev.extraRules = ''
    # Keep USB devices powered on
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{bInterfaceClass}=="03", ATTR{power/control}="on"
    # Keep NVIDIA GPU powered on
    ACTION=="add", SUBSYSTEM=="pci", DRIVER=="nvidia", ATTR{power/control}="on"
    # Increase NVMe read-ahead for better performance
    ACTION=="add", SUBSYSTEM=="block", KERNEL=="nvme*", ATTR{queue/read_ahead_kb}="2048"
  '';

  # ── Desktop-Specific Services ────────────────────────────────────────────
  # Ollama for local AI (desktop has more RAM/VRAM)
  services.ollama.enable = true;

  # ── Desktop-Specific Packages ────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Gaming and emulation tools (desktop only)
    gamemode
    # Add other desktop-only packages here
  ];
}
