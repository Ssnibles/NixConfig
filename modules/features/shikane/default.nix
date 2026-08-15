{ ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      config = {
        environment.systemPackages = with pkgs; [
          shikane
          nwg-displays
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

                # Laptop Display Profile
                [[profile]]
                name = "laptop"

                [[profile.output]]
                match = "eDP-1"
                enable = true
                scale = 1.0
                mode = "1920x1080@60Hz"
                position = "0,0"

                # Dual Monitor Setup (External display on top/primary, laptop below)
                [[profile]]
                name = "dual_laptop_external"

                [[profile.output]]
                match = "eDP-1"
                enable = true
                scale = 1.0
                position = "0,1080"

                [[profile.output]]
                match = ".*"
                enable = true
                scale = 1.0
                position = "0,0"

                # Fallback Profile (Auto-enable any connected monitors)
                [[profile]]
                name = "fallback"

                [[profile.output]]
                match = ".*"
                enable = true
                scale = 1.0
              '';
            };
          };
        };
      };
    };
}
