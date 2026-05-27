{ pkgs, lib, ... }:

{
  programs.niri.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  environment.etc."xdg-desktop-portal/niri-portals.conf".text = ''
    [preferred]
    default=gtk

    [org.freedesktop.impl.portal.FileChooser]
    default=gtk
  '';
}
