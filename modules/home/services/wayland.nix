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
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.vicinae}/bin/vicinae server";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
