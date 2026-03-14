{ lib, hostProfile, ... }:

# ===========================================================================
# HOST PROFILE — exposes laptop/desktop/GPU/VM flags as NixOS options.
#
# The actual detection runs once in flake.nix and is passed in via
# specialArgs as `hostProfile`. This module simply declares the options
# (so other modules can reference config.hostProfile.*) and sets their
# defaults to the pre-computed values from the flake.
#
# Any value can be manually overridden in configuration.nix:
#   hostProfile.isLaptop  = true;
#   hostProfile.hasNvidia = false;
#   hostProfile.isVM      = false;
# ===========================================================================

{
  options.hostProfile = {

    isLaptop = lib.mkOption {
      type = lib.types.bool;
      default = hostProfile.isLaptop;
      description = ''
        True when a battery is detected under /sys/class/power_supply/.
        Override in configuration.nix if auto-detection is wrong for your
        hardware (e.g. a desktop with a UPS that exposes a BAT* node).
      '';
    };

    isDesktop = lib.mkOption {
      type = lib.types.bool;
      default = hostProfile.isDesktop;
      description = ''
        Inverse of isLaptop. Derived automatically from the battery check.
        Override if auto-detection produces the wrong result.
      '';
    };

    hasNvidia = lib.mkOption {
      type = lib.types.bool;
      default = hostProfile.hasNvidia;
      description = ''
        True when an Nvidia PCI device (vendor 0x10de) is detected.
        Override in configuration.nix if auto-detection is wrong.
      '';
    };

    isVM = lib.mkOption {
      type = lib.types.bool;
      default = hostProfile.isVM;
      description = ''
        True when no PCI bus is detected under /sys/bus/pci/devices.
        This is the case for most VMs and containers. Modules can use this
        flag to skip hardware-specific tuning that is meaningless or harmful
        in a virtualised environment (e.g. CPU governor, TLP, powertop).
        Override in configuration.nix if detection is incorrect.
      '';
    };

  };
}

