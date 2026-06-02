{
  config,
  pkgs,
  semanticColors,
  ...
}:
let
  c = semanticColors { colors = config.lib.stylix.colors; };
  isDark = config.lib.stylix.colors.variant != "light";
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
        blocking.method = "auto";
        cookies.accept = "no-3rdparty";
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
      scrolling.smooth = false;
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
            enabled = isDark;
            policy.page = "smart";
            policy.images = if isDark then "never" else "smart";
          };
        };

        completion = {
          category = {
            bg = c.withHash.bgRaised;
            fg = c.withHash.accent;
          };
          even.bg = c.withHash.bg;
          fg = c.withHash.fg;
          item.selected = {
            bg = c.withHash.bgSubtle;
            fg = c.withHash.fg;
            match.fg = c.withHash.teal;
          };
          match.fg = c.withHash.accent;
          odd.bg = c.withHash.bgRaised;
          scrollbar = {
            bg = c.withHash.bgRaised;
            fg = c.withHash.fgDim;
          };
        };

        downloads = {
          bar.bg = c.withHash.bgRaised;
          error = {
            bg = c.withHash.red;
            fg = c.withHash.bg;
          };
          start = {
            bg = c.withHash.accent;
            fg = c.withHash.bg;
          };
          stop = {
            bg = c.withHash.green;
            fg = c.withHash.bg;
          };
        };

        hints = {
          bg = c.withHash.yellow;
          fg = c.withHash.bg;
          match.fg = c.withHash.red;
        };

        statusbar = {
          caret = {
            bg = c.withHash.bgRaised;
            fg = c.withHash.orange;
          };
          command = {
            bg = c.withHash.bgRaised;
            fg = c.withHash.fg;
          };
          insert = {
            bg = c.withHash.bgRaised;
            fg = c.withHash.teal;
          };
          normal = {
            bg = c.withHash.bgRaised;
            fg = c.withHash.fg;
          };
          passthrough = {
            bg = c.withHash.bgRaised;
            fg = c.withHash.yellow;
          };
          private = {
            bg = c.withHash.bgRaised;
            fg = c.withHash.purple;
          };
          progress.bg = c.withHash.accent;
          url = {
            error.fg = c.withHash.red;
            fg = c.withHash.fg;
            hover.fg = c.withHash.accent;
            success.http.fg = c.withHash.teal;
            success.https.fg = c.withHash.green;
            warn.fg = c.withHash.yellow;
          };
        };

        tabs = {
          bar.bg = c.withHash.bgRaised;
          even = {
            bg = c.withHash.bg;
            fg = c.withHash.fgMid;
          };
          indicator = {
            error = c.withHash.red;
            start = c.withHash.accent;
            stop = c.withHash.green;
          };
          odd = {
            bg = c.withHash.bg;
            fg = c.withHash.fgMid;
          };
          pinned = {
            even = {
              bg = c.withHash.bg;
              fg = c.withHash.purple;
            };
            odd = {
              bg = c.withHash.bg;
              fg = c.withHash.purple;
            };
            selected = {
              even = {
                bg = c.withHash.bgSubtle;
                fg = c.withHash.purple;
              };
              odd = {
                bg = c.withHash.bgSubtle;
                fg = c.withHash.purple;
              };
            };
          };
          selected = {
            even = {
              bg = c.withHash.bgSubtle;
              fg = c.withHash.fg;
            };
            odd = {
              bg = c.withHash.bgSubtle;
              fg = c.withHash.fg;
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
}
