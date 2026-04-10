# =============================================================================
# Wayland User Services
# =============================================================================
# Systemd user services for Wayland-specific utilities.
# =============================================================================
{ pkgs, ... }:

{
  # ── Awww wallpaper daemon ────────────────────────────────────────────────
  systemd.user.services.awww = {
    Unit = {
      Description = "Awww wallpaper daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.awww}/bin/awww-daemon";
      Restart = "on-failure";
      # Wait a bit for the compositor to be ready
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # ── Vicinae launcher ─────────────────────────────────────────────────────
  systemd.user.services.vicinae = {
    Unit = {
      Description = "Vicinae launcher daemon";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" ];
    };
    Service = {
      Environment = [ "QT_QPA_PLATFORM=wayland;xcb" ];
      ExecStart = "${pkgs.bash}/bin/bash -lc 'for i in {1..50}; do for socket in \"$XDG_RUNTIME_DIR\"/wayland-*; do if [ -S \"$socket\" ]; then export WAYLAND_DISPLAY=\"$(basename \"$socket\")\"; exec ${pkgs.vicinae}/bin/vicinae server; fi; done; sleep 0.2; done; echo \"Vicinae: Wayland socket not ready\" >&2; exit 1'";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };
}
