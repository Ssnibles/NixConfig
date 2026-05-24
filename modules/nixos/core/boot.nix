{ pkgs, lib, hostProfile, ... }:

{
  system.stateVersion = "24.05";

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
      consoleMode = "max";
    };
    efi.canTouchEfiVariables = true;
    timeout = 1;
  };

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  boot.kernelModules = [ "uinput" ];
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=NZ
  '';

  hardware.enableRedistributableFirmware = true;
}
