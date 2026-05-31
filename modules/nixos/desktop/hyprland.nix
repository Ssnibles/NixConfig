{ ... }:

{
  programs.hyprland.enable = true;

  environment.etc."xdg-desktop-portal/Hyprland-portals.conf".text = ''
    [preferred]
    default=hyprland;gtk

    [org.freedesktop.impl.portal.ScreenCast]
    default=hyprland

    [org.freedesktop.impl.portal.Screenshot]
    default=hyprland

    [org.freedesktop.impl.portal.FileChooser]
    default=gtk
  '';
}
