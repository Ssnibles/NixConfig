{
  pkgs,
  inputs,
  ...
}:

let
  solaar = inputs.solaar.packages.${pkgs.stdenv.hostPlatform.system}.default;
in

{
  # ── Early session services ───────────────────────────────────────────────
  # These start before graphical-session.target so they're ready immediately.

  systemd.user.services.polkit-gnome-authentication-agent = {
    Unit = {
      Description = "Polkit authentication agent";
      PartOf = [ "graphical-session.target" ];
      Before = [ "graphical-session.target" ];
      After = [ "graphical-session-pre.target" ];
    };
    Service = {
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 5;
      TimeoutStartSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.solaar = {
    Unit = {
      Description = "Solaar Logitech device manager";
      PartOf = [ "graphical-session.target" ];
      Before = [ "graphical-session.target" ];
      After = [ "graphical-session-pre.target" ];
    };
    Service = {
      ExecStart = "${solaar}/bin/solaar --window=hide";
      Restart = "on-failure";
      RestartSec = 5;
      TimeoutStartSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # ── Hyprland-bound services ─────────────────────────────────────────────
  # These start after the compositor is up and stop when it goes down.

  systemd.user.services.awww = {
    Unit = {
      Description = "Awww wallpaper daemon";
      PartOf = [ "hyprland-session.target" ];
      BindsTo = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.unstable.awww}/bin/awww-daemon";
      Restart = "on-failure";
      RestartSec = 5;
      TimeoutStartSec = 10;
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };

  programs.vicinae.systemd.enable = true;
}
