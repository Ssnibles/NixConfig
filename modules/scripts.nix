# =============================================================================
# Custom Scripts
# =============================================================================
# Defines shell scripts managed by Nix.
# =============================================================================
{ pkgs, ... }:
let
  toggle-float = pkgs.writeShellScriptBin "toggle-float" ''
    IS_FLOATING=$(${pkgs.hyprland}/bin/hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.floating')
    if [ "$IS_FLOATING" = "true" ]; then
    ${pkgs.hyprland}/bin/hyprctl dispatch togglefloating
    else
    ${pkgs.hyprland}/bin/hyprctl dispatch togglefloating
    ${pkgs.hyprland}/bin/hyprctl dispatch resizeactive exact 60% 60%
    ${pkgs.hyprland}/bin/hyprctl dispatch centerwindow
    fi
  '';
  reload-waybar = pkgs.writeShellScriptBin "reload-waybar" ''
    pkill waybar
    waybar &
  '';
in
{
  home.packages = [
    toggle-float
    reload-waybar
  ];
}
