{ ... }: {

  # ===========================================================================
  # SWAYNC (notification daemon + control centre)
  # Themed to match the vague.nvim palette used across the rest of the system.
  # home-manager writes settings → $XDG_CONFIG_HOME/swaync/config.json
  #                      style   → $XDG_CONFIG_HOME/swaync/style.css
  # ===========================================================================
  services.swaync = {
    enable = true;

    # =========================================================================
    # CONFIG
    # =========================================================================
    settings = {
      positionX = "right";
      positionY = "top";

      layer = "overlay";
      control-center-layer = "top";

      # Gap between the control centre and the screen edge / waybar.
      control-center-margin-top = 28;
      control-center-margin-bottom = 28;
      control-center-margin-right = 28;
      control-center-margin-left = 0;

      control-center-width = 380;
      control-center-height = 600;

      # Notification popup width (pixels).
      notification-window-width = 380;

      # Icon / inline-image sizing.
      notification-icon-size = 40;
      notification-body-image-width = 200;
      notification-body-image-height = 100;

      # How long normal / low-priority / critical notifications stay visible.
      timeout = 5;
      timeout-low = 3;
      timeout-critical = 0; # 0 = stay until dismissed

      # Slide the panel in/out rather than popping instantly.
      transition-time = 200;

      # Close the centre after clearing all or clicking an action.
      hide-on-clear = false;
      hide-on-action = true;

      # Don't let GTK themes override the CSS below.
      cssPriority = "application";

      # Keyboard navigation inside the control centre.
      keyboard-shortcuts = true;

      # Widget layout — title + DND toggle at the top, then the list.
      widgets = [ "title" "dnd" "mpris" "notifications" ];

      widget-config = {
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear";
        };

        dnd = {
          text = "Do Not Disturb";
        };

        mpris = {
          image-size = 56;
          image-radius = 8;
        };

        # Explicit notifications config — required in 0.12+ to silence the
        # "Config not found! Using default config" warning.
        notifications = {
          vexpand = true;
          max-notifications = 0; # 0 = unlimited
        };
      };
    };

    # =========================================================================
    # STYLE
    # vague.nvim palette — same values used in waybar.nix, hyprland.nix, etc.
    #
    #   bg          #141415  — main background
    #   bg-raised   #1c1c24  — raised surface (notification cards)
    #   bg-hover    #21212e  — hover surface
    #   border      #252530  — 1px dividers
    #   fg          #cdcdcd  — primary text
    #   fg-dim      #606079  — dimmed / secondary text
    #   fg-mid      #878787  — mid-tone (timestamps, subtitles)
    #   keyword     #6e94b2  — blue accent
    #   builtin     #b4d4cf  — teal
    #   parameter   #bb9dbd  — muted purple
    #   warning     #f3be7c  — amber
    #   error       #d8647e  — red
    #   plus        #7fa563  — green
    # =========================================================================
    style = ''
      /* ── reset ─────────────────────────────────────────────────── */
      * {
        font-family:      "JetBrains Mono", monospace;
        font-size:        13px;
        font-weight:      400;
        border:           none;
        border-radius:    0;
        padding:          0;
        margin:           0;
        box-shadow:       none;
        text-shadow:      none;
        -gtk-icon-shadow: none;
        outline:          none;
      }

      /* ── transparent GTK window backdrops ───────────────────────── */
      /* Both the control-centre surface and each popup layer-shell
         window must be transparent so our border-radius and compositor
         shadows render correctly.                                      */
      .blank-window,
      .notification-window {
        background: transparent;
      }

      /* ── control centre window ──────────────────────────────────── */
      .control-center {
        background:    #141415;
        border:        1px solid #252530;
        border-radius: 8px;
        padding:       8px;
      }

      /* ── notification background wrapper ────────────────────────── */
      /* In swaync ≥ 0.10 every card is wrapped in .notification-background
         regardless of whether it appears in the panel or a popup.     */
      .notification-background {
        background:    transparent;
        border-radius: 8px;
        margin:        4px 0;
        padding:       0;
      }

      /* Extra margin on popup cards so they don't touch the screen edge. */
      .notification-window .notification-background {
        margin: 4px;
      }

      /* ── notification card ──────────────────────────────────────── */
      /* This single rule covers both the control centre list and the
         floating popup — no need to repeat it for .notification-popup. */
      .notification {
        background:    #1c1c24;
        border:        1px solid #252530;
        border-radius: 8px;
        padding:       12px;
        margin:        0;
      }

      .notification:hover {
        background: #21212e;
      }

      /* Popup cards get a drop-shadow so they feel elevated on screen. */
      .notification-window .notification {
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.5);
      }

      /* ── urgency: low ───────────────────────────────────────────── */
      .notification.low {
        opacity: 0.75;
      }

      .notification.low .summary {
        color: #878787;   /* fg-mid */
      }

      .notification.low .body {
        color: #606079;   /* fg-dim */
      }

      /* ── urgency: critical ──────────────────────────────────────── */
      .notification.critical {
        border-color: #d8647e;   /* error red */
      }

      .notification.critical .summary {
        color: #d8647e;
      }

      .notification.critical .app-name {
        color:   #d8647e;
        opacity: 0.8;
      }

      .notification.critical .notification-default-icon,
      .notification.critical .notification-icon {
        border: 1px solid #d8647e;
      }

      .notification.critical progressbar progress {
        background: #d8647e;
      }

      .notification.critical .notification-action:first-child {
        color:        #d8647e;
        border-color: #d8647e;
      }

      /* ── notification content layout ────────────────────────────── */
      .notification-content {
        padding: 0;
      }

      /* App name — shown above the summary. */
      .app-name {
        font-size:     11px;
        font-weight:   400;
        color:         #6e94b2;   /* keyword blue */
        margin-bottom: 2px;
      }

      /* Main heading. */
      .summary {
        font-weight: 600;
        color:       #cdcdcd;     /* fg */
        font-size:   13px;
      }

      /* Timestamp. */
      .time {
        font-size: 11px;
        color:     #606079;       /* fg-dim */
      }

      /* Body text. */
      .body {
        font-size:  12px;
        color:      #878787;      /* fg-mid */
        margin-top: 3px;
      }

      /* ── notification image / icon ──────────────────────────────── */
      .notification-default-icon,
      .notification-icon {
        border-radius: 6px;
        min-width:     40px;
        min-height:    40px;
      }

      /* ── progress bar (volume / brightness OSD apps) ────────────── */
      .notification progressbar {
        margin-top: 6px;
      }

      .notification progressbar trough {
        background:    #252530;   /* border colour */
        border-radius: 4px;
        min-height:    4px;
        border:        none;
      }

      .notification progressbar progress {
        background:    #6e94b2;   /* keyword blue */
        border-radius: 4px;
        min-height:    4px;
        border:        none;
      }

      /* ── action buttons ─────────────────────────────────────────── */
      .notification-action {
        background:    transparent;
        border:        1px solid #252530;
        border-radius: 6px;
        color:         #878787;
        padding:       4px 10px;
        margin:        4px 4px 0 0;
        font-size:     11px;
      }

      .notification-action:hover {
        background: #21212e;
        color:      #cdcdcd;
      }

      /* Primary action — keyword blue accent. */
      .notification-action:first-child {
        color:        #6e94b2;
        border-color: #6e94b2;
      }

      .notification-action:first-child:hover {
        background: #21212e;
        color:      #b4d4cf;      /* builtin teal on active */
      }

      /* ── close button (×) ───────────────────────────────────────── */
      .close-button {
        background:    transparent;
        border:        none;
        border-radius: 4px;
        color:         #606079;
        padding:       2px 6px;
        font-size:     12px;
        min-width:     0;
      }

      .close-button:hover {
        background: #1c1c24;
        color:      #d8647e;      /* error red on hover */
      }

      /* ── notification groups ────────────────────────────────────── */
      .notification-group {
        margin:  4px 0;
        padding: 0;
      }

      .notification-group-headers {
        color:     #6e94b2;
        font-size: 11px;
      }

      .notification-group-icon {
        color: #6e94b2;
      }

      .notification-group-collapse-button,
      .notification-group-expand-button {
        background:    transparent;
        border:        1px solid #252530;
        border-radius: 6px;
        color:         #606079;
        padding:       2px 8px;
        font-size:     11px;
        margin:        4px 0 2px 0;
      }

      .notification-group-collapse-button:hover,
      .notification-group-expand-button:hover {
        background: #1c1c24;
        color:      #cdcdcd;
      }

      /* ── widget: title bar ──────────────────────────────────────── */
      .widget-title {
        padding:       4px 4px 8px 4px;
        border-bottom: 1px solid #252530;
        margin-bottom: 8px;
      }

      .widget-title > label {
        font-weight: 600;
        font-size:   13px;
        color:       #cdcdcd;
      }

      .widget-title > button {
        background:    transparent;
        border:        1px solid #252530;
        border-radius: 6px;
        color:         #606079;
        padding:       2px 10px;
        font-size:     11px;
      }

      .widget-title > button:hover {
        background: #1c1c24;
        color:      #cdcdcd;
      }

      /* ── widget: do not disturb ─────────────────────────────────── */
      .widget-dnd {
        padding:       6px 4px;
        border-bottom: 1px solid #252530;
        margin-bottom: 8px;
      }

      .widget-dnd > label {
        color:     #878787;
        font-size: 12px;
      }

      .widget-dnd > switch {
        background:    #1c1c24;
        border:        1px solid #252530;
        border-radius: 12px;
        min-width:     40px;
        min-height:    20px;
      }

      .widget-dnd > switch:checked {
        background:   #6e94b2;
        border-color: #6e94b2;
      }

      .widget-dnd > switch slider {
        background:    #cdcdcd;
        border-radius: 10px;
        min-width:     16px;
        min-height:    16px;
        margin:        2px;
      }

      /* ── widget: mpris ──────────────────────────────────────────── */
      .widget-mpris {
        background:    #1c1c24;
        border:        1px solid #252530;
        border-radius: 8px;
        padding:       10px;
        margin-bottom: 8px;
      }

      .widget-mpris-player {
        padding: 0;
      }

      .widget-mpris-title {
        font-weight: 600;
        font-size:   13px;
        color:       #cdcdcd;
      }

      .widget-mpris-subtitle {
        font-size:  11px;
        color:      #bb9dbd;      /* parameter purple */
        font-style: italic;
      }

      .widget-mpris-player > box > button {
        background:    transparent;
        border:        none;
        border-radius: 4px;
        color:         #606079;
        padding:       4px 8px;
      }

      .widget-mpris-player > box > button:hover {
        background: #252530;
        color:      #cdcdcd;
      }
    '';
  };
}

