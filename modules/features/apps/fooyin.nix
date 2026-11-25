# Fooyin music player.
# The interface follows the active theme palette. Fooyin stores its theme as a
# Qt metatype, so a small helper writes the QSettings file at build time rather
# than keeping a hand-written variant in the repository. The Minimal layout
# uses a track list, album cover grid, now playing panel, and seekbar.
_: {
  flake.nixosModules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.features.fooyin;
      c = config.theme.colours;

      # Pick the matching fooyin icon set from the background brightness.
      bgHex = lib.fromHexString c.bg;
      bgRed = bgHex / 65536;
      bgGreen = (bgHex / 256) - (bgRed * 256);
      bgBlue = bgHex - (bgRed * 65536) - (bgGreen * 256);
      iconTheme = if (bgRed * 299) + (bgGreen * 587) + (bgBlue * 114) > 128000 then 2 else 3;

      # Roles map to the same parts of the Qt palette that the built-in themes
      # use, so widgets, menus, selections and tooltips all follow the desktop.
      themeJson = pkgs.writeText "fooyin-theme.json" (
        builtins.toJSON {
          name = "NixConfig";
          id = 100;
          index = 100;
          colours = [
            {
              group = "all";
              role = "WindowText";
              colour = c.fg;
            }
            {
              group = "disabled";
              role = "WindowText";
              colour = c.fgDim;
            }
            {
              group = "all";
              role = "Text";
              colour = c.fg;
            }
            {
              group = "disabled";
              role = "Text";
              colour = c.fgDim;
            }
            {
              group = "all";
              role = "ButtonText";
              colour = c.fg;
            }
            {
              group = "disabled";
              role = "ButtonText";
              colour = c.fgDim;
            }
            {
              group = "all";
              role = "BrightText";
              colour = c.red;
            }
            {
              group = "all";
              role = "Button";
              colour = c.bgRaised;
            }
            {
              group = "all";
              role = "Light";
              colour = c.bgSubtle;
            }
            {
              group = "all";
              role = "Midlight";
              colour = c.border;
            }
            {
              group = "all";
              role = "Dark";
              colour = c.bg;
            }
            {
              group = "all";
              role = "Mid";
              colour = c.bgRaised;
            }
            {
              group = "all";
              role = "Base";
              colour = c.bgRaised;
            }
            {
              group = "all";
              role = "Window";
              colour = c.bg;
            }
            {
              group = "all";
              role = "Shadow";
              colour = c.bg;
            }
            {
              group = "all";
              role = "Highlight";
              colour = c.accent;
            }
            {
              group = "disabled";
              role = "Highlight";
              colour = c.bgSubtle;
            }
            {
              group = "all";
              role = "HighlightedText";
              colour = c.bg;
            }
            {
              group = "disabled";
              role = "HighlightedText";
              colour = c.fgDim;
            }
            {
              group = "all";
              role = "Link";
              colour = c.teal;
            }
            {
              group = "all";
              role = "LinkVisited";
              colour = c.purple;
            }
            {
              group = "all";
              role = "AlternateBase";
              colour = c.bgSubtle;
            }
            {
              group = "all";
              role = "ToolTipBase";
              colour = c.bgRaised;
            }
            {
              group = "all";
              role = "ToolTipText";
              colour = c.fg;
            }
            {
              group = "all";
              role = "PlaceholderText";
              colour = c.fgDim;
            }
          ];
        }
      );

      configDir =
        pkgs.runCommand "fooyin-config"
          {
            nativeBuildInputs = [
              pkgs.pkg-config
              pkgs.qt6.qtbase
              pkgs.stdenv.cc
            ];
          }
          ''
            export PKG_CONFIG_PATH=${pkgs.qt6.qtbase}/lib/pkgconfig
            c++ -std=c++20 -fPIC ${./fooyin/theme-writer.cpp} -o theme-writer \
              $(pkg-config --cflags --libs Qt6Gui Qt6Core) \
              -Wl,-rpath,${pkgs.qt6.qtbase}/lib

            mkdir -p $out/layouts
            ./theme-writer $out/fooyin.conf ${themeJson}

            cat >> $out/fooyin.conf <<'EOF'

            [Interface]
            IconTheme=${toString iconTheme}

            [Library]
            AutoRefresh=true
            MonitorLibraries=true
            MonitorTrackFiles=true
            EOF

            install -m644 ${./fooyin/minimal.fyl} $out/layouts/Minimal.fyl
          '';
    in
    {
      options.features.fooyin.enable = lib.mkEnableOption "the fooyin music player";

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ pkgs.fooyin ];

        hjem.users.${config.username}.files.".config/fooyin".source = configDir;
      };
    };
}
