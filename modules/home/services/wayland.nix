{
  pkgs,
  ...
}:

{
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

  systemd.user.services.solaar = {
    Unit = {
      Description = "Solaar Logitech device manager";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.solaar}/bin/solaar --window=hide";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

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

  programs.vicinae.systemd.enable = true;
}
