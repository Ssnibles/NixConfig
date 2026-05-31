{ ... }:

{
  programs.niri.enable = true;

  environment.etc."xdg-desktop-portal/niri-portals.conf".text = ''
    [preferred]
    default=gtk

    [org.freedesktop.impl.portal.FileChooser]
    default=gtk
  '';
}
