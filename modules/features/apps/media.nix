# =============================================================================
# Media & Document Applications Feature
# =============================================================================
# Media viewer (imv) and Zathura PDF reader with dark mode recolouring
# matching active theme colours and inverse search settings.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    { pkgs, config, ... }:
    let
      c = config.theme.colours;

      # Zathura parses colours with GDK, which accepts `rgba(r, g, b, a)` but
      # not 8-digit hex. Convert a theme hex triplet (no leading '#') plus an
      # alpha into an rgba() string.
      hexByte = pos: hex: (builtins.fromTOML "v = 0x${builtins.substring (pos * 2) 2 hex}").v;
      rgba =
        alpha: hex:
        "rgba(${toString (hexByte 0 hex)}, ${toString (hexByte 1 hex)}, ${toString (hexByte 2 hex)}, ${builtins.toJSON alpha})";

      # Highlight rectangles are 70% transparent (alpha 0.3) so the text they
      # cover stays readable instead of being hidden behind an opaque block.
      highlightAlpha = 0.3;
    in
    {
      config = {
        environment.systemPackages = with pkgs.unstable; [
          zathura
          imv
          musicpod
          (mpv.override {
            scripts = [
              mpvScripts.autoload
              mpvScripts.mpris
              mpvScripts.modernz
              mpvScripts.quality-menu
              mpvScripts.smartskip
              mpvScripts.thumbfast
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

                # Toggle now-playing card <-> video mode. The card shows the
                # cover art (embedded art, or the YouTube thumbnail) scaled,
                # rounded and centred with the title/artist below it; files
                # without any cover get a text-only card.
                # Note: overrides the default subtitle-visibility toggle.
                v script-message toggle-nowplaying
              '';
            };

            # Start each session in now-playing mode (yes) or video mode (no).
            ".config/mpv/script-opts/nowplaying.conf" = {
              text = ''
                initial=no
              '';
            };

            # Add the best YouTube thumbnail as an image track so the card has
            # cover art for videos too. The thumbnail is added unselected, so
            # normal video mode still plays the real video.
            ".config/mpv/script-opts/ytdl_hook.conf" = {
              text = ''
                thumbnails=best
              '';
            };

            # Custom now-playing card <-> video mode toggle (bound to `v` above).
            ".config/mpv/scripts/nowplaying.lua" = {
              text = ''
                local mp = require "mp"
                local options = require "mp.options"
                local utils = require "mp.utils"

                local function write_file(path, content)
                    local f = io.open(path, "w")
                    if f then
                        f:write(content)
                        f:close()
                    end
                end

                local opts = { initial = false }
                options.read_options(opts, "nowplaying")

                -- Layout / theme -------------------------------------------------
                local W, H = 1280, 720
                local COVER, RADIUS, COVER_Y = 340, 24, 120
                local BLUR_SIGMA, TINT_ALPHA = 45, 0.4
                local TITLE_Y, TITLE_NOCOVER_Y = 510, 300
                local ARTIST_Y, ARTIST_NOCOVER_Y = 585, 370
                local FONT = "sans"
                local BG = "0x${c.bg}"
                local FG = "0x${c.fg}"
                local FG_DIM = "0x${c.fgMid}"

                local enabled = opts.initial or false
                local pending = false
                local started = false
                local uid = tostring(utils.getpid())
                local title_file = "/tmp/mpv-nowplaying-" .. uid .. "-title.txt"
                local artist_file = "/tmp/mpv-nowplaying-" .. uid .. "-artist.txt"

                local function meta_first(keys)
                    for _, k in ipairs(keys) do
                        local v = mp.get_property("metadata/by-key/" .. k)
                        if v and v ~= "" then
                            return v
                        end
                    end
                    return ""
                end

                local function utf8len(s)
                    return #s - select(2, s:gsub("[\128-\191]", ""))
                end

                local function utf8sub(s, max)
                    local count, i = 0, 1
                    while i <= #s and count < max do
                        local b = s:byte(i)
                        local len = b < 0x80 and 1 or (b < 0xE0 and 2 or (b < 0xF0 and 3 or 4))
                        i = i + len
                        count = count + 1
                    end
                    return s:sub(1, i - 1)
                end

                -- Keep text on the canvas: shrink for medium strings, ellipsise long ones.
                local function fit(text, max_chars, base, min_size)
                    local n = utf8len(text)
                    if n > max_chars then
                        text = utf8sub(text, max_chars - 1) .. "..."
                        n = max_chars
                    end
                    local size = base
                    if n > 30 then
                        size = base - 8
                    end
                    if n > 40 then
                        size = base - 14
                    end
                    if size < min_size then
                        size = min_size
                    end
                    return text, size
                end

                -- Cover art = embedded art or an added thumbnail (image track).
                local function cover_id()
                    for _, t in ipairs(mp.get_property_native("track-list") or {}) do
                        if t.type == "video" and (t.albumart or t.image) then
                            return t.id
                        end
                    end
                end

                -- A real, moving video track (ignores cover art / thumbnails).
                local function real_video_id()
                    for _, t in ipairs(mp.get_property_native("track-list") or {}) do
                        if t.type == "video" and not (t.albumart or t.image) then
                            return t.id
                        end
                    end
                end

                local function audio_id()
                    local a = mp.get_property_native("current-tracks/audio")
                    if a then
                        return a.id
                    end
                    for _, t in ipairs(mp.get_property_native("track-list") or {}) do
                        if t.type == "audio" then
                            return t.id
                        end
                    end
                end

                -- drawtext reads the text from a file (textfile), which avoids the
                -- fragile filtergraph escaping of quotes/colons/commas/percent signs.
                local function dtext(file, size, colour, y)
                    return string.format(
                        "drawtext=font=%s:textfile=%s:fontcolor=%s:fontsize=%d:expansion=none:x=(w-text_w)/2:y=%d",
                        FONT, file, colour, size, y)
                end

                local function build_graph()
                    local title = meta_first({ "title" })
                    if title == "" then
                        title = mp.get_property("media-title") or ""
                    end
                    local artist = meta_first({ "artist", "album_artist", "uploader", "channel" })
                    local title_size, artist_size
                    title, title_size = fit(title, 44, 46, 30)
                    artist, artist_size = fit(artist, 56, 30, 20)
                    write_file(title_file, title)
                    write_file(artist_file, artist)

                    local aid, cid = audio_id(), cover_id()
                    local parts = {}

                    if cid then
                        -- Blurred cover art tinted with the theme colour, with the
                        -- sharp rounded cover composited on top.
                        parts[#parts + 1] = string.format("[vid%d]split[covsrc][bgsrc]", cid)
                        parts[#parts + 1] = string.format(
                            "[covsrc]scale=%d:%d:force_original_aspect_ratio=increase,crop=%d:%d,format=rgba," ..
                            "geq=r='p(X,Y)':g='p(X,Y)':b='p(X,Y)':" ..
                            "a='if(lt(hypot(max(0\\,abs(X-W/2)-(W/2-%d))\\,max(0\\,abs(Y-H/2)-(H/2-%d)))\\,%d)\\,255\\,0)'[cover]",
                            COVER, COVER, COVER, COVER, RADIUS, RADIUS, RADIUS)
                        parts[#parts + 1] = string.format(
                            "[bgsrc]scale=%d:%d:force_original_aspect_ratio=increase,crop=%d:%d," ..
                            "gblur=sigma=%d,eq=brightness=-0.25:saturation=0.85[bgb]",
                            W, H, W, H, BLUR_SIGMA)
                        parts[#parts + 1] = string.format(
                            "color=c=%s:s=%dx%d,format=rgba,colorchannelmixer=aa=%.2f[tint]",
                            BG, W, H, TINT_ALPHA)
                        parts[#parts + 1] = "[bgb][tint]overlay[bg]"
                        local chain = string.format("[bg][cover]overlay=x=(W-w)/2:y=%d", COVER_Y)
                        chain = chain .. "," .. dtext(title_file, title_size, FG, TITLE_Y)
                        if artist ~= "" then
                            chain = chain .. "," .. dtext(artist_file, artist_size, FG_DIM, ARTIST_Y)
                        end
                        parts[#parts + 1] = chain .. ",format=yuv420p[vo]"
                    else
                        local chain = string.format("color=c=%s:s=%dx%d", BG, W, H)
                        chain = chain .. "," .. dtext(title_file, title_size, FG, TITLE_NOCOVER_Y)
                        if artist ~= "" then
                            chain = chain .. "," .. dtext(artist_file, artist_size, FG_DIM, ARTIST_NOCOVER_Y)
                        end
                        parts[#parts + 1] = chain .. ",format=yuv420p[vo]"
                    end

                    if aid then
                        parts[#parts + 1] = string.format("[aid%d]anull[ao]", aid)
                    end
                    return table.concat(parts, ";")
                end

                local function ready()
                    return started and mp.get_property_native("current-tracks/audio") ~= nil
                end

                local function show_card()
                    local g = build_graph()
                    if g ~= mp.get_property("file-local-options/lavfi-complex", "") then
                        mp.set_property("file-local-options/lavfi-complex", g)
                    end
                end

                local function clear_card()
                    if mp.get_property("file-local-options/lavfi-complex", "") ~= "" then
                        mp.set_property("file-local-options/lavfi-complex", "")
                    end
                end

                local function apply()
                    if enabled then
                        if not ready() then
                            pending = true
                            return
                        end
                        pending = false
                        show_card()
                    else
                        pending = false
                        clear_card()
                        -- Clearing lavfi deselects the video track, so restore the
                        -- real video (or the cover art) once the teardown has settled.
                        mp.add_timeout(0.2, function()
                            if enabled then
                                return
                            end
                            local target = real_video_id() or cover_id()
                            mp.set_property("vid", target and tostring(target) or "auto")
                        end)
                    end
                end

                local function toggle()
                    enabled = not enabled
                    mp.osd_message(enabled and "Now playing" or "Video mode", 1)
                    apply()
                end

                mp.register_script_message("toggle-nowplaying", toggle)
                mp.register_event("start-file", function()
                    started = false
                end)
                mp.register_event("playback-restart", function()
                    started = true
                    if pending or enabled then
                        pending = false
                        mp.add_timeout(0.3, apply)
                    end
                end)
                mp.register_event("file-loaded", function()
                    if enabled then
                        pending = true
                    end
                end)
                mp.observe_property("metadata", "native", function()
                    if enabled and ready() then
                        show_card()
                    end
                end)
                mp.observe_property("track-list/count", "number", function()
                    if enabled and ready() then
                        show_card()
                    end
                end)
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

                # Theme colours
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

                # Enable dark mode recolouring by default
                set recolor true
                set recolor-keephue true
                set recolor-reverse-video true

                # Keybindings
                map t recolor
                map Y copy_filepath
                map b toggle_statusbar

                # Core layout colours
                set default-bg "#${c.bg}"
                set default-fg "#${c.fg}"
                set recolor-lightcolor "#${c.bg}"
                set recolor-darkcolor "#${c.fg}"

                # Statusbar colours
                set statusbar-bg "#${c.bg}"
                set statusbar-fg "#${c.fg}"

                # Input bar colours
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

                # Highlight and selection colours. The highlight fill must be
                # translucent so search hits don't cover the text, and
                # highlight-fg must not be the background colour or the matched
                # glyphs themselves would be painted invisible.
                set highlight-color "${rgba highlightAlpha c.yellow}"
                set highlight-active-color "${rgba highlightAlpha c.orange}"
                set highlight-fg "#${c.fg}"

                # Index (Table of Contents) colours
                set index-bg "#${c.bg}"
                set index-fg "#${c.fg}"
                set index-active-bg "#${c.accent}"
                set index-active-fg "#${c.bg}"
              '';
            };
          };

        };
      };
    };
}
