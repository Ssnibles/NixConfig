# =============================================================================
# Desktop Hardware Configuration
# =============================================================================
{ config, lib, modulesPath, hostProfile, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # ── Boot ─────────────────────────────────────────────────────────────────
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" ];
  boot.kernelModules = [ "kvm-amd" ];

  # ── Filesystems (Legacy/Test) ───────────────────────────────────────────
  # Only used when Disko is disabled (e.g., desktop-test host)
  fileSystems."/" = lib.mkIf (!hostProfile.useDisko) {
    device = "/dev/disk/by-uuid/fd2c75a0-9ce7-4285-8f44-18c4d933c448";
    fsType = "ext4";
  };

  fileSystems."/boot" = lib.mkIf (!hostProfile.useDisko) {
    device = "/dev/disk/by-uuid/C36C-EBE0";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # ── CPU ─────────────────────────────────────────────────────────────────
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
