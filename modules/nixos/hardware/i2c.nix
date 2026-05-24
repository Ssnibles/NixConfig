{ pkgs, lib, hostProfile, ... }:

{
  hardware.i2c.enable = lib.mkDefault hostProfile.isDesktop;
  services.udev.packages = (lib.optionals hostProfile.isDesktop [ pkgs.ddcutil ]) ++ [ pkgs.solaar ];
}
