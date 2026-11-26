# Media, Document Viewer & Audio Stack Guide

This guide details the media playback engine (MPV), document viewer (Zathura), image viewer (imv), PipeWire audio stack, and streaming utilities configured in NixConfig.

---

## Overview

The media stack is optimised for hardware acceleration, low latency, and aesthetic unity with the system colour palette:

| Application / Layer | Technology | Key Capabilities | Configuration Location |
| :--- | :--- | :--- | :--- |
| **Video Player** | **MPV** | Vulkan `gpu-next` pipeline, hardware decode, themed Modernz OSC, Thumbfast, toggleable now-playing card | `modules/features/apps/media.nix` |
| **PDF & Documents** | **Zathura** | Dynamic dark mode recolouring, Neovim SyncTeX reverse search | `modules/features/apps/media.nix` |
| **Image Viewer** | **imv** | Fast Wayland image viewer with shrink scaling | `modules/features/apps/media.nix` |
| **Audio Server** | **PipeWire** | Low-latency audio with WirePlumber, ALSA, PulseAudio, and JACK support | `modules/features/system/pipewire.nix` |
| **Equaliser** | **PipeWire `param_eq`** | AutoEq curves per device, parsed natively with no extra packages | `modules/features/system/pipewire.nix` |
| **Streaming CLI** | **ytplay** | Terminal command for direct YouTube playback in MPV | `modules/features/system/base.nix` |
| **Spotify** | **Spicetify & spotatui** | Themed desktop Spotify client and terminal TUI | `modules/features/apps/spotify.nix` & `media.nix` |
| **Spotifast** | **Flatpak bundle** | Native Rust Spotify client (`rocks.spotifast.Spotifast`) installed from a GitHub-release `.flatpak` bundle tracked at the latest release | `modules/features/system/flatpak/` |
| **Nuvio Desktop** | **Flatpak bundle** | Stremio-addon media player (`com.nuvio.media.desktop`) installed from a GitHub-release `.flatpak` bundle tracked at the latest release | `modules/features/system/flatpak/` |
| **Antra** | **Flatpak bundle** | Music library builder (`io.github.anandprtp.Antra`) that tags and files tracks into artist and album folders, installed from a GitHub-release `.flatpak` bundle tracked at the latest release | `modules/features/system/flatpak/` |
| **Music Library** | **Beets** | Tags imports from MusicBrainz, files them into `Artist/Album/Track Title`, and fills in cover art, lyrics, genres, and ReplayGain | `modules/features/apps/beets.nix` |
| **Music Player** | **Fooyin** | Customisable Qt player with a palette-matched theme, track list, album cover grid, and artwork and metadata sidebar | `modules/features/apps/fooyin.nix` |
| **Streaming Client** | **Sonora** | Native Rust client for streaming services and local files, built from the upstream flake and substituted from its own binary cache | `modules/features/apps/sonora.nix` |

> **Spotifast**, **Nuvio Desktop** and **Antra** are delivered as sandboxed Flatpaks rather than Nix packages because they are not published on Flathub. Installation, GitHub-release tracking, and updates are covered in the [Flatpak & Sandboxed Applications Guide](flatpak.md).

---

## MPV Hardware-Accelerated Video Player

MPV is packaged via `modules/features/apps/media.nix` with a custom override bundling community scripts and optimal video decoding flags.

### Hardware Acceleration & Vulkan Pipeline

Configured in `~/.config/mpv/mpv.conf`:
- **Vulkan Next-Gen Pipeline**: `vo=gpu-next` with `gpu-api=vulkan` for smooth frame pacing on Wayland.
- **Hardware Decoding**: `hwdec=auto-safe` with `hwdec-codecs=all` offloading decoding to GPU hardware (NVIDIA NVDEC on desktop, AMD VCN on laptop).
- **Direct Rendering**: `vd-lavc-dr=yes` enables zero-copy video decode, avoiding extra memory copies between GPU and system RAM.

### Web Video & YouTube Streaming Optimisation

