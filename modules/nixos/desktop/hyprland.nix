{ ... }:

{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  # Tell applications (Discord/Vesktop, browsers, etc.) to use the Hyprland
  # portal backend for screen casting. Without this, screen sharing via
  # xdg-desktop-portal won't work on Wayland.
  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
  };

}
