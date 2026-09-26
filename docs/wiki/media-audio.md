# Media, Document Viewer & Audio Stack Guide

This guide details the media playback engine (MPV), document viewer (Zathura), image viewer (imv), PipeWire audio stack, and streaming utilities configured in NixConfig.

---

## Overview

The media stack is optimised for hardware acceleration, low latency, and aesthetic unity with the system colour palette:

| Application / Layer | Technology | Key Capabilities | Configuration Location |
| :--- | :--- | :--- | :--- |
| **Video Player** | **MPV** | Vulkan `gpu-next` pipeline, hardware decode, themed Modernz OSC, Thumbfast | `modules/features/apps/media.nix` |
| **PDF & Documents** | **Zathura** | Dynamic dark mode recolouring, Neovim SyncTeX reverse search | `modules/features/apps/media.nix` |
| **Image Viewer** | **imv** | Fast Wayland image viewer with shrink scaling | `modules/features/apps/media.nix` |
| **Audio Server** | **PipeWire** | Low-latency audio with WirePlumber, ALSA, PulseAudio, and JACK support | `modules/features/system/pipewire.nix` |
| **Streaming CLI** | **ytplay** | Terminal command for direct YouTube playback in MPV | `modules/features/system/base.nix` |
| **Spotify** | **Spicetify & spotatui** | Themed desktop Spotify client and terminal TUI | `modules/features/apps/spotify.nix` & `media.nix` |

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

### Bundled Scripts & Theming

- **Modernz OSC (`modernz.conf`)**: Replaces the default on-screen controller with a clean, modern interface. Nix injects the active system colour palette (`bgRaised`, `accent`, `red`, `yellow`, `green`) into the seekbars, volume sliders, and hover effects. Window controls are disabled to match tiling compositor aesthetics.
- **Thumbfast (`thumbfast.conf`)**: Generates instant thumbnail previews while hovering over the seekbar. Configured with hardware decoding (`hwdec=yes`), remote network stream support (`network=yes`), and an automatic idle timeout (60 seconds) that reaps the background process to free system memory.
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
- **Full Theme Palette Integration**: Statusbar, input bar, `:command` completion menu (`c.bgRaised`, `c.accent`), and notification banners dynamically follow `config.theme.colors`.
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
Holding **`Ctrl`** and clicking any paragraph or equation in Zathura automatically opens your running Neovim instance at the exact source file and line number.

### Auto-Reload

With `set watch-files true`, Zathura instantly reloads the PDF on disk whenever a compiler (Typst, tectonic, pdflatex) writes a new build.

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

## YouTube CLI Playback (`ytplay`)

Packaged via `inputs.ytplay` and installed into system packages:

```bash
# Play a YouTube video or search query directly in MPV
ytplay "https://www.youtube.com/watch?v=..."

# Search and select from results
ytplay "lofi hip hop radio"
```
