# =============================================================================
# Desktop Host Configuration
# =============================================================================
# AMD CPU + NVIDIA GPU desktop.  Contains only desktop-specific overrides;
# everything shared with the laptop lives in modules/nixos/common.nix.
#
# useDisko = true  → Disko manages partitioning (hardware-configuration.nix skipped)
# useDisko = false → hardware-configuration.nix provides filesystem definitions
# =============================================================================
{
  pkgs,
  lib,
  hostProfile,
  ...
}:
{
  imports =
    lib.optionals (!hostProfile.useDisko) [ ./hardware-configuration.nix ]
    ++ [
      ../../modules/nixos/common.nix
      ../../modules/nixos/hardware/nvidia.nix
    ];

  # ── Boot ─────────────────────────────────────────────────────────────────
  # Kernel modules duplicated from hardware-configuration.nix so they are
  # always present even when Disko is used (skipping that file).
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # Prevent USB autosuspend – fixes keyboard / mouse wake-up issues
  boot.kernelParams = [ "usbcore.autosuspend=-1" ];

  # ── Power management ─────────────────────────────────────────────────────
  # Desktop stays on performance governor; no TLP needed.
  powerManagement.cpuFreqGovernor = "performance";

  # ── UDEV rules ───────────────────────────────────────────────────────────
  services.udev.extraRules = ''
    # Keep USB HID devices powered on
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{bInterfaceClass}=="03", ATTR{power/control}="on"
    # Keep NVIDIA GPU powered on
    ACTION=="add", SUBSYSTEM=="pci", DRIVER=="nvidia", ATTR{power/control}="on"
    # Higher NVMe read-ahead for desktop performance
    ACTION=="add", SUBSYSTEM=="block", KERNEL=="nvme*", ATTR{queue/read_ahead_kb}="2048"
  '';

  # ── Desktop-specific services ─────────────────────────────────────────────
  # Ollama local AI inference (desktop has enough RAM/VRAM)
  services.ollama.enable = true;

  # ── Desktop-specific system packages ─────────────────────────────────────
  # gamemode daemon must be system-wide for the setuid wrapper to work;
  # user-facing tools (steam, heroic, etc.) are in modules/home/packages.nix.
  environment.systemPackages = with pkgs; [
    gamemode
  ];
}
