{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    glib
    glib-networking
    dconf
    vim
    htop
    rsync
    iwd
    tuxedo
  ];
}
