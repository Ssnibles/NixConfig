{ lib, hostProfile, ... }:

lib.mkIf hostProfile.hasPrinting {
  services.printing = {
    enable = true;
    startWhenNeeded = true;
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = false;
  };
}
