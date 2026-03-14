{ config, lib, ... }:

# ===========================================================================
# HOST PROFILE — laptop vs desktop + GPU detection
#
# LAPTOP / DESKTOP DETECTION
# At evaluation time, check whether a battery device exists under
# /sys/class/power_supply/. NixOS evaluates config on the target machine
# during `nixos-rebuild`, so builtins.pathExists reflects real hardware.
# BAT0 covers most laptops; BAT1 is a fallback for some Lenovos/docks.
#
# NVIDIA DETECTION
# Check for an Nvidia PCI device by scanning /sys/bus/pci/devices/ for any
# entry whose `vendor` file contains Nvidia's PCI vendor ID (0x10de).
# This is available early in boot and doesn't require any userspace tools.
#
# All detected values are exposed as options so any module can branch on
# them, and any value can be manually overridden in configuration.nix if
# auto-detection gets it wrong for unusual hardware.
# ===========================================================================

let
  # ---------------------------------------------------------------------------
  # Battery detection
  # ---------------------------------------------------------------------------
  hasBat = name: builtins.pathExists "/sys/class/power_supply/${name}/capacity";
  detectedLaptop = hasBat "BAT0" || hasBat "BAT1";

  # ---------------------------------------------------------------------------
  # Nvidia detection
  # Reads every PCI device's vendor file and checks for 0x10de (Nvidia).
  # builtins.readDir gives us the list of device entries; we then try to
  # read each vendor file — using tryEval to safely skip unreadable entries.
  # ---------------------------------------------------------------------------
  pciBase = "/sys/bus/pci/devices";
  pciDevices =
    if builtins.pathExists pciBase
    then builtins.attrNames (builtins.readDir pciBase)
    else [ ];

  readVendor = dev:
    let result = builtins.tryEval (builtins.readFile "${pciBase}/${dev}/vendor");
    in if result.success then result.value else "";

  detectedNvidia = builtins.any
    (dev: lib.hasPrefix "0x10de" (lib.trim (readVendor dev)))
    pciDevices;
in
{
  options.hostProfile = {

    # -------------------------------------------------------------------------
    # Laptop / desktop
    # -------------------------------------------------------------------------
    isLaptop = lib.mkOption {
      type = lib.types.bool;
      default = detectedLaptop;
      description = ''
        True when a battery is detected under /sys/class/power_supply/.
        Override with `hostProfile.isLaptop = true/false` in configuration.nix
        if auto-detection is wrong for your hardware (e.g. a desktop UPS).
      '';
    };

    isDesktop = lib.mkOption {
      type = lib.types.bool;
      default = !detectedLaptop;
      description = "Inverse of isLaptop. Derived automatically.";
    };

    # -------------------------------------------------------------------------
    # GPU
    # -------------------------------------------------------------------------
    hasNvidia = lib.mkOption {
      type = lib.types.bool;
      default = detectedNvidia;
      description = ''
        True when an Nvidia PCI device (vendor 0x10de) is detected.
        Override with `hostProfile.hasNvidia = true/false` in configuration.nix
        if auto-detection is wrong.
      '';
    };
  };
}

