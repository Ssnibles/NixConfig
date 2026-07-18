{ self, inputs, ... }:
{
  flake.nixosModules.niri =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      imports = [
        self.nixosModules.cursors
        self.nixosModules.wallpapers
      ];

      config = {
        programs.niri = {
          enable = true;
          package = self.packages.${pkgs.stdenv.hostPlatform.system}.myNiri;
        };

        # Set wallpaper destination explicitly
        wallpaper-destinations = [ "Pictures/Wallpapers" ];

        xdg.mime.defaultApplications = {
          "text/html" = "librewolf";
          "x-scheme-handler/http" = "librewolf";
          "x-scheme-handler/https" = "librewolf";
          "x-scheme-handler/about" = "librewolf";
          "x-scheme-handler/unknown" = "librewolf";
        };
      };
    };

  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      packages.myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
        inherit pkgs;
        settings = {
          spawn-at-startup = [
            (lib.getExe self'.packages.myNoctalia)
            "steam"
          ];
          xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;
          input.keyboard = {
            xkb = {
              layout = "us";
              options = "compose:ralt,ctrl:nocaps";
            };
          };

          input.touchpad = {
            tap = {};
            natural-scroll = {};
          };

          "output \"eDP-1\"" = {
            scale = 1.0;
          };

          layout = {
            gaps = 24;
          };

          cursor = {
            xcursor-theme = "Bibata-Modern-Ice";
            xcursor-size = 24;
          };

          binds = {
            "Mod+R".spawn-sh = "${lib.getExe self'.packages.myNoctalia} ipc call launcher toggle";
            "Mod+Shift+W".spawn-sh = "librewolf";
            "Mod+Return".spawn-sh = lib.getExe self'.packages.kitty;
            "Mod+Shift+C".close-window = null;

            # workspace binds
            "Mod+1".focus-workspace = "w0";
            "Mod+2".focus-workspace = "w1";
            "Mod+3".focus-workspace = "w2";
            "Mod+4".focus-workspace = "w3";
            "Mod+5".focus-workspace = "w4";
            "Mod+6".focus-workspace = "w5";
            "Mod+7".focus-workspace = "w6";
            "Mod+8".focus-workspace = "w7";
            "Mod+9".focus-workspace = "w8";
            "Mod+0".focus-workspace = "w9";

            "Mod+Shift+1".move-column-to-workspace = "w0";
            "Mod+Shift+2".move-column-to-workspace = "w1";
            "Mod+Shift+3".move-column-to-workspace = "w2";
            "Mod+Shift+4".move-column-to-workspace = "w3";
            "Mod+Shift+5".move-column-to-workspace = "w4";
            "Mod+Shift+6".move-column-to-workspace = "w5";
            "Mod+Shift+7".move-column-to-workspace = "w6";
            "Mod+Shift+8".move-column-to-workspace = "w7";
            "Mod+Shift+9".move-column-to-workspace = "w8";
            "Mod+Shift+0".move-column-to-workspace = "w9";

            # Navigation
            "Mod+WheelScrollDown".focus-column-right = null;
            "Mod+WheelScrollUp".focus-column-left = null;
            "Mod+Ctrl+WheelScrollDown".focus-workspace-down = null;
            "Mod+Ctrl+WheelScrollUp".focus-workspace-up = null;
          };

          window-rules = [
            {
              geometry-corner-radius = 0;
            }
            {
              matches = [
                { app-id = "zed"; }
                { app-id = "librewolf"; }
                { app-id = "vesktop"; }
              ];
              default-column-width = {
                proportion = 1.0;
              };
            }
            {
              matches = [
                { app-id = "steam"; }
                { title = ''^notificationtoasts_\\d+_desktop$''; }
              ];
              open-focused = false;
              default-floating-position = {
                _attrs = {
                  x = 10;
                  y = 10;
                  relative-to = "bottom-right";
                };
              };
            }
          ];

          workspaces = {
            "w0" = { };
            "w1" = { };
            "w2" = { };
            "w3" = { };
            "w4" = { };
            "w5" = { };
            "w6" = { };
            "w7" = { };
            "w8" = { };
            "w9" = { };
          };
        };
      };
    };
}
