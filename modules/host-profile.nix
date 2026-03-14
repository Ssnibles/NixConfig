{ config, lib, ... }:

# ===========================================================================
# HOST PROFILE — laptop vs desktop detection
#
# Detection strategy: at evaluation time, check whether a battery device
# exists under /sys/class/power_supply/. NixOS evaluates config on the
# target machine during `nixos-rebuild`, so builtins.pathExists reflects
# the real hardware.
#
# BAT0 covers most laptops. BAT1 is a fallback for machines where the
# primary battery is enumerated as BAT1 (some Lenovos, docks, etc.).
#
# The resulting boolean is exposed as config.hostProfile.isLaptop so any
# module can branch on it without re-implementing the detection logic.
# ===========================================================================

let
  hasBat = path: builtins.pathExists "/sys/class/power_supply/${path}/capacity";
  isLaptop = hasBat "BAT0" || hasBat "BAT1";
in
{
  options.hostProfile = {
    isLaptop = lib.mkOption {
      type = lib.types.bool;
      default = isLaptop;
      description = ''
        True when a battery is detected under /sys/class/power_supply/.
        Set automatically; override with `hostProfile.isLaptop = true/false`
        in configuration.nix if auto-detection is wrong for your hardware.
      '';
    };

    isDesktop = lib.mkOption {
      type = lib.types.bool;
      default = !isLaptop;
      description = "Inverse of isLaptop. Derived automatically.";
    };
  };
}
