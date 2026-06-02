{
  pkgs,
  lib,
  hostProfile,
  ...
}:
{
  xdg.configFile."hypr/hypridle.conf".text =
    ''
      general {
          lock_cmd = pidof hyprlock || hyprlock
          before_sleep_cmd = loginctl lock-session
          after_sleep_cmd = hyprctl dispatch dpms on
      }

      listener {
          timeout = 300
          on-timeout = hyprlock
      }

      listener {
          timeout = 600
          on-timeout = hyprctl dispatch dpms off
          on-resume = hyprctl dispatch dpms on
      }
    ''
    + lib.optionalString hostProfile.isLaptop ''
      listener {
          timeout = 1200
          on-timeout = systemctl suspend
      }
    '';

  systemd.user.services.hypridle = {
    Unit = {
      Description = "Hyprland idle daemon";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.unstable.hypridle}/bin/hypridle";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };
}
