# =============================================================================
# Ghostty Terminal Emulator Feature
# =============================================================================
# Ghostty GPU-accelerated terminal emulator configured with high-performance
# defaults (GTK single-instance, zero cursor blink, client-side decoration
# stripping, bounded scrollback, instant resize, delayed process retention) and
# options ported over from Foot (custom font, padding, block cursor,
# Ctrl+Backspace text binding, and dynamic theme palette).
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
      cfg = config.features.ghostty;

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

      ghosttyConfig = ''
        # GTK single-instance daemon mode: spawns windows instantaneously via IPC,
        # eliminating process/GPU/GTK initialization latency (parity with foot-server).
        gtk-single-instance = ${if cfg.gtkSingleInstance then "true" else "false"}

        # Keep the single-instance daemon process resident in memory after windows close
        # so subsequent terminal launches remain instantaneous with 0ms cold-start.
        ${lib.optionalString (cfg.quitAfterLastWindowClosedDelay != "") ''
          quit-after-last-window-closed-delay = ${cfg.quitAfterLastWindowClosedDelay}
        ''}

        # Disable client-side decorations (CSD) and GTK titlebars for minimal rendering
        # overhead and native integration with Wayland tiling window managers.
        window-decoration = ${if cfg.windowDecoration then "true" else "false"}
        gtk-titlebar = false

        # Disable cursor blinking to eliminate periodic timer wakeups and idle redrawing.
        cursor-style-blink = ${if cfg.cursorBlink then "true" else "false"}

        # Suppress transient resize overlays to eliminate compositor paint churn during
        # tiling window manager reflows (MangoWC / Hyprland / Niri).
        resize-overlay = ${cfg.resizeOverlay}

        # Close surfaces immediately without confirmation dialog prompts.
        confirm-close-surface = ${if cfg.confirmCloseSurface then "true" else "false"}

        # Bound scrollback buffer (bytes) to prevent runaway RAM consumption during heavy CLI output.
        scrollback-limit = ${toString cfg.scrollbackLimit}

        # Disable background blur and maintain full opacity for fast, direct compositor passes.
        background-blur = false
        background-opacity = 1

        # Disable URL link previews to avoid hover inspection and network overhead.
        link-previews = false

        # Disable continuous animation loops on custom shaders when idle.
        custom-shader-animation = false

        # Hide mouse pointer while typing to minimize pointer event churn.
        mouse-hide-while-typing = true

        # Disable in-terminal notification banners on clipboard copies or config reloads.
        app-notifications = no-clipboard-copy,no-config-reload

        # Disable terminal bells, audio beeps, and border flashes to prevent latency.
        bell-features = no-audio,no-system,no-border

        # Disable automatic update checking threads (handled declaratively via NixOS).
        auto-update = off

        # Use systemd cgroups for resource tracking and process cleanup.
        linux-cgroup = single-instance

        # Avoid synthetic font thickening compute passes.
        font-thicken = false

        # Break text runs only at cursor to maintain large font shaping runs for throughput.
        font-shaping-break = cursor

        # Fast Unicode grapheme width calculation.
        grapheme-width-method = unicode

        # Cap graphics memory storage limit per surface (default 320MB upstream).
        image-storage-limit = ${toString cfg.imageStorageLimit}

        # Match Linux window theme to Ghostty background/foreground.
        window-theme = ghostty

        # Stabilize cursor rendering at prompt without shape switching churn.
        shell-integration-features = no-cursor,sudo,title,path,no-ssh-terminfo

        # Inherit the focused terminal's working directory when opening new windows.
        window-inherit-working-directory = false

        # =============================================================================
        # Options Ported From Foot
        # =============================================================================
        # Monospace font family and size ported from Foot (font=Maple Mono NR NF:size=12)
        font-family = ${cfg.fontFamily}
        font-size = ${toString cfg.fontSize}

        # Padding ported from Foot (pad=10x10)
        window-padding-x = ${toString cfg.paddingX}
        window-padding-y = ${toString cfg.paddingY}
        window-padding-balance = true

        # Cursor style ported from Foot ([cursor] style=block)
        cursor-style = ${cfg.cursorStyle}

        # Text bindings ported from Foot ([text-bindings] \x1f = Control+BackSpace)
        keybind = ctrl+backspace=text:\x1f

        # =============================================================================
        # Dynamic Theme Colors (Ported From Foot colors.ini)
        # =============================================================================
        background = #${bg}
        foreground = #${fg}
        selection-background = #${accent}
        selection-foreground = #${bg}
        cursor-color = #${fg}
        cursor-text = #${bg}

        # 16 ANSI Palette Colors
        palette = 0=#${bgSubtle}
        palette = 1=#${red}
        palette = 2=#${green}
        palette = 3=#${yellow}
        palette = 4=#${accent}
        palette = 5=#${purple}
        palette = 6=#${teal}
        palette = 7=#${fg}
        palette = 8=#${fgDim}
        palette = 9=#${orange}
        palette = 10=#${green}
        palette = 11=#${yellow}
        palette = 12=#${accent}
        palette = 13=#${purple}
        palette = 14=#${teal}
        palette = 15=#${fg}

        ${cfg.extraConfig}
      '';
    in
    {
      options.features.ghostty = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Ghostty terminal emulator with performance tuning.";
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.ghostty;
          defaultText = lib.literalExpression "pkgs.ghostty";
          description = "The Ghostty package to use.";
        };

        defaultTerminal = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Set Ghostty as the default terminal in features.default-apps.terminal (default: true).";
        };

        fontFamily = lib.mkOption {
          type = lib.types.str;
          default = "Maple Mono NR NF";
          description = "Monospace font family name ported from Foot.";
        };

        fontSize = lib.mkOption {
          type = lib.types.ints.positive;
          default = 12;
          description = "Terminal font size in points ported from Foot.";
        };

        paddingX = lib.mkOption {
          type = lib.types.ints.unsigned;
          default = 10;
          description = "Horizontal window padding in pixels ported from Foot (pad=10x10).";
        };

        paddingY = lib.mkOption {
          type = lib.types.ints.unsigned;
          default = 10;
          description = "Vertical window padding in pixels ported from Foot (pad=10x10).";
        };

        cursorStyle = lib.mkOption {
          type = lib.types.enum [
            "block"
            "bar"
            "underline"
            "block_hollow"
          ];
          default = "block";
          description = "Cursor style ported from Foot ([cursor] style=block).";
        };

        cursorBlink = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable cursor blinking. Disabled by default for zero-cost idle rendering.";
        };

        resizeOverlay = lib.mkOption {
          type = lib.types.enum [
            "always"
            "never"
            "after-first"
          ];
          default = "never";
          description = "When to show window resize dimension overlay. Set to never for minimal tiling reflow latency.";
        };

        confirmCloseSurface = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Confirm closing terminal surface. Disabled by default for immediate closing.";
        };

        quitAfterLastWindowClosedDelay = lib.mkOption {
          type = lib.types.str;
          default = "10m";
          description = "Delay before single-instance daemon process quits after last window closes (keeps process warm for instant launch).";
        };

        gtkSingleInstance = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable GTK single-instance mode to eliminate cold start latency (parity with foot-server).";
        };

        windowDecoration = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable window decorations. Disabled by default for compositor-native tiling and lower GPU overhead.";
        };

        scrollbackLimit = lib.mkOption {
          type = lib.types.ints.positive;
          default = 1000000;
          description = "Maximum scrollback buffer size in bytes (Ghostty 1.3+ uses bytes, not lines). 1MB ≈ 10K lines.";
        };

        imageStorageLimit = lib.mkOption {
          type = lib.types.ints.unsigned;
          default = 50000000;
          description = "Max bytes for image data (Kitty/sixel) per surface. Upstream default is 320MB. Set to 0 to disable image protocols entirely.";
        };

        extraConfig = lib.mkOption {
          type = lib.types.lines;
          default = "";
          example = ''
            mouse-scroll-multiplier = precision:1,discrete:3
          '';
          description = "Additional raw configuration lines appended to Ghostty config.";
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ cfg.package ];

        hjem.users."${config.username}".files = {
          ".config/ghostty/config" = {
            clobber = true;
            text = ghosttyConfig;
          };
        };

        features.default-apps.terminal = lib.mkIf cfg.defaultTerminal (lib.mkDefault "ghostty");
      };
    };
}
