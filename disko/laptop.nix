# =============================================================================
# Disko Configuration – Laptop
# =============================================================================
# Partition layout for the laptop host.
# Includes a dedicated swap partition to support hibernation.
# =============================================================================
{
  args ? { },
  ...
}:
let
  device = args.diskDevice or "/dev/INVALID_SET_--argstr_diskDevice";
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
        swap = {
          priority = 2;
          name = "swap";
          start = "512M";
          end = "8512M";
          content = {
            type = "swap";
            resumeDevice = true;
          };
        };
        root = {
          priority = 3;
          name = "root";
          start = "8512M";
          end = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
