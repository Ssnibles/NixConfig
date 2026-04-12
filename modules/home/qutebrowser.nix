# =============================================================================
# Qutebrowser Module (Home Manager)
# =============================================================================
# Declarative qutebrowser setup aligned with the same Vague palette used across
# the rest of the desktop stack.
# =============================================================================
{
  pkgs,
  colors,
  ...
}:
let
  c = colors.vague.withHash;
in
{
  programs.qutebrowser = {
    enable = true;
    package = pkgs.unstable.qutebrowser-qt5;
    loadAutoconfig = false;

    aliases = {
      q = "quit";
      w = "session-save";
      wq = "quit --save";
    };

    searchEngines = {
      DEFAULT = "https://duckduckgo.com/?q={}";
      g = "https://www.google.com/search?q={}";
      gh = "https://github.com/search?q={}";
      hm = "https://home-manager-options.extranix.com/?query={}";
      nw = "https://wiki.nixos.org/w/index.php?search={}";
      yt = "https://www.youtube.com/results?search_query={}";
    };

    quickmarks = {
      gh = "https://github.com";
      hm = "https://home-manager-options.extranix.com";
      nixpkgs = "https://search.nixos.org/packages";
      wiki = "https://wiki.nixos.org";
    };

    settings = {
      auto_save.session = true;
      content = {
        autoplay = false;
        blocking.method = "both";
        cookies.accept = "no-3rdparty";
      };
      downloads = {
        position = "bottom";
        remove_finished = 8000;
      };
      editor.command = [
        "${pkgs.neovim}/bin/nvim"
        "{file}"
        "-c"
        "normal {line}G{column0}l"
      ];
      scrolling.smooth = true;
      statusbar.show = "in-mode";
      tabs = {
        favicons.show = "always";
        indicator.width = 1;
        last_close = "startpage";
        mousewheel_switching = false;
        position = "top";
        show = "multiple";
      };
      url = {
        default_page = "https://start.duckduckgo.com/";
        start_pages = [ "https://start.duckduckgo.com/" ];
      };

      colors = {
        webpage = {
          bg = c.bg;
          preferred_color_scheme = "dark";
          darkmode = {
            # Chromium's force-dark pipeline ignores `colors.webpage.bg` for most pages.
            # Keep this off so `colors.webpage.bg` remains the effective fallback.
            enabled = false;
            policy.images = "smart";
          };
        };

        completion = {
          category = {
            bg = c.bg;
            fg = c.purple;
          };
          even.bg = c.bgRaised;
          fg = c.fg;
          item.selected = {
            bg = c.selection;
            fg = c.fg;
            match.fg = c.teal;
          };
          match.fg = c.accent;
          odd.bg = c.bg;
          scrollbar = {
            bg = c.bg;
            fg = c.fgDim;
          };
        };

        downloads = {
          bar.bg = c.bg;
          error = {
            bg = c.red;
            fg = c.bg;
          };
          start = {
            bg = c.accent;
            fg = c.bg;
          };
          stop = {
            bg = c.green;
            fg = c.bg;
          };
        };

        hints = {
          bg = c.bgSubtle;
          fg = c.fg;
          match.fg = c.accent;
        };

        statusbar = {
          caret = {
            bg = c.bgSubtle;
            fg = c.orange;
          };
          command = {
            bg = c.bgSubtle;
            fg = c.fg;
          };
          insert = {
            bg = c.bgSubtle;
            fg = c.teal;
          };
          normal = {
            bg = c.bg;
            fg = c.fg;
          };
          passthrough = {
            bg = c.bgSubtle;
            fg = c.yellow;
          };
          private = {
            bg = c.bgSubtle;
            fg = c.purple;
          };
          progress.bg = c.accent;
          url = {
            error.fg = c.red;
            fg = c.fgMid;
            hover.fg = c.accent;
            success.http.fg = c.teal;
            success.https.fg = c.green;
            warn.fg = c.yellow;
          };
        };

        tabs = {
          bar.bg = c.bg;
          even = {
            bg = c.bg;
            fg = c.fgMid;
          };
          indicator = {
            error = c.red;
            start = c.accent;
            stop = c.green;
            system = "none";
          };
          odd = {
            bg = c.bg;
            fg = c.fgMid;
          };
          pinned = {
            even = {
              bg = c.bg;
              fg = c.purple;
            };
            odd = {
              bg = c.bg;
              fg = c.purple;
            };
            selected = {
              even = {
                bg = c.bgSubtle;
                fg = c.purple;
              };
              odd = {
                bg = c.bgSubtle;
                fg = c.purple;
              };
            };
          };
          selected = {
            even = {
              bg = c.bgSubtle;
              fg = c.fg;
            };
            odd = {
              bg = c.bgSubtle;
              fg = c.fg;
            };
          };
        };
      };
    };

    keyBindings.normal = {
      "J" = "tab-prev";
      "K" = "tab-next";
      "<Ctrl-h>" = "back";
      "<Ctrl-l>" = "forward";
      ",r" = "config-source";
    };

    extraConfig = ''
      config.set("content.javascript.enabled", True, "file://*")
      config.set("content.javascript.enabled", True, "chrome://*/*")
      config.set("content.javascript.enabled", True, "qute://*/*")
    '';
  };

  # Take ownership of existing user-managed files during first migration.
  xdg.configFile."qutebrowser/config.py".force = true;
  xdg.configFile."qutebrowser/quickmarks".force = true;
}
