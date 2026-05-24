{ pkgs, lib, ... }:

{
  programs.hyprland.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = lib.mkForce [
      pkgs.unstable.xdg-desktop-portal-hyprland
      pkgs.unstable.xdg-desktop-portal-gtk
    ];
  };

  environment.etc."xdg/xdg-desktop-portal/portals.conf".text = ''
    [preferred]
    default=hyprland;gtk

    [org.freedesktop.impl.portal.ScreenCast]
    default=hyprland

    [org.freedesktop.impl.portal.Screenshot]
    default=hyprland

    [org.freedesktop.impl.portal.FileChooser]
    default=gtk
  '';

  environment.etc."xdg-desktop-portal/portals.conf".text = ''
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
