{ lib, ... }:

let
  modules = [
    ./core/boot.nix
    ./core/locale.nix
    ./core/networking.nix
    ./core/nix.nix
    ./core/power.nix

    ./hardware/bluetooth.nix
    ./hardware/i2c.nix

    ./services/audio.nix
    ./services/printing.nix
    ./services/system.nix
    ./services/virtualisation.nix

    ./desktop/display-manager.nix
    ./desktop/stylix.nix
    ./desktop/niri.nix

    ./users.nix
    ./packages.nix
  ];
in
{
  imports = modules;
}
