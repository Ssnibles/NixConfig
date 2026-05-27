# =============================================================================
# Wayland User Services
# =============================================================================
# Systemd user services for Wayland-specific utilities.
# =============================================================================
{
  pkgs,
  lib,
  hostProfile,
  ...
}:

{
  # ── Polkit authentication agent ───────────────────────────────────────────
  systemd.user.services.polkit-gnome-authentication-agent = {
    Unit = {
      Description = "Polkit authentication agent";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # ── Solaar Logitech device manager ─────────────────────────────────────────
  systemd.user.services.solaar = {
    Unit = {
      Description = "Solaar Logitech device manager";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      # The --battery flag restricts Solaar to monitoring mode
      ExecStart = "${pkgs.solaar}/bin/solaar --window=hide";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # ── Awww wallpaper daemon ────────────────────────────────────────────────
  systemd.user.services.awww = {
    Unit = {
      Description = "Awww wallpaper daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.bash}/bin/bash -lc 'for i in {1..50}; do for socket in \"$XDG_RUNTIME_DIR\"/wayland-*; do if [ -S \"$socket\" ]; then export WAYLAND_DISPLAY=\"$(basename \"$socket\")\"; exec ${pkgs.unstable.awww}/bin/awww-daemon; fi; done; sleep 0.1; done; echo \"Awww: Wayland socket not ready\" >&2; exit 1'";
      Restart = "on-failure";
      RestartSec = 1;
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
      Environment = [ "QT_QPA_PLATFORM=wayland;xcb" ];
      ExecStart = "${pkgs.bash}/bin/bash -lc 'for i in {1..50}; do for socket in \"$XDG_RUNTIME_DIR\"/wayland-*; do if [ -S \"$socket\" ]; then export WAYLAND_DISPLAY=\"$(basename \"$socket\")\"; exec ${pkgs.vicinae}/bin/vicinae server; fi; done; sleep 0.2; done; echo \"Vicinae: Wayland socket not ready\" >&2; exit 1'";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # ── Kando pie menu ───────────────────────────────────────────────────────
  systemd.user.services.kando = {
    Unit = {
      Description = "Kando pie menu";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Environment = [
        "ELECTRON_OZONE_PLATFORM_HINT=auto"
        "NIXOS_OZONE_WL=1"
      ];
      ExecStart = "${pkgs.unstable.kando}/bin/kando";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # ── Swayidle ─────────────────────────────────────────────────────────────
  services.swayidle = {
    enable = true;
    package = pkgs.swayidle;
    events = [
      {
        event = "before-sleep";
        command = "${pkgs.unstable.swaylock}/bin/swaylock -f";
      }
      {
        event = "after-resume";
        command = "${pkgs.niri}/bin/niri msg action wake-monitors";
      }
      {
        event = "lock";
        command = "${pkgs.unstable.swaylock}/bin/swaylock -f";
      }
    ];
    timeouts = [
      {
        timeout = 300;
        command = "${pkgs.unstable.swaylock}/bin/swaylock -f";
      }
      {
        timeout = 600;
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
        resumeCommand = "${pkgs.niri}/bin/niri msg action wake-monitors";
      }
    ]
    ++ lib.optionals hostProfile.isLaptop [
      {
        timeout = 1200;
        command = "${pkgs.systemd}/bin/systemctl suspend";
      }
    ];
  };
}
