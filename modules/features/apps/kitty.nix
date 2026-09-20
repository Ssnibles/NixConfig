# =============================================================================
# Kitty Terminal Emulator Feature
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.features.kitty;

      inherit (config.theme.colors)
        bg
        bgRaised
        bgSubtle
        fg
        fgDim
        accent
        teal
        purple
        green
        yellow
        red
        orange
        ;

      kittyConfig = ''
        # ── Server Mode (single shared instance) ──────────────────────────────
        # Enables the Unix-domain socket so `kitty --single-instance` invocations
        # open new windows inside this one process instead of forking duplicates.
        # All windows then share a single GPU sprite cache and process, cutting
        # per-window RAM dramatically (same idea as foot-server / ghostty -1).
        ${lib.optionalString cfg.singleInstance ''
          allow_remote_control ${cfg.allowRemoteControl}
        ''}

        # Font family and size
        font_family ${cfg.fontFamily}
        font_size ${toString cfg.fontSize}

        # Window padding
        window_padding_width ${toString cfg.paddingY} ${toString cfg.paddingX}

        # Cursor settings
        cursor_shape ${cfg.cursorShape}
        cursor_blink_interval ${if cfg.cursorBlink then "-1" else "0"}

        # Window behaviour & decorations
        confirm_os_window_close ${if cfg.confirmCloseSurface then "1" else "0"}
        hide_window_decorations ${if cfg.windowDecoration then "no" else "yes"}

        # Scrollback & resource limits
        scrollback_lines ${toString cfg.scrollbackLines}
        max_image_bytes ${toString cfg.imageStorageLimit}

        # Disable the separate pager-scrollback history buffer (extra RAM).
        scrollback_pager_history_size 0

        # Miscellaneous
        enable_audio_bell no
        canvas_max_size 4096
        sync_to_monitor yes
        enabled_layouts stack
        map ctrl+shift+enter no_op
        map ctrl+shift+t no_op

        # Colour scheme
        background #${bg}
        foreground #${fg}
        selection_background #${accent}
        selection_foreground #${bg}
        cursor #${fg}

        # 16 ANSI Palette Colours
        color0  #${bgSubtle}
        color1  #${red}
        color2  #${green}
        color3  #${yellow}
        color4  #${accent}
        color5  #${purple}
        color6  #${teal}
        color7  #${fg}
        color8  #${fgDim}
        color9  #${orange}
        color10 #${green}
        color11 #${yellow}
        color12 #${accent}
        color13 #${purple}
        color14 #${teal}
        color15 #${fg}

        ${cfg.extraConfig}
      '';
    in
    {
      options.features.kitty = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Kitty terminal emulator.";
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.kitty;
          defaultText = lib.literalExpression "pkgs.kitty";
          description = "The Kitty package to use.";
        };

        defaultTerminal = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Set Kitty as the default terminal in features.default-apps.terminal.";
        };

        fontFamily = lib.mkOption {
          type = lib.types.str;
          default = "Maple Mono NR NF";
          description = "Monospace font family name (same Maple Mono as Ghostty).";
        };

        fontSize = lib.mkOption {
          type = lib.types.ints.positive;
          default = 12;
          description = "Terminal font size in points.";
        };

        paddingX = lib.mkOption {
          type = lib.types.ints.unsigned;
          default = 10;
          description = "Horizontal window padding in pixels.";
        };

        paddingY = lib.mkOption {
          type = lib.types.ints.unsigned;
          default = 10;
          description = "Vertical window padding in pixels.";
        };

        cursorShape = lib.mkOption {
          type = lib.types.enum [
            "block"
            "beam"
            "underline"
          ];
          default = "block";
          description = "Cursor shape.";
        };

        cursorBlink = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable cursor blinking.";
        };

        confirmCloseSurface = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Confirm closing window.";
        };

        windowDecoration = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable window decorations.";
        };

        scrollbackLines = lib.mkOption {
          type = lib.types.ints.positive;
          default = 2000;
          description = "Maximum scrollback lines (Kitty measures this in lines, not bytes). Lower values cap per-window scrollback RAM.";
        };

        imageStorageLimit = lib.mkOption {
          type = lib.types.ints.unsigned;
          default = 16777216;
          description = "Maximum bytes allocated for image data per window (set 0 to disable). Capped to keep the kitty graphics-protocol cache lean.";
        };

        singleInstance = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Run Kitty as a single shared instance (server mode). Concurrent `kitty --single-instance` launches open windows in this one process, sharing its GPU sprite cache and reducing per-window RAM.";
        };

        allowRemoteControl = lib.mkOption {
          type = lib.types.enum [
            "no"
            "yes"
            "socket-only"
            "socket"
          ];
          default = "socket-only";
          description = "Remote control policy. socket-only accepts control only over the Unix socket (required for --single-instance) while preventing programs inside kitty from driving it via the TTY.";
        };

        extraConfig = lib.mkOption {
          type = lib.types.lines;
          default = "";
          example = ''
            repaint_delay 8
            input_delay 1
          '';
          description = "Additional raw configuration lines appended to Kitty config.";
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ cfg.package ];

        hjem.users."${config.username}".files = {
          ".config/kitty/kitty.conf" = {
            clobber = true;
            text = kittyConfig;
          };
        };

        features.default-apps.terminal = lib.mkIf cfg.defaultTerminal (lib.mkDefault "kitty");
      };
    };
}
