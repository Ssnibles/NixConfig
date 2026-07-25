{ self, inputs, ... }:
{
  flake.nixosModules.qutebrowser =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (config.theme.colors)
        bg
        bgRaised
        bgSubtle
        fg
        fgMid
        fgDim
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
      environment.systemPackages = [ pkgs.unstable.qutebrowser ];

      hjem.users."${config.username}" = {
        files = {
          ".config/qutebrowser/config.py".text = ''
            config.load_autoconfig(False)

            c.auto_save.session = True

            c.content.autoplay = False
            c.content.blocking.method = "auto"
            c.content.cache.size = 52428800
            c.content.cookies.accept = "no-3rdparty"
            c.content.prefers_reduced_motion = True

            c.qt.args = ["enable-gpu-rasterization", "enable-accelerated-video-decode"]

            c.downloads.position = "bottom"
            c.downloads.remove_finished = 8000

            c.editor.command = ["${pkgs.neovim}/bin/nvim", "{file}", "-c", "normal {line}G{column0}l"]

            c.scrolling.smooth = False

            c.session.lazy_restore = True

            c.statusbar.show = "in-mode"

            c.tabs.favicons.show = "always"
            c.tabs.indicator.width = 1
            c.tabs.last_close = "startpage"
            c.tabs.mousewheel_switching = False
            c.tabs.position = "top"
            c.tabs.show = "multiple"

            c.url.default_page = "https://start.duckduckgo.com/"
            c.url.start_pages = ["https://start.duckduckgo.com/"]

            c.aliases = {
              "q": "quit",
              "w": "session-save",
              "wq": "quit --save",
            }

            c.url.searchengines = {
              "DEFAULT": "https://duckduckgo.com/?q={}",
              "g": "https://www.google.com/search?q={}",
              "gh": "https://github.com/search?q={}",
              "hm": "https://home-manager-options.extranix.com/?query={}",
              "nw": "https://wiki.nixos.org/w/index.php?search={}",
              "yt": "https://www.youtube.com/results?search_query={}",
            }

            config.quickmarks = {
              "gh": "https://github.com",
              "hm": "https://home-manager-options.extranix.com",
              "nixpkgs": "https://search.nixos.org/packages",
              "wiki": "https://wiki.nixos.org",
              "uni": "https://elearn.waikato.ac.nz",
            }

            # Colors

            c.colors.webpage.darkmode.enabled = True
            c.colors.webpage.darkmode.policy.page = "always"
            c.colors.webpage.darkmode.policy.images = "never"

            c.colors.completion.category.bg = "#${bgRaised}"
            c.colors.completion.category.fg = "#${accent}"
            c.colors.completion.even.bg = "#${bg}"
            c.colors.completion.fg = "#${fg}"
            c.colors.completion.item.selected.bg = "#${bgSubtle}"
            c.colors.completion.item.selected.fg = "#${fg}"
            c.colors.completion.item.selected.match.fg = "#${teal}"
            c.colors.completion.match.fg = "#${accent}"
            c.colors.completion.odd.bg = "#${bgRaised}"
            c.colors.completion.scrollbar.bg = "#${bgRaised}"
            c.colors.completion.scrollbar.fg = "#${fgDim}"

            c.colors.downloads.bar.bg = "#${bgRaised}"
            c.colors.downloads.error.bg = "#${red}"
            c.colors.downloads.error.fg = "#${bg}"
            c.colors.downloads.start.bg = "#${accent}"
            c.colors.downloads.start.fg = "#${bg}"
            c.colors.downloads.stop.bg = "#${green}"
            c.colors.downloads.stop.fg = "#${bg}"

            c.colors.hints.bg = "#${yellow}"
            c.colors.hints.fg = "#${bg}"
            c.colors.hints.match.fg = "#${red}"

            c.colors.statusbar.caret.bg = "#${bgRaised}"
            c.colors.statusbar.caret.fg = "#${orange}"
            c.colors.statusbar.command.bg = "#${bgRaised}"
            c.colors.statusbar.command.fg = "#${fg}"
            c.colors.statusbar.insert.bg = "#${bgRaised}"
            c.colors.statusbar.insert.fg = "#${teal}"
            c.colors.statusbar.normal.bg = "#${bgRaised}"
            c.colors.statusbar.normal.fg = "#${fg}"
            c.colors.statusbar.passthrough.bg = "#${bgRaised}"
            c.colors.statusbar.passthrough.fg = "#${yellow}"
            c.colors.statusbar.private.bg = "#${bgRaised}"
            c.colors.statusbar.private.fg = "#${purple}"
            c.colors.statusbar.progress.bg = "#${accent}"
            c.colors.statusbar.url.error.fg = "#${red}"
            c.colors.statusbar.url.fg = "#${fg}"
            c.colors.statusbar.url.hover.fg = "#${accent}"
            c.colors.statusbar.url.success.http.fg = "#${teal}"
            c.colors.statusbar.url.success.https.fg = "#${green}"
            c.colors.statusbar.url.warn.fg = "#${yellow}"

            c.colors.tabs.bar.bg = "#${bgRaised}"
            c.colors.tabs.even.bg = "#${bg}"
            c.colors.tabs.even.fg = "#${fgMid}"
            c.colors.tabs.indicator.error = "#${red}"
            c.colors.tabs.indicator.start = "#${accent}"
            c.colors.tabs.indicator.stop = "#${green}"
            c.colors.tabs.odd.bg = "#${bg}"
            c.colors.tabs.odd.fg = "#${fgMid}"
            c.colors.tabs.pinned.even.bg = "#${bg}"
            c.colors.tabs.pinned.even.fg = "#${purple}"
            c.colors.tabs.pinned.odd.bg = "#${bg}"
            c.colors.tabs.pinned.odd.fg = "#${purple}"
            c.colors.tabs.pinned.selected.even.bg = "#${bgSubtle}"
            c.colors.tabs.pinned.selected.even.fg = "#${purple}"
            c.colors.tabs.pinned.selected.odd.bg = "#${bgSubtle}"
            c.colors.tabs.pinned.selected.odd.fg = "#${purple}"
            c.colors.tabs.selected.even.bg = "#${bgSubtle}"
            c.colors.tabs.selected.even.fg = "#${fg}"
            c.colors.tabs.selected.odd.bg = "#${bgSubtle}"
            c.colors.tabs.selected.odd.fg = "#${fg}"

            # Key bindings
            config.bind("h", "tab-prev")
            config.bind("l", "tab-next")
            config.bind("1", "tab-focus 1")
            config.bind("2", "tab-focus 2")
            config.bind("3", "tab-focus 3")
            config.bind("4", "tab-focus 4")
            config.bind("5", "tab-focus 5")
            config.bind("6", "tab-focus 6")
            config.bind("7", "tab-focus 7")
            config.bind("8", "tab-focus 8")
            config.bind("9", "tab-focus 9")
            config.bind("<Ctrl-h>", "back")
            config.bind("<Ctrl-l>", "forward")
            config.bind(",r", "config-source")

            config.bind("<Ctrl-j>", "completion-item-focus --history next", mode="command")
            config.bind("<Ctrl-k>", "completion-item-focus --history prev", mode="command")

            # JavaScript enabled for local pages
            config.set("content.javascript.enabled", True, "file://*")
            config.set("content.javascript.enabled", True, "chrome://*/*")
            config.set("content.javascript.enabled", True, "qute://*/*")
          '';
        };
      };
    };
}