YouTube adaptive AV1 streams frequently cause packet demuxing errors over FFmpeg HTTP streams. NixConfig optimises web streaming:
- **VP9 Stream Preference**: `ytdl-format=bestvideo[vcodec^=vp9]+bestaudio/best` selects robust VP9 streams over brittle AV1 streams.
- **Buffer Management**: `demuxer-readahead-secs=30` and `demuxer-max-bytes=256MiB` ensure video fragments arrive whole while preventing runaway memory consumption.

### Vim-Style Seeking (`input.conf`)

Seeking controls follow standard Vim home-row navigation:
- **`h`**: Seek backward 5 seconds
- **`l`**: Seek forward 5 seconds
- **`j`**: Seek backward 10 seconds
- **`k`**: Seek forward 10 seconds

### Now-Playing Card (`v`)

A custom Lua script (`~/.config/mpv/scripts/nowplaying.lua`) adds a single-key toggle between a **now-playing card** and normal **video mode**:

- **Now-playing mode**: builds a `lavfi-complex` filter graph: the cover art fills the window heavily blurred and tinted with the theme colour, with the sharp cover centre-cropped to a square and rounded on top, plus the track **title** and **artist** below it. Embedded art is used for local files; for YouTube, `ytdl_hook.conf` sets `thumbnails=best`, which adds the video thumbnail as an *unselected* image track (so it never hijacks the real video). Files with no cover at all get a text-only card on the flat theme background.
- **Video mode** (default): normal playback, restoring the real video track (or the plain cover art for audio files).

The card colours are pulled from the active theme (`bg`, `fg`, `fgMid`). Title/artist text is passed through `drawtext` `textfile`s with `expansion=none`, so quotes, colons, commas and `%` render literally, and long titles are shrunk/ellipsised to stay on the canvas. Pressing **`v`** toggles the mode with a short OSD confirmation, and the state carries across playlist entries. Set `initial=yes` in `script-opts/nowplaying.conf` to start every session in now-playing mode.

The card is only applied once playback has actually started, which avoids reconfiguring the video chain while a network stream is still opening. When MPV exits, a registered `shutdown` event hook cleans up any temporary metadata files (`/tmp/mpv-nowplaying-<pid>-*.txt`) to prevent stale `/tmp` artifacts.

> **Note:** binding `v` overrides MPV's default subtitle-visibility toggle.

### Bundled Scripts & Theming

- **Modernz OSC (`modernz.conf`)**: Replaces the default on-screen controller with a clean, modern interface. Nix injects the active system colour palette (`bgRaised`, `accent`, `red`, `yellow`, `green`) into the seekbars, volume sliders, and hover effects. Window controls are disabled to match tiling compositor aesthetics.
- **Thumbfast (`thumbfast.conf`)**: Generates instant thumbnail previews while hovering over the seekbar. Configured with hardware decoding (`hwdec=yes`), remote network stream support (`network=yes`), and an automatic idle timeout (60 seconds) that reaps the background process to free system memory.
- **Now-Playing Card (`scripts/nowplaying.lua`)**: Custom toggle (**`v`**) that renders a centred, rounded cover-art card with the title/artist below (embedded art, or the YouTube thumbnail via `ytdl_hook.conf`: `thumbnails=best`), or a text-only card for coverless media.
- **Autoload**: Automatically loads all adjacent media files in the active directory into the playlist.
- **MPRIS**: Exposes playback state and track metadata to Quickshell status widgets and media control keys (`playerctl`).
- **Quality Menu**: On-screen menu allowing interactive video resolution and stream selection.
- **Smartskip**: Automatically detects and skips video intros and outros.
- **Webtorrent Hook**: Allows streaming magnet links and torrent files directly in MPV.

---

## Zathura PDF Reader & Neovim Inverse Search

Zathura provides keyboard-driven document reading configured in `modules/features/apps/media.nix`.

### Dynamic Theme Recolouring

Zathura automatically adapts to your system colour palette:
- **`recolor true`**, **`recolor-keephue true`**, and **`recolor-reverse-video true`**: Inverts document pages into an eye-friendly dark mode while preserving syntax highlighting and preventing images/diagrams from being inverted into negatives.
- **Full Theme Palette Integration**: Statusbar, input bar, `:command` completion menu (`c.bgRaised`, `c.accent`), and notification banners dynamically follow `config.theme.colours`.
- **Reading Ergonomics**: `scroll-page-aware` prevents awkward split page boundaries, `scroll-full-overlap 0.1` maintains context across page jumps, `link-zoom false` prevents citation links from resetting custom zoom levels, and `render-loading false` avoids white flashes during page rendering.

