# =============================================================================
# Laptop Hardware Configuration
# =============================================================================
{ config, lib, modulesPath, hostProfile, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # ── Boot ─────────────────────────────────────────────────────────────────
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "sdhci_pci" ];
  boot.kernelModules = [ "kvm-amd" ];

  # ── Filesystems (Legacy/Test) ───────────────────────────────────────────
  # Only used when Disko is disabled (e.g., laptop-test host)
  fileSystems."/" = lib.mkIf (!hostProfile.useDisko) {
    device = "/dev/disk/by-uuid/55b99976-5f02-482d-bb45-6f6315f9fe3d";
    fsType = "ext4";
  };

  fileSystems."/boot" = lib.mkIf (!hostProfile.useDisko) {
    device = "/dev/disk/by-uuid/1CC7-06FE";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = lib.mkIf (!hostProfile.useDisko) [
    { device = "/dev/disk/by-uuid/a4812ab3-cb18-47a9-935d-209cce46492a"; }
  ];

  # ── CPU ─────────────────────────────────────────────────────────────────
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
