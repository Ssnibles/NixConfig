{ ... }:
{
  perSystem = { pkgs, ... }: {
    packages.foot = pkgs.foot;
  };

  nixos.modules.shared =
    {
      pkgs,
      config,
      ...
    }:
    let
      inherit (config.theme.colors)
        bg
        bgRaised
        fg
        accent
        teal
        purple
        green
        yellow
        red
        orange
        ;
    in
    {
      environment.systemPackages = [ pkgs.foot ];

      systemd.user.services.foot-server = {
        description = "Foot terminal server";
        documentation = [ "man:foot(1)" ];
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        aliases = [ "foot.service" ];
        unitConfig = {
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };
        path = [ config.system.path ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.foot}/bin/foot --server";
          Restart = "on-failure";
          RestartSec = 2;
        };
      };

      hjem.users."${config.username}" = {
        files = {
          ".config/foot/foot.ini" = {
            text = ''
              include=/home/${config.username}/.config/foot/colors.ini
              font=JetBrainsMono Nerd Font:size=12
              pad=10x10

              [cursor]
              style=block

              [text-bindings]
              \x1f = Control+BackSpace
            '';
          };
          ".config/foot/colors.ini" = {
            text = ''
              [colors-dark]
              background=${bg}
              foreground=${fg}
              selection-foreground=${bg}
              selection-background=${accent}
              regular0=${bg}
              regular1=${red}
              regular2=${green}
              regular3=${yellow}
              regular4=${accent}
              regular5=${purple}
              regular6=${teal}
              regular7=${fg}
              bright0=${bgRaised}
              bright1=${orange}
              bright2=${green}
              bright3=${yellow}
              bright4=${accent}
              bright5=${purple}
              bright6=${teal}
              bright7=${fg}
            '';
          };
        };
      };
    };
}
