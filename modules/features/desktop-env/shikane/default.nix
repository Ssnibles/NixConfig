# =============================================================================
# Shikane Display Manager Daemon
# =============================================================================
# Automatic dynamic display profile management (laptop, dual-monitor, fallback)
# using Shikane and nwg-displays.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      config,
      ...
    }:
    {
      config = {
        environment.systemPackages = with pkgs; [
          shikane
        ];

        systemd.user.services.shikane = {
          description = "Shikane dynamic display configuration daemon";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          startLimitBurst = 0;
          startLimitIntervalSec = 0;
          path = [
            config.system.path
            pkgs.libnotify
          ];
          serviceConfig = {
            ExecStart = "${pkgs.shikane}/bin/shikane --timeout 1000";
            Restart = "always";
            RestartSec = 2;
          };
        };

        hjem.users."${config.username}" = {
          enable = true;
          files = {
            ".config/shikane/config.toml" = {
              text = ''
                # Shikane Dynamic Display Configuration

                # Dual Monitor Setup (External display on top/primary, laptop below)
                [[profile]]
                name = "dual_laptop_external"
                exec = ["${pkgs.libnotify}/bin/notify-send -a shikane -i video-display 'Display Manager' 'Dual monitor profile applied'"]

                [[profile.output]]
                search = "n=eDP-1"
                enable = true
                scale = 1.0
                mode = "1920x1200@60Hz"
                position = "0,1440"
                adaptive_sync = false

                [[profile.output]]
                search = "n/(HDMI|DP).*"
                enable = true
                scale = 1.0
                mode = "preferred"
                position = "0,0"
                adaptive_sync = false

                # Laptop Display Profile
                [[profile]]
                name = "laptop"
                exec = ["${pkgs.libnotify}/bin/notify-send -a shikane -i video-display 'Display Manager' 'Laptop profile applied'"]

                [[profile.output]]
                search = "n=eDP-1"
                enable = true
                scale = 1.0
                mode = "1920x1200@60Hz"
                position = "0,0"
                adaptive_sync = false

                # Fallback Profile (Auto-enable any connected monitors)
                [[profile]]
                name = "fallback"
                exec = ["${pkgs.libnotify}/bin/notify-send -a shikane -i video-display 'Display Manager' 'Fallback display profile applied'"]

                [[profile.output]]
                search = "n/.*"
                enable = true
                scale = 1.0
              '';
            };
          };
        };
      };
    };
}
