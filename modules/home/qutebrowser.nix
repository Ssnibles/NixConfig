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
    package = pkgs.unstable.qutebrowser;
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
      uni = "https://elearn.waikato.ac.nz";
    };

    settings = {
      auto_save.session = true;
      content = {
        autoplay = false;
        # Use one blocker backend for lower per-request overhead.
        blocking.method = "adblock";
        cookies.accept = "no-3rdparty";
        # Ask sites to reduce animations/transitions.
        prefers_reduced_motion = true;
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
      # Smoother visuals cost extra CPU; disable for responsiveness/battery.
      scrolling.smooth = false;
      # Restore tabs lazily to lower startup memory and CPU spikes.
      session.lazy_restore = true;
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
          darkmode = {
            # Force a consistent dark rendering to avoid site-by-site theme flips.
            enabled = true;
            policy.page = "always";
            policy.images = "never";
          };
        };

        completion = {
          category = {
            bg = c.bgRaised;
            fg = c.accent;
          };
          even.bg = c.bg;
          fg = c.fg;
          item.selected = {
            bg = c.search;
            fg = c.fg;
            match.fg = c.teal;
          };
          match.fg = c.accent;
          odd.bg = c.bgRaised;
          scrollbar = {
            bg = c.bgRaised;
            fg = c.fgDim;
          };
        };

        downloads = {
          bar.bg = c.bgRaised;
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
          bg = c.yellow;
          fg = c.bg;
          match.fg = c.red;
        };

        statusbar = {
          caret = {
            bg = c.bgRaised;
            fg = c.orange;
          };
          command = {
            bg = c.bgRaised;
            fg = c.fg;
          };
          insert = {
            bg = c.bgRaised;
            fg = c.teal;
          };
          normal = {
            bg = c.bgRaised;
            fg = c.fg;
          };
          passthrough = {
            bg = c.bgRaised;
            fg = c.yellow;
          };
          private = {
            bg = c.bgRaised;
            fg = c.purple;
          };
          progress.bg = c.accent;
          url = {
            error.fg = c.red;
            fg = c.fg;
            hover.fg = c.accent;
            success.http.fg = c.teal;
            success.https.fg = c.green;
            warn.fg = c.yellow;
          };
        };

        tabs = {
          bar.bg = c.bgRaised;
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
                bg = c.search;
                fg = c.purple;
              };
              odd = {
                bg = c.search;
                fg = c.purple;
              };
            };
          };
          selected = {
            even = {
              bg = c.search;
              fg = c.fg;
            };
            odd = {
              bg = c.search;
              fg = c.fg;
            };
          };
        };
      };
    };

    keyBindings.normal = {
      "J" = "tab-prev";
      "K" = "tab-next";
      "1" = "tab-focus 1";
      "2" = "tab-focus 2";
      "3" = "tab-focus 3";
      "4" = "tab-focus 4";
      "5" = "tab-focus 5";
      "6" = "tab-focus 6";
      "7" = "tab-focus 7";
      "8" = "tab-focus 8";
      "9" = "tab-focus 9";
      "<Ctrl-h>" = "back";
      "<Ctrl-l>" = "forward";
      ",r" = "config-source";
    };
    keyBindings.command = {
      "<Ctrl-j>" = "completion-item-focus --history next";
      "<Ctrl-k>" = "completion-item-focus --history prev";
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
