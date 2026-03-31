# =============================================================================
# Disko Configuration – Desktop
# =============================================================================
# Partition layout for the desktop host.
# Only activated when hostProfile.useDisko = true.
#
# WARNING: Running `disko --mode disko` will wipe the target disk.
# Only use during initial installation or intentional reformats.
# =============================================================================
{
  args ? { },
  ...
}:
let
  # Override via CLI: --argstr diskDevice /dev/nvme0n1
  device = args.diskDevice or "/dev/nvme1n1";
in
{
  disko.devices.disk.main = {
    inherit device;
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
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
            mountOptions = [ "fmask=0077" "dmask=0077" ];
          };
        };
        root = {
          priority = 2;
          name = "root";
          start = "512M";
          end = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            extraArgs = [ "-L" "nixos-root" ];
          };
        };
      };
    };
  };
}
