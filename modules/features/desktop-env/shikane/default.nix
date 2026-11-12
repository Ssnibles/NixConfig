# Shikane display profiles.
{ ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      lib,
      config,
      mkWaylandService,
      ...
    }:
    let
      cfg = config.features.shikane;
    in
    {
      options.features.shikane.enable = lib.mkEnableOption "the Shikane dynamic display profile daemon";

      config = lib.mkIf cfg.enable {
        environment.systemPackages = with pkgs; [
          shikane
        ];

        systemd.user.services.shikane = mkWaylandService {
          description = "Shikane dynamic display configuration daemon";
          execStart = "${pkgs.shikane}/bin/shikane --timeout 1000";
          path = [ pkgs.libnotify ];
          restart = "always";
        };

        hjem.users."${config.username}" = {
          enable = true;
          files = {
            ".config/shikane/config.toml" = {
              text = ''
                # Dual monitor setup with the external display above the laptop.
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

                # Laptop only.
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

                # Turn on any connected monitor.
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