### Keybindings & Controls

| Key | Action | Description |
|---|---|---|
| **`t`** / **`Ctrl+r`** | `recolor` | Toggle custom recoloured dark mode |
| **`Y`** | `copy_filepath` | Copy full path of current document to system clipboard |
| **`b`** | `toggle_statusbar` | Toggle statusbar for distraction-free reading |
| **`f`** | `follow` | Link hints (Vimium-style letter labels on links and citations) |
| **`d`** | `toggle_page_mode` | Toggle dual-page (spread) reading view |
| **`a`** / **`s`** | `adjust_window` | Adjust page zoom to best-fit or full width |
| **`Ctrl+o`** / **`Ctrl+i`** | `jumplist` | Jump backward / forward through navigation history |

### Neovim Inverse Search via SyncTeX

For academic writing, Typst, and LaTeX documents, Zathura is configured for two-way synchronisation:
```ini
set synctex-editor-command "nvr --remote-silent +%{line} %{input}"
```
Holding **`Ctrl`** and clicking any paragraph or equation in Zathura automatically opens your running Neovim instance at the exact source file and line number. NixOS provides `neovim-remote` (`nvr`) globally in `environment.systemPackages` to guarantee that inverse search calls connect cleanly to active Neovim server sockets.

### Native Document Watching & Auto-Reload

Using native file monitoring (`filemonitor "glib"`), Zathura automatically monitors PDF files on disk and reloads them instantly whenever a compiler (Typst, tectonic, pdflatex) writes a new build.

---

## Image Viewing with imv

`imv` is configured as the default image viewer for PNG, JPEG, WebP, and GIF files:
- Scaling mode set to `shrink` (`~/.config/imv/config`), displaying full-resolution images scaled cleanly within window boundaries.
- Works seamlessly with Yazi openers and compositor tiling rules.

---

## Low-Latency PipeWire Audio Stack

Configured in `modules/features/system/pipewire.nix`:

- **PipeWire Core**: Provides modern Wayland-native audio routing and screen capture support.
- **WirePlumber**: Modular session manager for dynamic audio device switching (Bluetooth headphones, USB DACs, HDMI outputs).
- **Compatibility Layers**:
  - `alsa.enable = true` with 32-bit ALSA support for legacy games.
  - `pulse.enable = true` providing full PulseAudio emulation for Discord/Vesktop and browser media.
  - `jack.enable = true` enabling pro-audio low-latency routing without running a separate JACK daemon.

---

## Per-Device Equaliser (`param_eq`)

`modules/features/system/pipewire.nix` defines two filter-chain sinks that run AutoEq parametric curves through PipeWire's built-in `param_eq` filter. Nothing else is installed: `param_eq` parses the AutoEq text format directly, preamp included.

- **`eq_aria2`** ("Aria 2 EQ") for the Moondrop Aria 2 on the Moondrop Dawn Pro DAC.
- **`eq_hd450bt`** ("HD 450BT EQ") for the Sennheiser HD 450BT over Bluetooth.

Each chain's playback node is passive, so WirePlumber links it to whichever device is the current default output. A WirePlumber Lua script (`auto-eq.lua`) then makes the matching sink the default whenever devices appear, disappear or change, so the curve follows the output without any polling.

The scripts match the output device, not the headphone name: the Aria 2 profile matches the Dawn Pro DAC and the HD 450BT profile matches the Bluetooth device. Plugging in the DAC or turning the headset on selects the right curve; unplugging either returns to the plain device with no equaliser.

| Command | Effect |
| :--- | :--- |
| `pipewire-eq status` | Print the default sink and whether auto is on |
| `pipewire-eq off` | Bypass the equaliser, back to the device it was feeding |
| `pipewire-eq on` | Resume automatic selection |
| `pipewire-eq aria2` | Force the Aria 2 curve and stop auto |
| `pipewire-eq hd450bt` | Force the HD 450BT curve and stop auto |

