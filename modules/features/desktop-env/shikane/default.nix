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
          serviceConfig = {
            ExecStart = "${pkgs.shikane}/bin/shikane";
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

                [[profile.output]]
                search = "n=eDP-1"
                enable = true
                scale = 1.0
                position = "0,1440"

                [[profile.output]]
                search = "n/.*"
                enable = true
                scale = 1.0
                position = "0,0"

                # Laptop Display Profile
                [[profile]]
                name = "laptop"

                [[profile.output]]
                search = "n=eDP-1"
                enable = true
                scale = 1.0
                mode = "1920x1200@60Hz"
                position = "0,0"

                # Fallback Profile (Auto-enable any connected monitors)
                [[profile]]
                name = "fallback"

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
