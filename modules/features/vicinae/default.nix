{ self, inputs, ... }:
{
  flake.nixosModules.vicinae =
    { pkgs, lib, config, ... }:
    let
      inherit (config.theme.colors) bg fg accent red;
    in
    {
      environment.systemPackages = with pkgs; [ vicinae ];

      hjem.users."${config.username}" = {
        enable = true;
        files = {
          ".local/share/vicinae/themes/nixconfig.toml".text = ''
            [meta]
            version = 1
            name = "nixconfig"
            description = "Generated from theme colors"
            variant = "dark"

            [colors.core]
            background = "#${bg}"
            foreground = "#${fg}"
            secondary_background = "#${bg}"
            border = "#${fg}"
            accent = "#${accent}"

            [colors.accents]
            blue = "#${accent}"
            green = "#${accent}"
            magenta = "#${accent}"
            orange = "#${accent}"
            purple = "#${accent}"
            red = "#${red}"
            yellow = "#${accent}"
            cyan = "#${accent}"
          '';

          ".config/vicinae/settings.json".text = ''
            {
              "theme": {
                "dark": {
                  "name": "nixconfig"
                }
              }
            }
          '';
        };
      };
    };
}