Auto is the default state. The manual profile commands and `off` set a latch in the WirePlumber `default` metadata under `default.auto-eq`, which `pipewire-eq on` clears. The latch is runtime state, so a reboot returns to automatic selection. Both sinks also appear in the bar's output switcher and in `pavucontrol` under their descriptions.

Picking an output in the command centre's switcher sets the same latch, so the automatic match does not undo the choice. Choosing the plain device there bypasses the equaliser; run `pipewire-eq on` to go back to automatic selection.

### Volume

The equaliser adds a second volume stage: the sink in front of the device and the device itself, and PipeWire multiplies the two. Left alone, a DAC at 15% behind a sink at 70% plays at roughly 10%, which is what makes it sound far too quiet.

`pipewire-eq` avoids that by carrying the level across when it switches sinks and leaving the device it feeds at 100%. The bar slider therefore stays a single control, and the percentage behaves like it did before the equaliser existed: 25% on the Aria 2 sink is about the same loudness as 25% straight to the DAC. Bluetooth devices keep their own volume, since that belongs to the headset.

If a device ends up quiet because its own volume was lowered while the equaliser was bypassed, `pipewire-eq on` folds that level back into the sink and returns the device to unity.

Because nothing polls, there is no background CPU cost. The Lua hooks only run on device and metadata events. A chain handling audio runs a chain of biquads, well under 1% of one core, and a chain with no audio costs nothing measurable.

### Measurement Sources

