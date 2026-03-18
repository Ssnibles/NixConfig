# =============================================================================
# Disko Configuration - Desktop
# =============================================================================
# Defines the partition layout for the desktop host.
# This file is only activated when hostProfile.useDisko = true.
#
# WARNING: Running disko --mode disko will wipe the target disk.
# Only run during initial installation or when reformatting is intended.
# =============================================================================
{
  lib,
  args ? { },
  ...
}:
let
  # Device path can be overridden via CLI: --argstr diskDevice /dev/nvme0n1
  device = args.diskDevice or "/dev/nvme1n1";
in
{
  disko.devices = {
    disk = {
      main = {
        inherit device;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            # EFI System Partition
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0077"
                  "dmask=0077"
                ];
              };
            };
            # Root Partition
            root = {
              priority = 2;
              name = "root";
              start = "512M";
              end = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                extraArgs = [
                  "-L"
                  "nixos-root"
                ];
              };
            };
          };
        };
      };
    };
  };
}
