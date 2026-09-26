# =============================================================================
# Media & Document Applications Feature
# =============================================================================
# Media viewer (imv) and Zathura PDF reader with dark mode recoloring
# matching active theme colors and inverse search settings.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    { pkgs, config, ... }:
    let
      c = config.theme.colors;
    in
    {
      config = {
        environment.systemPackages = with pkgs.unstable; [
          zathura
          imv
          (mpv.override {
            scripts = [
              mpvScripts.autoload
              mpvScripts.mpris
              mpvScripts.modernz
              mpvScripts.quality-menu
              mpvScripts.smartskip
              mpvScripts.thumbfast
              mpvScripts.visualizer
              mpvScripts.webtorrent-mpv-hook
            ];
          })
          spotatui
          thunar
        ];

        hjem.users.${config.username} = {
          files = {
            ".config/mpv/mpv.conf" = {
              text = ''
                osc=no
                osd-bar=no

                keepaspect=yes
                keepaspect-window=yes

                # Hardware decoding + Vulkan GPU pipeline (NVIDIA Wayland)
                hwdec=auto-safe
                vo=gpu-next
                gpu-api=vulkan
                hwdec-codecs=all
                # Zero-copy decode where supported (avoids an extra NV buffer copy)
                vd-lavc-dr=yes

                # YouTube AV1 adaptive streams ("Invalid OBU length",
                # "Packet corrupt") fail to demux cleanly while streamed via
                # ffmpeg http. Prefer the more robust VP9 stream for web video
                # and buffer enough so fragments arrive whole (halved from the
                # original 512MiB / 60s to reduce RAM footprint).
                ytdl-format=bestvideo[vcodec^=vp9]+bestaudio/best
                demuxer-readahead-secs=30
                demuxer-max-bytes=256MiB

                # Modernz (OSC) conflicts with watch-later restoring sub-pos;
                # drop it from the saved options set (modernz manages sub margins itself).
                watch-later-options-remove=sub-pos
              '';
            };

            ".config/mpv/input.conf" = {
              text = ''
                # Vim-style seeking
                h seek -5
                j seek -10
                k seek +10
                l seek +5
              '';
            };

            ".config/mpv/script-opts/thumbfast.conf" = {
              text = ''
                # Enable thumbnails for YouTube / remote streams (disabled by default)
                network=yes
                spawn_first=yes

                # Use hardware decode in the thumbnailer process to cut CPU load
                hwdec=yes

                # Reap the background thumbnailer process when idle to free RAM/CPU
                quit_after_inactivity=60
              '';
            };

            ".config/mpv/script-opts/modernz.conf" = {
              text = ''
                # Disable built-in window control buttons
                window_controls=no

                # Theme colors
                osc_color=#${c.bgRaised}
                window_title_color=#${c.fg}
                window_controls_color=#${c.fg}
                windowcontrols_close_hover=#${c.red}
                windowcontrols_max_hover=#${c.yellow}
                windowcontrols_min_hover=#${c.green}
                title_color=#${c.fg}
                cache_info_color=#${c.fgMid}
                seekbar_cache_color=#${c.fgDim}
                seekbarfg_color=#${c.accent}
                seekbarbg_color=#${c.bgSubtle}
                seek_handle_color=#${c.accent}
                seek_handle_border_color=#${c.accent}
                volumebar_match_seek_color=yes
                time_color=#${c.fg}
                chapter_title_color=#${c.fg}
                side_buttons_color=#${c.fg}
                middle_buttons_color=#${c.fg}
                playpause_color=#${c.fg}
                held_element_color=#${c.fgMid}
                hover_effect_color=#${c.accent}
                thumbnail_box_color=#${c.bg}
                thumbnail_box_outline=#${c.border}
                nibble_color=#${c.accent}
                nibble_current_color=#${c.fg}
                ab_loop_color=#${c.purple}
              '';
            };

            ".config/imv/config" = {
              text = ''
                [options]
                scaling_mode = shrink
              '';
            };

            ".config/zathura/zathurarc" = {
              text = ''
                " Auto-reload PDF on file change
                set watch-files true

                " Fit width when opening
                set adjust-open "best-fit"
                set adjust-width "best-fit"
                set adjust-height "best-fit"

                " Inverse search: Ctrl+Click in Zathura opens Neovim at the line
                set synctex-editor-command "nvr --remote-silent +%{line} %{input}"

                " Preferences
                set pages-per-row 1
                set scroll-step 50
                set zoom-min 50
                set zoom-max 400
                set font "monospace 10"
                set window-title-home-tilde true
                set selection-clipboard clipboard

                # Reading ergonomics
                set scroll-page-aware true
                set scroll-full-overlap 0.1
                set link-zoom false
                set abort-clear-search true

                # Statusbar formatting
                set statusbar-page-percent true
                set statusbar-home-tilde true

                # Prevent white flash on page load
                set render-loading false
                set render-loading-bg "#${c.bg}"
                set render-loading-fg "#${c.fg}"

                # Enable dark mode recoloring by default
                set recolor true
                set recolor-keephue true
                set recolor-reverse-video true

                # Keybindings
                map t recolor
                map Y copy_filepath
                map b toggle_statusbar

                # Core layout colors
                set default-bg "#${c.bg}"
                set default-fg "#${c.fg}"
                set recolor-lightcolor "#${c.bg}"
                set recolor-darkcolor "#${c.fg}"

                # Statusbar colors
                set statusbar-bg "#${c.bg}"
                set statusbar-fg "#${c.fg}"

                # Input bar colors
                set inputbar-bg "#${c.bg}"
                set inputbar-fg "#${c.fg}"

                # Completion menu palette
                set completion-bg "#${c.bgRaised}"
                set completion-fg "#${c.fg}"
                set completion-highlight-bg "#${c.accent}"
                set completion-highlight-fg "#${c.bg}"
                set completion-group-bg "#${c.bg}"
                set completion-group-fg "#${c.fgDim}"

                # Notification and error styling
                set notification-bg "#${c.bgRaised}"
                set notification-fg "#${c.fg}"
                set notification-error-bg "#${c.bgRaised}"
                set notification-error-fg "#${c.red}"
                set notification-warning-bg "#${c.bgRaised}"
                set notification-warning-fg "#${c.yellow}"

                # Highlight and selection colors
                set highlight-color "#${c.yellow}"
                set highlight-active-color "#${c.orange}"
                set highlight-fg "#${c.bg}"

                # Index (Table of Contents) colors
                set index-bg "#${c.bg}"
                set index-fg "#${c.fg}"
                set index-active-bg "#${c.accent}"
                set index-active-fg "#${c.bg}"
              '';
            };
          };

          xdg.mime-apps.default-applications = {
            "application/pdf" = [ "org.pwmt.zathura.desktop" ];
            "application/x-pdf" = [ "org.pwmt.zathura.desktop" ];
            "image/png" = [ "imv.desktop" ];
            "image/jpeg" = [ "imv.desktop" ];
            "image/jpg" = [ "imv.desktop" ];
            "image/webp" = [ "imv.desktop" ];
            "image/gif" = [ "imv.desktop" ];
            "video/mp4" = [ "mpv.desktop" ];
            "video/webm" = [ "mpv.desktop" ];
            "video/x-matroska" = [ "mpv.desktop" ];
            "video/avi" = [ "mpv.desktop" ];
            "video/x-msvideo" = [ "mpv.desktop" ];
            "video/mpeg" = [ "mpv.desktop" ];
            "video/mp2t" = [ "mpv.desktop" ];
            "video/quicktime" = [ "mpv.desktop" ];
            "video/x-flv" = [ "mpv.desktop" ];
            "video/x-ms-wmv" = [ "mpv.desktop" ];
            "video/x-m4v" = [ "mpv.desktop" ];
            "video/3gpp" = [ "mpv.desktop" ];
            "video/3gpp2" = [ "mpv.desktop" ];
            "video/x-ogm+ogg" = [ "mpv.desktop" ];
            "video/x-theora+ogg" = [ "mpv.desktop" ];
            "video/x-mng" = [ "mpv.desktop" ];
            "application/vnd.apple.mpegurl" = [ "mpv.desktop" ];
            "application/x-mpegURL" = [ "mpv.desktop" ];
            "application/mp4" = [ "mpv.desktop" ];
            "application/ogg" = [ "mpv.desktop" ];
          };
        };

        xdg.mime = {
          enable = true;
          defaultApplications = {
            "application/pdf" = [ "org.pwmt.zathura.desktop" ];
            "application/x-pdf" = [ "org.pwmt.zathura.desktop" ];
            "image/png" = [ "imv.desktop" ];
            "image/jpeg" = [ "imv.desktop" ];
            "image/jpg" = [ "imv.desktop" ];
            "image/webp" = [ "imv.desktop" ];
            "image/gif" = [ "imv.desktop" ];
            "video/mp4" = [ "mpv.desktop" ];
            "video/webm" = [ "mpv.desktop" ];
            "video/x-matroska" = [ "mpv.desktop" ];
            "video/avi" = [ "mpv.desktop" ];
            "video/x-msvideo" = [ "mpv.desktop" ];
            "video/mpeg" = [ "mpv.desktop" ];
            "video/mp2t" = [ "mpv.desktop" ];
            "video/quicktime" = [ "mpv.desktop" ];
            "video/x-flv" = [ "mpv.desktop" ];
            "video/x-ms-wmv" = [ "mpv.desktop" ];
            "video/x-m4v" = [ "mpv.desktop" ];
            "video/3gpp" = [ "mpv.desktop" ];
            "video/3gpp2" = [ "mpv.desktop" ];
            "video/x-ogm+ogg" = [ "mpv.desktop" ];
            "video/x-theora+ogg" = [ "mpv.desktop" ];
            "video/x-mng" = [ "mpv.desktop" ];
            "application/vnd.apple.mpegurl" = [ "mpv.desktop" ];
            "application/x-mpegURL" = [ "mpv.desktop" ];
            "application/mp4" = [ "mpv.desktop" ];
            "application/ogg" = [ "mpv.desktop" ];
          };
        };
      };
    };
}