| Headphone | Measurement | Curve |
| :--- | :--- | :--- |
| Moondrop Aria 2 | Harpo | [results/Harpo/in-ear/Moondrop Aria 2](https://github.com/jaakkopasanen/AutoEq/tree/master/results/Harpo/in-ear/Moondrop%20Aria%202) |
| Sennheiser HD 450BT | oratory1990 | [results/oratory1990/over-ear/Sennheiser HD 450BT](https://github.com/jaakkopasanen/AutoEq/tree/master/results/oratory1990/over-ear/Sennheiser%20HD%20450BT) |

AutoEq also publishes Jaytiss and Super Review measurements for the Aria 2, so the curve can be swapped without changing anything else in the chain.

### Swapping a Curve

1. Open the AutoEq results directory for the model.
2. Copy the contents of the `... ParametricEQ.txt` file.
3. Replace the matching `pkgs.writeText` body in `modules/features/system/pipewire.nix`.
4. Run `nixos-rebuild switch`, then run `pipewire-eq on` if a manual profile is active.

The filter list is read when the chain is created, so a rebuild is required. Bands, gain and Q all come straight from the file.

---

## Fooyin music player

fooyin is the graphical library player. The module is [`modules/features/apps/fooyin.nix`](../../modules/features/apps/fooyin.nix) and is enabled by default through `features.fooyin.enable`.

The interface uses the active desktop palette and the `Minimal` layout: a track list, an album cover grid, artwork with selection info, and a full-width seekbar above the bottom transport row. The album grid only includes tracks that belong to a fooyin library, so add the music folder from **Settings > Library** first.

For the palette role mapping, `.fyt` theme format, `FyTheme` storage, layout state, and troubleshooting, see the **[Fooyin Player & Theming Guide](fooyin.md)**.

---

## Sonora music client

Sonora is the streaming and local-file client. The module is [`modules/features/apps/sonora.nix`](../../modules/features/apps/sonora.nix) and is enabled by default through `features.sonora.enable`. It imports the upstream NixOS module, so `programs.sonora` owns the package, the WebKit, GStreamer and ALSA environment the binary needs, and an optional `settings.json` write.

Nothing is packaged in nixpkgs, so the flake input builds it with crane against its own pinned nixpkgs. Upstream CI pushes every build to `https://sonora.cachix.org`, and the cache is trusted in `modules/features/system/base.nix`. The input deliberately does not follow the repo's nixpkgs: a follow changes the derivation hash and turns a download into a full Rust build, so leave `flake.nix` alone if you are tempted to tidy it.

The input tracks upstream `main`, where CI caches each push. The `stable` ref was not in the cache when this was written, so check `curl -o /dev/null -w '%{http_code}' https://sonora.cachix.org/<hash>.narinfo` on the store path before switching refs. The first switch after adding the cache still needs the cache in `/etc/nix/nix.conf`, because the running system evaluates with the old settings.

---

## Music library with beets

beets tags and files a local music library. The module is [`modules/features/apps/beets.nix`](../../modules/features/apps/beets.nix), and the generated config lives at `~/.config/beets/config.yaml`. The library database and state file sit beside it, so `~/.config/beets` holds the whole library index.

The music itself stays in `~/Music` by default. Change `features.beets.directory` in a host file to use another folder.

`config.yaml` is a read-only symlink into the Nix store, so change settings in the module and rebuild instead of editing the file. The library database and state file are written at runtime and stay in `~/.config/beets`.

### Importing

```bash
# Tag and file a download or album folder
beet import ~/Downloads/some-album

# Re-check files already in the library, ignoring the import memory
beet import -I ~/Music
```

Imports move files into the library (`import.move: yes`, `import.copy: no`), so the source folder is emptied as each album is filed. A dry run is available with `beet import --pretend`.

`import.incremental: yes` records each import, so running the same folder again skips albums that are already in the library. Pass `-I` to import the folder again anyway.

`import.incremental_skip_later: yes` keeps skipped albums out of that record. Without it, an album declined once, or one that quiet mode (`-q`) skips for a weak match, is remembered as imported and never offered again.

### Folder layout

| Path setting | Layout |
| :--- | :--- |
| `default` | `$albumartist/$album%aunique{}/$track $title` |
| `singleton` | `Non-Album/$artist/$title` |
| `comp` | `Compilations/$album%aunique{}/$track $title` |

`%aunique{}` adds a disambiguator such as the year or label only when two albums would otherwise share a folder. `art_filename: cover` writes downloaded art as `cover.jpg`.

### Enabled plugins

| Plugin | Effect |
| :--- | :--- |
| `chroma` | Fingerprints tracks with AcoustID to improve autotag matches |
| `fetchart` | Downloads art from the album folder, Cover Art Archive, iTunes, or Wikipedia, resized to at most 1200 px |
| `embedart` | Embeds art into files that have none, and leaves existing art alone |
| `lyrics` | Fetches lyrics from LRCLIB and lrcmux, keeping the timestamps when the source has them. Genius is left out because it rate-limits the shared key that ships with beets and stalls imports |
| `lastgenre` | Writes the most specific Last.fm genre that survives canonicalisation and the genre whitelist |
| `replaygain` | Writes ReplayGain tags with the ffmpeg backend |
| `ftintitle` | Moves `feat.` artists from the artist field into the title |
| `scrub` | Strips stray tag frames that other tools leave behind |
| `convert` | Adds `beet convert`, which writes an Opus copy to `~/Music-converted` at 160 kbps with opusenc and copies lossy files unchanged |
| `duplicates`, `missing`, `badfiles` | Find duplicate tracks, missing album tracks, and corrupt files |
| `unimported` | Lists files in the library folder that are not in the database |
| `info`, `edit`, `mbsync` | Inspect, interactively edit, and refresh metadata from MusicBrainz |

Art, lyrics, genre, and ReplayGain fetching all run automatically on import. They need network access, and a lookup that fails only logs a warning. A large import therefore takes longer than the tagging step alone.

### Everyday commands

```bash
beet ls                       # list the library
beet ls -a artist:radiohead   # query albums
beet modify title="..."       # change tags in the database and in the files
beet move                     # re-file files after a paths change
beet fetchart -f              # force fresh cover art
beet replaygain               # write ReplayGain tags
beet duplicates -a            # list duplicate albums
beet missing -a               # list albums with missing tracks
beet unimported ~/Music       # show files not in the database
beet bad                      # check files for corruption
beet mbsync                   # refresh metadata from MusicBrainz
beet convert                  # Opus copies in ~/Music-converted
beet convert -d ~/phone-music # make an Opus copy for a phone
```

`beet modify` and `beet move` write to the files, so import a few albums first and check the result before running either over the whole library.

---

## YouTube CLI Playback (`ytplay`)

Packaged via `inputs.ytplay` and installed into system packages:

```bash
# Play a YouTube video or search query directly in MPV
ytplay "https://www.youtube.com/watch?v=..."

# Search and select from results
ytplay "lofi hip hop radio"
```
