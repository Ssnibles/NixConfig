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

  # ── Focus Mode Toggle (gaps + waybar toggle) ───────────────────────────────
  toggle-focus-mode = pkgs.writeShellScriptBin "toggle-focus-mode" ''
    STATE_FILE="/tmp/hyprland-focus-mode"

    # Default values from your hyprland.nix
    GAPS_IN=8
    GAPS_OUT=16
    ROUNDING=16

    if [ -f "$STATE_FILE" ] && [ "$(cat $STATE_FILE)" = "focus" ]; then
      # ── Restore Normal Mode ──────────────────────────────────────────────
      ${pkgs.hyprland}/bin/hyprctl keyword general:gaps_in $GAPS_IN
      ${pkgs.hyprland}/bin/hyprctl keyword general:gaps_out $GAPS_OUT
      ${pkgs.hyprland}/bin/hyprctl keyword decoration:rounding $ROUNDING

      # Toggle waybar visibility (SIGUSR1 toggles)
      ${pkgs.procps}/bin/pkill -SIGUSR1 waybar

      echo "normal" > "$STATE_FILE"
      ${pkgs.libnotify}/bin/notify-send "Focus Mode" "Disabled - Normal mode restored"
    else
      # ── Enable Focus Mode ────────────────────────────────────────────────
      ${pkgs.hyprland}/bin/hyprctl keyword general:gaps_in 0
      ${pkgs.hyprland}/bin/hyprctl keyword general:gaps_out 0
      ${pkgs.hyprland}/bin/hyprctl keyword decoration:rounding 0

      # Toggle waybar visibility (SIGUSR1 toggles)
      ${pkgs.procps}/bin/pkill -SIGUSR1 waybar

      echo "focus" > "$STATE_FILE"
      ${pkgs.libnotify}/bin/notify-send "Focus Mode" "Enabled - Distractions removed"
    fi
  '';
in
{
  home.packages = [
    toggle-float
    reload-waybar
    toggle-focus-mode
  ];
}
