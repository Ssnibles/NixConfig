{ ... }:
{
  nixos.modules.shared =
    { pkgs, lib, config, ... }:
    let
      inherit (config.theme.colors) bg bgRaised bgSubtle border fg fgMid fgDim
        accent teal purple green yellow red orange;
    in
    {
      environment.systemPackages = with pkgs; [ vicinae ];

      hjem.users."${config.username}" = {
        enable = true;
        files = {
          ".local/share/vicinae/themes/nixconfig.toml" = {
            text = ''
              [meta]
              version = 1
              name = "nixconfig"
              description = "Generated from theme colors"
              variant = "dark"

              [colors.core]
              background = "#${bg}"
              foreground = "#${fg}"
              secondary_background = "#${bgRaised}"
              border = "#${border}"
              accent = "#${accent}"

              [colors.accents]
              blue = "#${accent}"
              green = "#${green}"
              magenta = "#${purple}"
              orange = "#${orange}"
              purple = "#${purple}"
              red = "#${red}"
              yellow = "#${yellow}"
              cyan = "#${teal}"
            '';
          };
          ".config/vicinae/settings.json" = {
            text = ''
              {
                "theme": {
                  "dark": {
                    "name": "nixconfig"
                  }
                },
                "launcher_window": {
                  "layer_shell": {
                    "enabled": true,
                    "layer": "top"
                  }
                }
              }
            '';
          };
        };
      };
    };
}
