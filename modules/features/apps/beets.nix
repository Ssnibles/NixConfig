# Beets music library manager.
_: {
  flake.nixosModules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.features.beets;

      # Beets resolves relative paths against the config directory, so the
      # database and state file stay beside config.yaml in ~/.config/beets.
      # The music itself lives in cfg.directory.
      beetsConfig = ''
        directory: ${cfg.directory}
        library: library.db
        statefile: state.pickle

        # Soulseek leaves unfinished downloads behind as INCOMPLETE<hash>
        # folders. Beets would otherwise walk into them and import the
        # partial tracks. Setting ignore replaces the built-in list, so the
        # rest of the defaults are repeated. Hidden files stay excluded by
        # ignore_hidden.
        ignore:
          - '*~'
          - System Volume Information
          - lost+found
          - INCOMPLETE*

        ignore_hidden: yes

        plugins:
          - musicbrainz
          - chroma
          - fetchart
          - embedart
          - lyrics
          - lastgenre
          - replaygain
          - ftintitle
          - scrub
          - convert
          - duplicates
          - missing
          - unimported
          - badfiles
          - info
          - edit
          - mbsync

        import:
          # Move downloads into the library instead of copying them, so the
          # library is the only copy and the download folder stays clean.
          move: yes
          copy: no
          write: yes
          autotag: yes
          incremental: yes
          # A skipped album is still written to the incremental history, which
          # then hides the folder from every later import. Do not record skips.
          incremental_skip_later: yes

        paths:
          default: $albumartist/$album%aunique{}/$track $title
          singleton: Non-Album/$artist/$title
          comp: Compilations/$album%aunique{}/$track $title

        art_filename: cover

        chroma:
          auto: yes

        fetchart:
          auto: yes
          # Only trust folder images with a cover-like name, so a stray
          # screenshot cannot become the album art.
          cautious: yes
          minwidth: 500
          maxwidth: 1200
          quality: 90
          sources:
            - filesystem
            - coverart
            - itunes
            - wikipedia

        embedart:
          auto: yes
          # Never replace art that a file already carries.
          ifempty: yes

        lyrics:
          auto: yes
          # Keep the timestamps LRCLIB returns instead of stripping them to
          # plain text.
          synced: yes
          # Genius is left out on purpose. It rate-limits the shared key that
          # ships with beets and its lookups stall an import for minutes.
          sources:
            - lrclib
            - lrcmux

        lastgenre:
          auto: yes
          canonical: yes
          source: album
          # Keep the most precise genre rather than its broad parent.
          prefer_specific: yes

        replaygain:
          auto: yes
          backend: ffmpeg

        ftintitle:
          auto: yes

        scrub:
          auto: yes

        convert:
          auto: no
          # Converted copies live outside the library so they are never
          # picked up as unimported files or re-imported as duplicates.
          dest: ${cfg.convertDest}
          format: opus
          never_convert_lossy_files: yes
          embed: yes
          formats:
            opus:
              # opusenc only reads WAV, AIFF, FLAC and Ogg, so forcing the
              # conversion of an MP3 or M4A with -F will fail. Lossy files are
              # skipped unless that flag is used.
              command: opusenc --bitrate 160 $source $dest
              extension: opus
      '';
    in
    {
      options.features.beets = {
        enable = lib.mkEnableOption "beets music library management";

        directory = lib.mkOption {
          type = lib.types.str;
          default = "~/Music";
          description = "Folder that holds the organised music library.";
        };

        convertDest = lib.mkOption {
          type = lib.types.str;
          default = "~/Music-converted";
          description = ''
            Folder that holds converted copies. Keep it outside the library
            directory so beets does not import the copies as duplicates.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          pkgs.beets
          pkgs.opus-tools
          # badfiles shells out to mp3val for MP3s and flac for FLACs.
          pkgs.mp3val
        ];

        hjem.users.${config.username}.files.".config/beets/config.yaml".text = beetsConfig;
      };
    };
}
