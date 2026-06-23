{ pkgs, lib, inputs, hostProfile, ... }:

let
  solaar = inputs.solaar.packages.${pkgs.stdenv.hostPlatform.system}.default;
in

{
  hardware.i2c.enable = lib.mkDefault hostProfile.isDesktop;
  services.udev.packages = (lib.optionals hostProfile.isDesktop [ pkgs.ddcutil ]) ++ [ solaar ];
}
