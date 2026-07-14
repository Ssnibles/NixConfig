{ pkgs, ... }:

{
  security.pam.services.quickshell = {
    enable = true;
    gnupg.enable = false;
    enableGnomeKeyring = true;
  };
}
