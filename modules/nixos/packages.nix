{ pkgs, ... }:

{
  environment.systemPackages = with pkgs.unstable; [
    git
    glib
    glib-networking
    dconf
    vim
    htop
    rsync
    nvme-cli
    smartmontools
    iwd
  ];
}
